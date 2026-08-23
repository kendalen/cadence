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
- Android backup disabled: `android:allowBackup="false"` plus a
  `data_extraction_rules.xml` that also excludes device-to-device transfer,
  which `allowBackup` alone does not cover on Android 12+ (CLAUDE.md §5).
