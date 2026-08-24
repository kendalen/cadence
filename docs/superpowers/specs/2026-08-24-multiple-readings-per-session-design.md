# Design — Multiple readings per session (+ reading context)

- **Date:** 2026-08-24
- **Status:** Approved (pending spec review)
- **Slice:** S2 (roadmap `docs/ROADMAP.md`). Let one occasion carry more than one
  reading in the entry flow, and capture the optional context fields S1 added to
  the model.

This design refers throughout to the constraints in `CLAUDE.md`; section numbers
(e.g. §4) point there. §4's domain model is treated as given.

---

## 1. Goal and scope

The entry flow records exactly one reading per occasion today, even though the
schema and `SessionRepository.add` already store many (S1; verified by the
existing `drift_session_repository_test.dart` two-reading round-trip). This slice
makes the UI stop breaking that promise: a user builds up an occasion of one or
more readings and saves them as a single `Session`, and can attach the optional
arm / posture / before-after-medication context to each reading.

**In scope**

- Entry flow rework: fill a reading, bank it into a list, add more, save the
  whole occasion as one `Session`.
- The one-reading case stays a single action (fill → Save), with no nagging
  toward the protocol (§4).
- Pre-save correction: remove a banked reading before saving.
- Optional context per reading: `MeasurementSite`, `Posture`,
  `MedicationTiming`, each defaulting to "not recorded" (§4).
- Domain: `ReadingInput` carries the three context fields into the built
  `Reading`.
- English ARB strings for all new copy; TDD on the domain and Cubit changes.

**Out of scope (do not build toward these)**

Session detail and the session average (S4), edit/delete of *saved* data (S5),
7-2-2 coverage and any period average or 135/85 threshold (S6), export, Italian
copy (S10). No schema change: the data layer is untouched. The session **list**
row is not redesigned here (that is S4); this slice only confirms it tolerates a
multi-reading session without error.

**Explicitly not painting into a corner**

- Banked readings are already-validated domain `Reading` objects, so Save is a
  plain `repo.add(Session(...))` with no re-validation of banked entries.
- The context pickers live in a self-contained collapsible section, so S3's
  fast-entry rework can restyle the number fields without fighting them.

---

## 2. Decisions (with rationale)

1. **Build up in memory, then save once.** The occasion is assembled in the
   Cubit as a list of `Reading`s and written with a single `repo.add(Session)`.
   `add` is already atomic all-or-nothing (§5), and the repository has no
   "append to a saved session" method — building in memory matches both. The
   trade-off is accepted: an occasion abandoned before Save is lost (it was
   never written); this is a diary of typed numbers, not a long form, so the
   exposure is small.
2. **One screen, form on top, banked list below** (chosen in brainstorming).
   No navigation to get lost in, everything entered is visible, each banked
   reading is removable — the ease-of-use principle for an older audience
   (roadmap §"Cross-cutting principle"). Rejected: a separate occasion screen
   (more taps, worse for the common one-reading case) and top-of-form chips
   (harder to review/remove).
3. **Save grabs the in-progress form.** "Save" writes the banked list **plus**
   the reading currently in the form, if one has been started. This keeps
   logging a single reading to one action (fill → Save) — §4's "no friction for
   one reading." Consequence: a *started-but-invalid* current reading blocks
   Save with field errors rather than being silently dropped (§5 — never
   silently drop typed data). "Started" is defined narrowly (see §4).
4. **Next reading defaults to the previous +1 minute.** After banking a reading,
   the form's `takenAt` resets to that reading's time plus one minute. Nudges
   toward the protocol's "~1 min apart" (§4) without enforcing it, and does the
   right thing when back-entering an earlier day (keeps the date). Not a clinical
   rule — a UI default, easy to change.
5. **Context: optional dropdowns in a collapsible "details" section.** Three
   dropdowns, each defaulting to "Not recorded", hidden behind an expandable
   section so the fast path (just the numbers) stays uncluttered. Per-reading, so
   left-arm-then-right-arm is expressible. No validation — set or null.
6. **`ReadingInput` gains the context fields.** The only domain change. Today
   `validate()` builds a `Reading` with null context; it will pass the three
   optional fields straight through. Additive, pure, TDD-first. No change to
   `Session`, the repository, the schema, or the mappers.
