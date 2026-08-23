# Cadence — Agent Instructions

Read this file fully before answering anything about this repository. These are
constraints, not suggestions. When a constraint blocks you, say so and ask — do
not work around it.

---

## 1. What this project is

Cadence is an offline-first blood pressure diary for Android, built in Flutter.

The user reads their own validated blood pressure monitor and types the numbers
in by hand. The app does not measure anything.

**Cadence is a diary, not a medical device.** It records readings and does
arithmetic on them. It must never present output that reads as a diagnosis, a
treatment recommendation, or an instruction to change medication. Reference
ranges may be shown, always attributed to their source (ESH/AHA) and always
alongside a pointer to consult a physician. This is a regulatory boundary (EU
MDR), not a matter of tone — treat any feature request that crosses it as a
question for the human, not a design decision you can make.

Licence: Apache 2.0. Solo developer, side project, no deadline. Correctness and
maintainability outrank velocity in every trade-off.

---

## 2. Hard constraints

These were decided before the repository existed. Do not reopen them without
asking.

- **Flutter + Drift (SQLite).** No other persistence engine.
- **Local only.** No backend, no user accounts, no telemetry, no analytics SDK,
  no crash reporting that transmits off-device. No ads, ever.
- **Manual entry only.** No Bluetooth cuff integration, no camera-based
  measurement, no sensor reads.
- **Session-based data model.** See §4.
- **Versioned JSON is the only restorable backup format.** CSV and PDF are
  export-only.
- **Export goes through the Android share sheet / SAF first.** Google Drive API
  is a later, separate decision. If it happens, scope is `drive.file` or
  `drive.appdata` only — never `drive` or `drive.readonly`, which trigger the
  restricted-scope regime and an annual paid security assessment.
- **Source language is English.** All UI strings are localised from day one
  (§9). No hardcoded user-facing text.

---

## 3. Architecture

Three layers, strict one-way dependencies:

```
ui  ──▶  domain  ──▶  data
```

- `lib/domain/` — entities, value objects, protocol logic, statistics. Pure
  Dart. **No Flutter imports. No Drift imports. No I/O.** This is the layer
  that encodes what the app knows; it must be testable with zero setup.
- `lib/data/` — Drift schema, DAOs, repositories, serialisation, file export.
  Depends on `domain` for the types it maps to. Never imports `ui`.
- `lib/ui/` — widgets, screens, state management, formatting. Depends on both.

These boundaries are enforced by lint rules, not by convention. If you find
yourself needing to violate one, that is a signal the design is wrong — stop and
raise it.

**Repositories return domain types, never Drift row classes.** A Drift-generated
class must not appear in a signature outside `lib/data/`.

State management: one approach for the whole app. Do not introduce a second one
because it fits a particular screen better.

---

## 4. Domain rules

The domain model is the part of this app that distinguishes it. Get it right.

### Session, not reading

A **Session** is one measurement occasion and holds one or more **Readings**.
The session — not the individual reading — is the unit of analysis. Do not model
a reading as a standalone top-level record.

A Reading carries: systolic, diastolic, pulse, timestamp, and optional context
(arm, posture, before/after medication, notes). Derived values — pulse pressure,
MAP — are computed, never stored.

### The 7-2-2 protocol

Home monitoring, per ESH/AHA guidance:

- two readings per occasion, separated by ~1 minute
- two occasions per day (morning and evening)
- over 7 consecutive days
- after ~5 minutes of seated rest before the first reading

The app **supports** this protocol; it does not enforce it. A user who logs one
reading at a random hour must be able to do so without friction or nagging.

- Session average is the mean of its readings.
- Discarding day 1 of a monitoring period is **optional and user-configurable**.
  The literature is genuinely divided on it — do not hardcode either behaviour
  and do not present either as the correct one.
- The home-monitoring threshold of 135/85 mmHg applies to the *average of a
  monitoring period*, never to a single reading. Never colour or label an
  individual reading as if it carried diagnostic weight.
- **Coverage is a first-class output**: report readings collected against
  readings expected (e.g. 9/14 this week). An average computed from insufficient
  data must be labelled as such.

### Interpretation

Any threshold shown must name its source. No sentence in the UI may tell the
user what to do about a number.

---

## 5. Persistence and data safety

This is the only part of the app where a mistake is unrecoverable. Treat it
accordingly.

- Database lives in `getApplicationDocumentsDirectory()`. Never in a cache
  directory.
- Every `schemaVersion` bump requires: an explicit migration step, a
  `drift_dev schema dump` snapshot committed to the repo, and generated
  migration tests that pass in CI. **A schema change without a passing migration
  test does not get merged.**
- `validateDatabaseSchema()` in `beforeOpen` under debug builds.
- Force `PRAGMA wal_checkpoint(TRUNCATE)` before copying or exporting the
  database file.
- Android Auto Backup is **disabled** (`android:allowBackup="false"`). Backup is
  explicit, user-initiated, and goes through the JSON export path. Do not
  re-enable it.
- The JSON backup format carries its own version field at the top level. The
  importer tolerates unknown fields and supplies defaults for missing ones. It
  never silently drops data — on ambiguity it reports and asks.

