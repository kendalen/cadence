# Changelog

All notable changes to Cadence are documented in this file. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Project scaffolding: Android-only Flutter application (package
  `net.kendalen.cadence`) with the three-layer source tree `lib/domain`,
  `lib/data`, `lib/ui` and a placeholder test per layer (CLAUDE.md §3, §7).
- Strict static-analysis configuration in `analysis_options.yaml`, layered on
  top of `flutter_lints` with the analyzer's strict language modes.
- Import-boundary enforcement via the `import_rules` analyzer plugin: the domain
  layer stays pure (no Flutter, Drift, I/O, or upward imports) and the data
  layer may not import ui (CLAUDE.md §3).
- ARB-based localisation scaffolding with English as the source locale
  (CLAUDE.md §9).
- `lefthook` pre-commit hook mirroring the CI gate: `dart format`,
  `flutter analyze`, `dart analyze` (boundaries), and `flutter test`
  (CLAUDE.md §8).
- Continuous integration: a GitHub Actions workflow
  (`.github/workflows/ci.yml`) that runs the same gate as the pre-commit hook —
  format, analyze, import boundaries, and tests — on Linux for pushes and pull
  requests to `main` (CLAUDE.md §8).
- Log a session end-to-end: enter one reading on a form, store it, and see it
  in a list that survives a restart. The first vertical slice, designed in
  `docs/superpowers/specs/2026-08-23-log-session-end-to-end-design.md`.
- Domain: `Session` and `Reading` entities, typed `SessionId`/`ReadingId`,
  `ReadingInput.validate()` with plausibility bounds (typo guards, not
  clinical thresholds), a sealed `Result` type, and the `SessionRepository`
  and `IdGenerator` interfaces (CLAUDE.md §4).
- Data: drift schema v1 (`Sessions` one-to-many `Readings`, cascade delete),
  timestamps stored as UTC ISO-8601 text, `DriftSessionRepository`, UUID v7
  identifiers, the committed `drift_schema_v1.json` snapshot, and the
  migration test harness (CLAUDE.md §5).
- UI: the readings list and the entry form, on `flutter_bloc` Cubits, with
  every user-facing string in the ARB (CLAUDE.md §9).
- Optional reading context (CLAUDE.md §4): `MeasurementSite` (left/right arm or
  wrist), `Posture` (sitting/standing/lying), and `MedicationTiming`
  (before/after) on each `Reading`, all nullable and defaulting to unrecorded.
  Persisted by enum name in drift schema v2; existing readings survive the
  v1→v2 migration with null context, covered by a committed
  `drift_schema_v2.json` snapshot and migration tests (CLAUDE.md §5). No UI yet
  — the entry pickers arrive with the entry-form slices.
- Android backup disabled: `android:allowBackup="false"` plus a
  `data_extraction_rules.xml` that also excludes device-to-device transfer,
  which `allowBackup` alone does not cover on Android 12+ (CLAUDE.md §5).
- An end-to-end smoke test driving the real app against an in-memory
  database: enter a reading, save it, and find it in the list, including
  after the widget tree is rebuilt.
- Multiple readings per occasion in the entry flow: bank a reading with "add
  another reading", review and remove banked readings, and save the occasion as
  one multi-reading session (CLAUDE.md §4). Logging a single reading is
  unchanged — fill and save.
- Optional context pickers in the entry form: per reading, choose where it was
  measured (arm/wrist), the body position, and before/after medication, in a
  collapsible "Add details" section defaulting to not-recorded (CLAUDE.md §4).
- `Session.average`: the mean of an occasion's readings as a `SessionAverage`
  value object (CLAUDE.md §4). Systolic and diastolic are averaged separately,
  each rounded to the nearest whole mmHg (a half rounds up); pulse is the mean
  of only the readings that recorded one, or absent when none did. Derived,
  never stored.
- The readings list now shows each occasion as its average rather than its
  first reading, with a badge counting the readings behind a multi-reading
  average so it is never mistaken for a single measurement. A single-reading
  occasion looks unchanged.
- Tap an occasion in the list to expand it in place and see its individual
  readings, each with its own time, pulse, and any recorded context (arm,
  posture, before/after medication) and note (CLAUDE.md §4) — the first place
  reading context surfaces in the UI, shown as fact, not interpreted. Readings
  are ordered by time (`Session.readingsByTime`). A lone reading with no such
  detail does not expand, since it would only repeat the row. Read-only;
  editing and deleting remain a later slice.
- Fast entry (S3a): systolic, diastolic and pulse are now large numbers with big
  − / + steppers on either side, sized for the older audience the app targets —
  large type, tap targets over the 48dp minimum, and screen-reader labels on
  every button (roadmap ease-of-use principle). The number is still typeable for
  a big jump, and typing stays unclamped so `ReadingInput.validate` remains the
  one typo guard (CLAUDE.md §4). A new occasion opens on a neutral default
  (120/80, no pulse) so there is always something to step from; "add another
  reading" now carries the numbers and context of the reading just banked into
  the next one instead of clearing them, since readings a minute apart cluster.
  Pulse stays optional: it shows a dash until set and has a clear button back to
  "not recorded" (CLAUDE.md §4). The morning/evening-average prefill for the
  first reading is the next slice (S3b).
- History-aware first-reading prefill (S3b): a new occasion's first reading now
  opens on the user's own numbers instead of the fixed 120/80. The estimate is
  the mean of past occasion averages in the same half of the day — morning
  before local noon, evening after, matching the 7-2-2 two-occasions-a-day shape
  — since readings cluster by time of day; when that bucket is empty it falls
  back to all history, and 120/80 remains only when there is no history at all
  (`suggestedFirstReading`, CLAUDE.md §4). The first reading's context (arm,
  posture, before/after medication) is prefilled from the most recent stored
  reading. It is a gentle nudge, not a norm or a target: every value is the
  user's own data, shown and fully editable before it is saved. The form waits
  for this one-shot history read (`SessionRepository.recentHistory`) before it
  opens, so the numbers never change under the user (roadmap ease-of-use
  principle; the audience skews older).