7. **Split into two commits on one `S2` branch.** With context pickers included,
   the diff will exceed the ~400-line slice budget (§8), so it ships as:
   - **S2a — multiple readings:** the build-up flow, banked list, save-whole-
     occasion. Domain unchanged.
   - **S2b — context pickers:** `ReadingInput` + the collapsible pickers + enum
     strings.
   Each commit keeps CI green on its own and stays reviewable.

---

## 3. Architecture by layer

Dependencies flow one way and are lint-enforced (§3): `domain` is pure; `data`
depends on `domain`; `ui` depends on both.

### 3.1 Data (`lib/data/`) — no change

`repository.add` inserts the session then batch-inserts every reading under it,
and `watchAll` groups joined rows back into multi-reading sessions. Both are
already exercised by a two-reading test. Nothing in `data` changes; no schema
bump, no migration.

### 3.2 Domain (`lib/domain/`) — S2b only

```
ReadingInput {                          // + three optional context fields
  ...systolic, diastolic, pulse, notes, takenAt (unchanged),
  MeasurementSite? site
  Posture? posture
  MedicationTiming? medicationTiming
  Result<Reading, List<ValidationFailure>> validate(IdGenerator, {DateTime now})
}
```

`validate()` gains no new failure modes — the context fields are either set or
null. On success it passes `site` / `posture` / `medicationTiming` into the
`Reading` it builds. `Reading`, `Session`, `SessionRepository`, and the failure
types are unchanged.

### 3.3 UI (`lib/ui/sessions/entry/`) — the bulk of the slice