---

## 6. Coding standards

### Readability

Code is read by a human maintainer who did not write it and has not seen it in
six months. Optimise for that reader.

- Names state intent. `sessionAverage`, not `calc` or `avg2`. No abbreviations
  beyond established ones (`id`, `db`, `bp`).
- A function does one thing. If you need "and" to describe it, split it.
- Guard clauses over nested conditionals. Maximum nesting depth of three.
- Prefer explicit over clever. A three-line loop that reads plainly beats a
  one-line fold that does not.
- Files over ~300 lines and classes over ~200 are a smell — flag them rather
  than continuing to grow them.

### Design patterns

Apply patterns where they solve a problem you actually have. Do not apply them
to demonstrate that you know them.

- Repository at the data boundary — yes, this is the design.
- Result/Either for expected failures — yes; exceptions are for bugs, not for
  "the file wasn't there".
- Strategy, Factory, Adapter — when there is genuine variation to absorb.
- Singletons, service locators reached from anywhere, inheritance chains deeper
  than two — no. Prefer composition and explicit dependency injection.

An abstraction with exactly one implementation and no second one in sight is
premature. Delete it.

### Duplication

The rule is three, not two. Two similar pieces of code may legitimately be two
things that happen to look alike; extracting them early couples things that
should evolve apart. On the third occurrence, extract — and extract the concept,
not the syntax.

**Before writing a helper, search the repo for one that already exists.** The
characteristic failure mode of agent-written code is three functions that format
a date three ways. Introducing a second way to do something that already has a
way is a defect, regardless of whether the code works.

### Documentation

- Every public API in `domain` and `data` carries a dartdoc comment: what it
  does, what it assumes, what it returns on the edge cases.
- Inline comments explain **why**, never **what**. `// increment counter` is
  noise. `// day 1 is excluded here because the protocol treats it as
  acclimatisation — see §4` is the comment worth writing.
- Anything that encodes a clinical rule cites its source in the comment.
- Non-obvious workarounds record what was tried and why it failed, so the next
  reader does not undo them.
- Update the doc comment in the same commit as the code. A stale comment is
  worse than none.

### Error handling

- No empty catch blocks. No catching `Exception` broadly to make an error go
  away.
- User-facing errors say what happened and what the user can do. Never surface a
  raw exception string.
- Data-loss-adjacent operations (import, migration, delete) confirm before
  acting and are reversible where possible.

---

## 7. Testing

Test where tests pay. Do not chase a coverage number.

- **`domain`: full TDD, no exceptions.** Protocol logic, averages, coverage
  calculation, threshold classification. These are pure functions with real
  consequences — write the failing test first.
- **`data`: tested thoroughly.** Serialisation round-trips, repository
  behaviour, and above all migrations.
- **`ui`: golden tests on key screens only.** Do not write widget tests
  asserting the structure of a `Column`. If you are about to, stop and ask.

Every bug fix starts with a test that reproduces the bug.

---

## 8. Workflow and definition of done

Work in vertical slices — "log a session end-to-end", not "build the data
layer". One branch per slice. If a slice exceeds ~400 lines of diff, it was two
slices; stop and split it.

A change is done when **all** of these hold:

- [ ] CI is green: `dart format --set-exit-if-changed`, `flutter analyze
      --fatal-infos --fatal-warnings`, `flutter test`
- [ ] tests exist for the domain and data code it touched
- [ ] a schema change, if any, has a committed snapshot and a passing migration
      test
- [ ] no new user-facing string is hardcoded
- [ ] public APIs it added are documented
- [ ] it did not introduce a second way of doing something the repo already does
- [ ] CHANGELOG.md is updated

**Never disable, downgrade, or `// ignore:` a lint rule to make the build pass.**
If a rule is genuinely wrong for this codebase, say so and ask. Silencing it is
not a fix.

**Never mark work complete with a red pipeline.** Report the failure instead.

---

## 9. Dependencies and i18n

Before adding any package to `pubspec.yaml`, verify and state in your message:

1. **Licence** — permissive (MIT / BSD / Apache 2.0) and unchanged. Packages
   have switched away from permissive licences mid-life; check the current
   `LICENSE` file, not the reputation.
2. **Maintenance** — last commit, open issue count, whether it supports the
   current Flutter stable.
3. **Necessity** — whether the standard library or an existing dependency
   already does this.

Popularity on pub.dev is not evidence of any of the three.

Localisation uses ARB files with English as the source locale. Every string the
user can see goes through the localisation layer from the moment it is written.
Retrofitting i18n is not on the plan.

---

## 10. When to stop and ask

Stop and raise it with the human rather than deciding, if:

- a change would alter the database schema in a way existing data cannot survive
- a feature would have the app interpret, diagnose, or advise (§1)
- a constraint in §2 is in the way
- an architectural boundary in §3 needs to be crossed
- a clinical rule is ambiguous and you would have to pick an interpretation
- the correct answer depends on how the app feels to use, which you cannot
  evaluate

The human is a backend and architecture specialist and knows the clinical
domain; Flutter and Android platform behaviour are the unfamiliar territory.
Push back on non-idiomatic Flutter proposals. Defer on domain modelling.
