# Project status

A living, git-tracked handoff note — the shared "memory" that travels between
machines and sessions. Keep it current: when you finish a slice or make a
decision worth remembering, update this file in the same commit. It complements
`CHANGELOG.md` (which records *what shipped*); this file records *where things
stand and what's next*.

**Last updated:** 2026-08-25

---

## Current state

"Log a session end-to-end" is complete; **S1 (reading context → schema v2)** and
**S2 (multiple readings per session + context pickers)** have landed on top of it
(roadmap slices, `docs/ROADMAP.md`).

- **Domain:** `Session` / `Reading` entities, typed ids, `ReadingInput.validate()`
  (plausibility bounds — typo guards, not clinical thresholds), a sealed `Result`
  type, and the `SessionRepository` / `IdGenerator` interfaces. `Reading` carries
  optional context — `MeasurementSite`, `Posture`, `MedicationTiming` (§4) —
  persisted by enum name.
- **Data:** drift **schema v2** (`Sessions` 1‑to‑many `Readings`, cascade delete;
  v2 adds nullable context columns), UTC ISO‑8601 timestamps,
  `DriftSessionRepository`, UUID v7 ids, committed v1 + v2 snapshots, and a
  migration test proving v1 rows survive the upgrade with null context.
- **UI:** readings list + entry form on `flutter_bloc` Cubits; all strings in ARB.
  The entry form builds up an occasion of one or more readings (bank with "add
  another reading", remove a banked one, save the lot as one session) and
  captures optional per-reading context via a collapsible "Add details" section
  (arm/wrist, body position, before/after medication) — **S2 landed (a + b)**.
  The list shows each occasion as its **average** (`Session.average`, §4) with a
  reading-count badge on multi-reading rows — **S2c** (it closed a gap S2 left:
  the tile still showed only the first reading). Tapping a row opens a read-only
  **session detail screen** (`SessionDetailScreen`) showing the occasion's
  individual readings — each with time, pulse and any recorded context/note
  (`ReadingDetail`) — and, for a multi-reading occasion, their **average** above
  them; a single-reading occasion shows just the reading (§4) — **S4 landed**.
  (This replaced S2d's in-place row expansion: one path to a session's readings,
  and the home for the later edit/delete slice. Context first surfaces here.)
  The three number fields are now big −/+ **steppers** (`NumberStepper`), sized
  for the older audience — large type, >48dp targets, screen-reader labels;
  still typeable, and typing stays unclamped so `ReadingInput.validate` is the
  one typo guard. A new occasion opens on a neutral default (120/80, no pulse);
  "add another reading" carries the just-banked numbers + context into the next
  reading; pulse keeps its optional "—"/clear state — **S3a landed**.
  A new occasion's first reading now opens on the user's **own** numbers instead
  of the fixed 120/80: the mean of past occasion averages, preferring the last
  two weeks (`firstReadingWindow`) in the current day-bucket (morning before
  local noon / evening after), then same-bucket at any age, then any occasion,
  then 120/80 only with no history at all (`suggestedFirstReading`) — recency
  tracks BP drift, the bucket the time-of-day difference; its context is
  prefilled from the most recent stored reading. The form waits on a one-shot
  `SessionRepository.recentHistory` read before it opens, so nothing changes
  under the user — **S3b landed**.
- **Tests:** domain + data covered; an end-to-end smoke test (incl. a
  two-reading occasion, a context round-trip, tapping a row through to the detail
  screen, stepper defaults, carry-over prefill, a stepped value being what is
  saved, and a fresh occasion prefilled from history), plus `SessionDetailScreen`
  behaviour tests (average shown/omitted, each reading listed), `NumberStepper`
  behaviour tests, the `suggestedFirstReading` / `mostRecentReading` domain
  stats, `recentHistory`, the cubit's `initialSeed`, and a golden test on the
  readings-list empty state, plus `SessionDetailScreen` delete-flow behaviour
  tests (confirm, cancel, delete + undo, restore, failure) and the
  `SessionRepository.delete` data tests (removes + cascades, absent-session
  no-op), plus S5c add-reading + Session.withReadingAdded + the shared TakenAtField extraction. All green (150).
- **Verified running:** the theme + S4 were run and eyeballed on a **physical
  Android device** (Redmi 2312DRA50G, Android 16 / API 36) on 2026-08-25 — the
  warm theme, Hanken type, big teal steppers and teal Save button all render
  correctly. (Xiaomi/HyperOS needs Developer options → "Install via USB" on to
  let `flutter run` install; `adb shell input` tap-injection additionally needs
  "USB debugging (Security settings)", which was left off — screen capture works
  without it.)
- **Design foundation — now in code (2026-08-24).** The *warm & reassuring*
  visual language (worked out on a Claude Design canvas, approved by the
  maintainer) is a Material 3 `ThemeData` built in `lib/ui/theme/`
  (`cadence_colors.dart` holds the exact palette; `cadence_theme.dart` the
  `buildCadenceTheme()`), wired onto `MaterialApp`. Teal is Material's
  `primary` (structural accent); the terracotta **clay** action colour is
  reserved for the entry FAB via `floatingActionButtonTheme`. Hanken Grotesk is
  bundled as a single variable-weight asset (`assets/fonts/`, SIL OFL 1.1,
  registered in `main.dart`) — **not** the `google_fonts` package, which fetches
  over the network (§2). The "Add a reading" button is now a labelled extended
  FAB. Exact tokens: paper `#FAF6F1`, surface white, sand `#F3ECE4`, border
  `#EAE0D6`, ink `#2A2521`/`#6F655C`/`#A2968B`, teal `#2F6E63`/`#234F47`/`#DCEAE5`,
  clay `#BC6248`/`#8F4732`/`#F6E2D9`; chart series validated colour-blind-safe
  (systolic teal `#0E8C74`, diastolic ochre `#B4832E`). **Never colour a reading
  good/bad, no threshold lines** (§1). Light-only for now: the canvas designed no
  dark palette, so a device in dark mode still gets the warm light theme (dark is
  a later, separate design slice). Golden coverage: the readings-list **empty
  state** (timezone-free) via a tolerant comparator (`test/flutter_test_config.dart`)
  so one macOS-generated baseline holds on the Linux CI runner. Remaining mockups
  still to build: **S4 detail (with S5 edit/delete)**, a **1.x trends chart**;
  canvas <https://claude.ai/code/artifact/33a266c3-5a9b-40f1-8847-9c2583ee2d39>
  (working `.dc.html` files were scratchpad-only, not committed). **Not yet run
  on a physical device this slice** — verified via the golden + full suite;
  confirm on-device when S4 lands.

## Environment & tooling

- **Fresh-clone setup is in the [README](../README.md)** (`flutter pub get`,
  `lefthook install`). Generated drift/l10n code is committed — no code-gen
  needed on a clean clone.
- **Android build needs JDK 17.** Gradle 9 / AGP 9.1 refuse to run on JDK 11 and
  aren't validated on very new JDKs (e.g. 25). If a build fails at Gradle
  start-up complaining about the JVM version, check for a JDK pin in your global
  `~/.gradle/gradle.properties` (`org.gradle.java.home`) — a stale global pin
  overrides per-project settings. Point Flutter at a JDK 17 with
  `flutter config --jdk-dir <path-to-temurin-17>`.
- Machine-specific paths (SDK locations, JDK dirs) differ per machine and are
  **not** recorded here — set them per machine via `flutter config`.

## CI

- `.github/workflows/ci.yml` runs the same gate as the pre-commit hook (format,
  analyze, import boundaries, tests) on Linux for pushes/PRs to `main`.
- Third-party actions are SHA-pinned; Dependabot (`.github/dependabot.yml`) keeps
  them current.
- **When you upgrade Flutter locally, bump the `flutter-version:` line in
  `ci.yml`** so CI tests against the same version you develop on.

## Next slices — see the roadmap

The path to a shippable **v1.0** is now planned in **[`ROADMAP.md`](ROADMAP.md)**:
an ordered product track (S1–S10) and a parallel Play-Store release track
(B1–B7), plus what is deferred to 1.x and why.

**Decided (2026-08-24):** a fuller v1.0 that deliberately pulls in 7‑2‑2
coverage, the reading context fields, and Italian localisation. Reference-range
display stays deferred (a maintainer call — `CLAUDE.md` §1, §10). Ease of use is
a cross-cutting requirement because the audience skews older; see the roadmap's
principle section.

**Done:** **S1 — context fields → schema v2**. `MeasurementSite {leftArm,
rightArm, leftWrist, rightWrist}`, `Posture {sitting, standing, lying}`,
`MedicationTiming {before, after}` — all optional, stored by name, no UI. Thin
migration slice (schema + domain + tests only); the entry pickers come with the
form rework.

**Done (2026-08-24): S3a — fast-entry steppers.** The `NumberStepper` widget +
within-occasion prefill + optional-pulse handling described in the UI bullet
above. UI-only: no domain or data change. Design decided in brainstorm — first
reading prefills from the **average of the morning/evening bucket** (a new domain
stat, deferred to S3b), later readings from the last banked one; context prefills
from the last actual reading, not an average.

**Done (2026-08-24): S3b — history-aware first-reading prefill.** Replaced
S3a's fixed 120/80 default with the user's own **recent morning/evening bucketed
average**. New pure domain function `suggestedFirstReading` (in
`first_reading_suggestion.dart`) means past **session averages** —
session-as-unit (§4) — over a tiered fallback: (1) last two weeks
(`firstReadingWindow = 14d`) in the current day-bucket (split at local noon,
7-2-2 shape; per-hour rejected as too sparse), (2) same bucket at any age, (3)
any occasion, (4) `null` → caller supplies 120/80. Recency tracks BP drift
(a med change surfaces in a week or two instead of being buried under years);
the bucket keeps morning-vs-evening straight; an old same-bucket occasion beats
a recent other-bucket one because time-of-day drives the value. Bucketing takes
an injected `toLocal` so tests are timezone-independent; the recency cutoff is
`now.toUtc() - window`. A shared `roundedMean` was extracted into
`session_average.dart` so it and `Session.average` round identically. A one-shot
`SessionRepository.recentHistory()` feeds it (drift `.get()` reusing the join;
the fake gets a settable `history`). Context is prefilled from
`mostRecentReading`. Wiring: the cubit exposes a memoised
`Future<EntrySeed> initialSeed`; the entry form awaits it (spinner first) so the
numbers never swap under the user — no new cubit state, no churn to existing
cubit/state tests. Decisions taken in brainstorm: one-shot read over
`watchAll().first` (the fake doesn't replay on subscribe, which would have
fought ~20 tests); load-then-show over show-then-swap; and the recent-window
average (user's call) over an all-time one — 14 days, tunable, a candidate for a
future Settings toggle.

**Done (2026-08-24): design foundation.** The approved warm visual language is
now a Material 3 theme wired onto `MaterialApp` — see the design-foundation
bullet under Current state for the details, tokens, and decisions (teal =
`primary`, clay reserved for the FAB; Hanken Grotesk as a bundled OFL variable
asset; light-only; golden on the empty state via a tolerant comparator). UI-only,
own branch `design-foundation-theme`.

**Done (2026-08-25): S4 — session detail.** Tapping a list row opens a read-only
`SessionDetailScreen` (the occasion's readings via `ReadingDetail`, plus their
average for multi-reading occasions). Replaced S2d's in-place expansion; no
domain or data change (`Session.average` already existed); two new ARB strings
(`Average` / `Readings`). Built and eyeballed in the new theme via a throwaway
render; tested by direct-pump behaviour tests + the navigation smoke test. Own
branch `s4-session-detail` (merged to `main`). **Verified on a physical device**
2026-08-25 — see "Verified running" above.

**Done (2026-08-25): S5a — delete an occasion.** The `SessionDetailScreen` can
now delete the whole occasion: a confirmation dialog, then on success it leaves
the screen and shows an "Undo" that re-adds the kept `Session` as-is (its id is
free again after the delete, so the restore cannot collide) — confirm + undo
per the maintainer's call (CLAUDE.md §6). New `SessionRepository.delete(SessionId)`
(readings cascade away; an absent-session delete is a no-op that still returns
`Ok`) with drift-repo + fake coverage; a thin `SessionDetailCubit` (state is the
`Session`) so the screen reaches the store through a cubit, not directly. The
undo snackbar rides the app-root `ScaffoldMessenger`, shown just before the pop
so it lands on the list; navigator/messenger/repository are captured before the
awaits (no reach for a disposed context). Own branch `s5a-delete-session`.
**S5 was split** at the ~400-line budget (CLAUDE.md §8) — the reactive detail
(watch the store) and the shared reading widgets landed with S5b.

**Done (2026-08-25): S5b — edit a reading & remove a single reading.** On the
`SessionDetailScreen`, each reading now has an edit action (tap → a focused
`EditReadingScreen`) and, when the occasion holds more than one, a remove action.
- **Edit** reuses the entry `NumberStepper` + `ReadingContextDetails` +
  `ReadingInput.validate`; the editor is a pure form that pops the corrected
  `Reading` (the detail screen writes it). Identity is preserved via
  `Reading.withId` — validate mints a fresh id, immediately re-stamped with the
  original, so the store updates the reading rather than adding one. **Editing
  the time was left out of this slice** (the mistyped thing is the numbers; time
  is picked, not typed) — a candidate follow-up.
- **Remove** a reading is offered only when others remain (removing a lone
  reading is the whole-occasion delete, which keeps its dialog); undo only, no
  dialog, since it is small and immediately reversible (undo = `update` the
  previous readings back).
- Domain (TDD): `Session.withReadingReplaced` (match by id, throws if absent)
  and `withoutReading` (→ `Session?`, `null` when it would empty the occasion —
  the ≥1-reading rule, §4), plus `Reading.withId`.
- Data: `SessionRepository.update(Session)` — one transaction: delete this
  session's readings, re-insert the given set (the session row has only its id,
  nothing to update on it). Drift + fake coverage.
- `SessionDetailCubit` now watches `watchAll()` and re-emits its occasion when
  the store changes, so an edit's new values appear without a stale snapshot; a
  vanished occasion is ignored (the screen is already leaving on the action).
- Own branch `s5b-edit-reading` (off `s5a-delete-session`). 146 tests green; not
  yet on a device.

**Also done (2026-08-25, folded into the S5b branch at the maintainer's ask):**
the readings list renders each occasion as a **card** (matching the approved
design) instead of a flat `ListTile` — colour/border/radius/spacing all from the
theme's `cardTheme`, so nothing hardcoded.

**Done (2026-08-25): S5c — add-to-occasion + editable time (maintainer ask).**
Two follow-ups after eyeballing S5b on the device:
- **Add another reading** to a saved occasion — an "Add another reading" button
  on `SessionDetailScreen` for the reading a user meant to log but saved too
  soon (a common slip for the older audience). New domain `Session.withReadingAdded`
  (TDD). It opens the reading form seeded from the occasion's latest reading
  (numbers + context carried, note cleared, time ~1 min later, clamped to now),
  and appends on save.
- **Editable time** in the reading form — not just the values. The entry form's
  time field + date/time picker were extracted into a shared `TakenAtField`
  (+ `pickTakenAt`) so time is picked one way everywhere (§8, no second way);
  the entry form was refactored onto it. S5b's `EditReadingScreen` was
  generalised into `ReadingFormScreen` (title param, editable `takenAt`), serving
  both edit and add — it pops a validated `Reading` with a **fresh** id and the
  caller decides identity (edit re-stamps via `Reading.withId`; add keeps the
  fresh id). S5a/S5b's earlier nav-bar-inset fix (`withSystemBottomInset`) also
  applies here.
- Own branch `s5c-add-and-time-edit` (off `main`, which already had S5a+S5b+icon).
  150 tests green. **All of S5 (a/b/c) is now on `main`.**

**Next up — S6 (7-2-2 coverage), see the roadmap.** S5 is merged and pushed;
device-verify the full edit/add/delete flow when convenient.

## Working reminders

- Vertical slices, one branch per slice; a slice over ~400 lines of diff was two.
- Definition of done: `CLAUDE.md` §8 (CI green, tests, docs, CHANGELOG, no
  hardcoded strings, no second way to do an existing thing). Never silence a lint.
- Defer domain/clinical modelling decisions to the maintainer (`CLAUDE.md` §10);
  push back on non-idiomatic Flutter.