**State** (`session_entry_state.dart`). `SessionEntryEditing` gains a
`bankedReadings` list of validated `Reading`s; `SessionEntrySubmitting` and
`SessionEntrySaveFailed` carry it too, so an in-flight or failed write keeps the
banked occasion for retry. `takenAt` stays on the base (it is the *current*
form's moment). Value equality includes `bankedReadings`.

**Cubit** (`session_entry_cubit.dart`). New/changed methods:

- `addReading({systolic, diastolic, pulse, notes, context...})` — validates the
  form via `ReadingInput.validate`. On `Err`, emit `Editing(takenAt,
  bankedReadings, failures)`. On `Ok`, append the `Reading`, reset `takenAt` to
  `reading.takenAt + 1 min` (local), emit `Editing(newTakenAt, grownList, [])`.
- `removeBankedReading(ReadingId)` — emit `Editing` with that reading dropped.
- `save({...form fields})` — if a write is in flight, no-op. Determine whether
  the form is *started* (§4). If started, validate it; on `Err`, emit
  `Editing(..., failures)` and stop (do not drop it). Assemble
  `bankedReadings + [currentIfStarted]`; if that is empty, emit `Editing` with
  the empty-form validation failures (can't save an empty occasion). Otherwise
  emit `Submitting`, build one `Session`, `await repo.add`, then emit `Saved` or
  `SaveFailed(bankedReadings)`.
- `takenAtChanged` — unchanged, but preserves the current `bankedReadings`.

**Screen** (`session_entry_screen.dart`). One `ListView`:

- the number fields + notes + the collapsible "Add details (optional)" section
  with the three context dropdowns + the date-time field (all as today, plus
  context);
- a secondary **"+ Add another reading"** button;
- a **"Readings so far"** list of banked readings — each showing `120/80`, its
  local time, and a delete (✕) — shown only when the list is non-empty;
- a primary **Save** button.

The screen clears its text controllers and resets the context dropdowns when the
banked list grows (its signal that an add succeeded), via the `BlocConsumer`
listener comparing the new `bankedReadings.length` against the previous build's.
On `Saved` it pops (as today); on `SaveFailed` it keeps the fields and shows the
existing error snackbar; the banked list survives in state for retry.

---

## 4. Behaviour rules

- **"Started" form.** The current form counts as a reading-in-progress iff
  `systolic` or `diastolic` is non-blank (the two required fields). Pulse, notes,
  or a context dropdown alone do **not** count as started — they cannot form a
  valid reading without a pressure, and treating them as started would block Save
  with confusing errors after the user only touched an optional field.
- **Add another reading:** validates the current form; banks it on success,
  clears the form, bumps `takenAt` by a minute; shows field errors on failure and
  banks nothing.
- **Save:**
  - form started + valid → write `banked + current` as one `Session`;
  - form started + invalid → show field errors, write nothing;
  - form not started, banked non-empty → write the banked list;
  - form not started, banked empty → show the empty-form "value missing" errors
    (nothing to save). A `Session` requires ≥1 reading (§4), enforced in the
    domain constructor.
- **Remove a banked reading** before saving is always allowed. Editing or
  deleting a reading that has already been *saved* is S5, out of scope.
- **No protocol nagging** (§4): logging one reading is fill → Save; the app never
  pushes the user to add a second.

---

## 5. Error handling

- Validation failures surface per-field exactly as today (`ReadingInput.validate`
  reports all failures at once). A persistence failure surfaces as the existing
  localised snackbar, never a raw exception string (§6); the banked occasion and
  the typed form both stay in place so the user can retry.
- Context fields cannot fail validation; a value the database never wrote is a
  bug, still left to throw in the mapper (unchanged, §6).

---

## 6. Strings (§9)

New English ARB keys (source locale; Italian is S10). Provisional wording, plain
and jargon-free for an older audience (roadmap principle):

- Screen/title and actions: "Add another reading", "Save", "Readings so far",
  a delete tooltip.
- The details section: "Add details (optional)", "Not recorded" (the default
  option for each dropdown), and the three field labels (arm / body position /
  medication).
- A plain label per enum value: left arm, right arm, left wrist, right wrist;
  sitting, standing, lying; before medication, after medication. Rendered through
  a single mapping helper in `ui/sessions/` (reuse the existing
  `validation_messages.dart` pattern — do not introduce a second way to map a
  domain value to a string, §6).

No user-facing string is hardcoded (§8).

---

## 7. Testing (§7)

- **domain (full TDD, S2b):** `ReadingInput` passes each context field through to
  the built `Reading`; unset context stays null; existing validation behaviour
  unchanged.
- **ui — Cubit (S2a + S2b):** driving the Cubit and asserting emitted states —
  add banks a reading and grows the list; an invalid add shows failures and banks
  nothing; `takenAt` resets to +1 min after an add; remove drops a banked
  reading; Save writes `banked + current` as one multi-reading `Session` (assert
  against a fake repository); Save with a started-but-invalid form is rejected;
  Save on an empty form + empty list is rejected; a save failure keeps the banked
  list. Context values flow through Save into the stored session (S2b).
- **ui — smoke (S2a):** extend `log_session_smoke_test.dart` to log a
  **two-reading** occasion end-to-end and find both readings in the stored
  session.
- **ui — golden:** only if a key screen's golden meaningfully changes; no
  `Column`-structure assertions (§7).

Every behaviour above is written test-first (§7).

---

## 8. File layout

Changed files (no new domain/data files):

```
lib/
  domain/sessions/reading_input.dart        # + context fields (S2b)
  ui/sessions/
    validation_messages.dart                # + context-enum labels (S2b), or a sibling helper
    entry/session_entry_state.dart          # + bankedReadings (S2a)
    entry/session_entry_cubit.dart          # add/remove/save rework (S2a, +context S2b)
    entry/session_entry_screen.dart         # banked list + pickers (S2a, +pickers S2b)
  l10n/app_en.arb                           # new keys
test/
  domain/sessions/reading_input_test.dart   # context pass-through (S2b)
  ui/sessions/session_entry_cubit_test.dart # build-up + save behaviour
  ui/log_session_smoke_test.dart            # two-reading occasion
```

`session_entry_screen.dart` risks passing the ~300-line file smell (§6) once the
pickers and banked list land; if it does, extract the banked-list widget and/or
the details section into sibling private widgets rather than growing it.

---

## 9. Definition of done (§8) — per commit

- [ ] `lefthook run pre-commit` green (`dart format`, `flutter analyze
      --fatal-infos --fatal-warnings`, `dart analyze` boundaries, `flutter test`).
- [ ] Domain and Cubit changes covered by tests, written first.
- [ ] No schema change (so no migration work); if that assumption breaks, stop
      and raise it (§10).
- [ ] No hardcoded user-facing strings; new keys in the ARB.
- [ ] Public APIs touched in `domain`/`ui` documented (§6).
- [ ] No second way introduced for anything the repo already does (esp. the
      domain-value→string mapping).
- [ ] `CHANGELOG.md` updated; `docs/STATUS.md` handoff note updated.
