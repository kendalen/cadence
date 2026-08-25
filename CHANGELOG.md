# Changelog

All notable changes to Cadence are documented in this file. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- The pinned "Last 7 days" coverage card now has a soft sand background, setting
  the summary apart from the white reading cards below it. The tint is a neutral
  warm colour, never a status colour — colouring it good/bad would cross the
  no-verdict boundary (§1).

### Fixed

- The "Remove" tooltip on a reading in the entry form showed "Remove this
  reading" instead of the short "Remove": `app_en.arb` defined `removeReading`
  twice and the later, longer entry silently won. The two actions now have
  distinct keys (`removeReading` / `removeReadingFromOccasion`), so each reads
  correctly; the Italian translation was split to match.

### Changed

- The 7-day trends view now plots every occasion as its own point instead of one
  average per day, so a day's morning and evening readings (the 7-2-2 protocol's
  two occasions a day) stay visible rather than being blended together. Points
  sit at their local time so same-day occasions separate on the axis, and their
  tooltip shows the time. The 30/90-day and All views keep their daily/adaptive
  averaging. Applies to every time-of-day filter (all / morning / evening).

### Added

- Trends chart (T3): a pulse chart on the trends screen, in its own tab beside
  blood pressure (the shared range/time-of-day controls drive both). Tabs let
  each chart fill the space instead of two being stacked. The pulse chart reuses
  the same line chart with a single pulse series in its own muted slate colour;
  when the chosen range holds no recorded pulse the pulse tab says so rather than
  drawing an empty axis, and buckets with no pulse are skipped, never drawn as
  zero.
- Trends screen (T2): a read-only blood-pressure chart reachable from a chart
  icon on the readings list. Two segmented controls choose the range (7 / 30 /
  90 days / All) and the time of day (all / morning / evening); the chart draws a
  faint per-day scatter behind bold averaged systolic and diastolic lines, with a
  legend and a tap-to-pin tooltip. In landscape the controls move to a compact
  vertical side rail so the chart gets the width. Neutral lines only — no threshold, no reference
  range, no good/bad colour, no verdict (§1). Adds the `fl_chart` dependency
  (MIT, verified in the resolved package's LICENSE).
- Trend-series domain aggregation (`buildTrendSeries`): range windowing,
  morning/evening filter, and adaptive daily/weekly/monthly averaging of
  session averages, for the upcoming trends chart. Domain-only (no UI yet).
- Italian localisation (S10): the full UI string set is translated to Italian, so
  a device set to Italian shows the app in Italian. English stays the source
  locale (CLAUDE.md §9); the register is informal ("tu"). Dropping in `app_it.arb`
  wires `it` into the supported locales automatically — no Dart change. ICU
  plurals and elided apostrophes are handled and covered by a test; the wording
  is pending a native-speaker review before release.
- Export confirmation (S9b): after the whole diary is shared as a JSON backup,
  CSV, or PDF, a brief message confirms it ("Backup shared." / "Readings
  exported.") — feedback the older audience was missing when the share sheet
  simply closed. It appears only when the share actually completes; backing out
  of the share sheet stays silent, as before.
- First-run disclaimer + About (S9a): on first launch, a one-time notice states
  plainly that Cadence is a diary for recording readings you measure yourself —
  not a medical device, and it does not diagnose, interpret, or advise — and
  points you to your doctor (CLAUDE.md §1). It must be acknowledged to continue
  and is then remembered, so it shows only once. An always-available "About"
  item in the overflow menu (set apart by a divider) shows the same statement
  plus the licences page, which includes the bundled Hanken font's OFL. Backed
  by a new app-settings key-value table (drift schema v3 — an additive migration
  with a committed snapshot and a migration test, CLAUDE.md §5) and a
  `SettingsRepository`, the groundwork the deferred Settings screen will reuse.
- CSV and PDF export (S8): two new items in the readings-list overflow menu —
  "Export as CSV" and "Export as PDF" — save the whole diary and open the
  Android share sheet, for handing a clinician the numbers. Both are
  export-only (only JSON backup is restorable, CLAUDE.md §2). One line per
  reading (not per occasion), oldest first, with an occasion number so readings
  taken together stay grouped without exposing internal ids; derived values such
  as the session average are never included (CLAUDE.md §4). Columns, the PDF
  title, and the context values (arm, position, medication) are all localised —
  the context wording reuses the entry form's own labels (CLAUDE.md §8, §9).
  Both carry a "self-recorded diary, not a medical diagnosis, discuss with your
  doctor" line, keeping Cadence's regulatory boundary visible on the export a
  doctor might see (CLAUDE.md §1). Notes containing commas, quotes or newlines
  are escaped per RFC 4180. Dates are numeric and locale-ordered
  (e.g. `8/25/2026` / `25/8/2026`). The PDF is landscape and embeds the bundled
  Hanken font so accented Italian text and typographic punctuation render
  correctly rather than as an empty box. Adds `pdf` (Apache-2.0) for pure-Dart
  PDF generation; no schema change.
- JSON backup import (S7b): an "Import backup" item in the readings-list
  overflow menu restores occasions from a JSON backup file, picked through the
  Android file picker (SAF). Merge is by occasion id and never overwrites — an
  occasion already in the diary is left exactly as it is (local data wins) — so
  the import is non-destructive; the confirmation states what will happen and
  the summary reports how many new occasions were added. The reader is forgiving
  but honest (CLAUDE.md §5): it ignores unknown fields, defaults missing optional
  ones, treats an unknown context value as unrecorded, and skips a malformed
  reading — but everything it cannot use is counted and surfaced, never dropped
  silently. A file that is not a Cadence backup, cannot be parsed, or was written
  by a newer version of the format is refused with a plain reason. Adds
  `file_selector` (BSD-3) for the file pick. New domain `ImportSummary` and
  `SessionRepository.importSessions` (merge-by-id in one transaction).
- JSON backup export (S7a): an "Export backup" item in the readings-list
  overflow menu saves the whole diary as a versioned JSON document and opens the
  Android share sheet. The format carries a top-level `format`/`version` and each
  reading's raw stored fields only — enums by name, timestamps UTC ISO-8601,
  optional fields omitted when unset, derived values never written (CLAUDE.md §4,
  §5). Encoding goes through `dart:convert`, so notes with quotes or newlines are
  escaped safely. The diary is read through the repository, not by copying the
  database file. Export only; restoring a backup (import) is a later slice.
  Adds `share_plus` (BSD-3) for the share sheet, sharing in-memory bytes with no
  temporary file.
- Weekly coverage summary (S6): a "Last 7 days" card pinned above the readings
  list reports two dimensions of coverage against the 7-2-2 protocol — occasions
  logged against the 14 expected (two a day), and distinct days logged against
  the 7 the protocol spans — so readings bunched into a few days are not mistaken
  for a full week's spread. When the window holds any occasion it also shows the
  period average (the mean of the occasions' averages). A statement of
  completeness, never a judgement of the readings and with no threshold
  (CLAUDE.md §1, §4). The window is a rolling last-7-days, so the heading is
  "Last 7 days" rather than "This week" (which would read as the calendar week).
  New pure domain `weeklyCoverage` / `MonitoringCoverage`; UI-only wiring, no
  schema change.
- App launcher icon: a cream "C" monogram with a terracotta beat-dot on the teal
  brand tile, generated for
  all densities plus an Android 8+ adaptive icon via `flutter_launcher_icons`
  (dev-only dependency). Source art in `assets/icon/`.

### Changed

- Build tooling: debug builds now install as a separate app
  (`net.kendalen.cadence.debug`, labelled "Cadence Debug") beside the release
  build instead of replacing it. Debug and release use different signing keys, so
  installing a debug build over a release one used to force an uninstall — which
  wipes the on-device diary (Auto Backup is off, §5). The suffix lets both live on
  the device with separate data. The release app id and label are unchanged.
- The "Last 7 days" summary is now compact in landscape: the same title, counts
  and average that stack over a few lines in portrait flow onto a single line
  when the phone is rotated, so the short landscape height is left for the
  readings instead of the summary. It stays pinned and visible either way, and
  falls back to more lines under very large font scales rather than clipping.
- Session detail: the occasion average now reads as the screen's hero — larger
  and in the teal brand colour, with the pulse smaller on its own line beneath —
  and the individual readings sit in their own card. New/edit reading forms give
  the notes, "Add details" and "Taken at" sections each their own card. Shared
  `SectionCard` keeps the padded-card look consistent (one way to do it, §8).
- Blood-pressure values are now shown in bold everywhere they appear (list,
  coverage summary, session average, each reading), via a shared `PressureText`
  widget that holds that design invariant and the one value formatting in a
  single place (§8).
- Device launcher name is now "Cadence" (was lowercase "cadence").

### Fixed

- PDF export column widths (S10 follow-up): the readings table gave every column
  an equal share, so longer localised text — and even dates and times — broke
  across lines mid-value ("Sistolic/a", "18/08/202/6"). The date, time and
  numeric columns now size to their content (never wrapping a value) and the text
  columns flex and wrap only at word boundaries.
- "Last 7 days" coverage could read "8 of 7 days" (S9b): the window was a rolling
  168-hour cutoff, which straddles eight calendar days when opened mid-day. It is
  now the local calendar day of today plus the six days before it, so the
  distinct-days count can never exceed seven and the occasions window matches
  (CLAUDE.md §4).
- The readings list now has room at its end so the last card scrolls clear of
  the floating "Add a reading" button instead of hiding behind it.
- Content no longer hides under the Android system bars. Scrollable screens
  (readings list, entry, edit/add reading, session detail) pad past the
  navigation bar at the bottom and — new — past a side bar or display cutout
  when the phone is rotated to landscape, where the bar moves to a side edge.
  Before, a Save button or a card's side border could slide off under the bar
  and be hard or impossible to tap (`withSystemInsets`, generalised from the
  earlier bottom-only helper).

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
  the mean of past occasion averages, preferring the most specific data
  available: occasions from the last two weeks (`firstReadingWindow`) in the
  same half of the day — morning before local noon, evening after — then the
  same half-day at any age, then any occasion at all, with 120/80 remaining only
  when there is no history (`suggestedFirstReading`, CLAUDE.md §4). Recency keeps
  the guess close to the user's current level (blood pressure drifts with
  medication and time, so a recent change shows through in a week or two rather
  than being buried under years of readings); the morning/evening split keeps it
  to the right time of day, since those pressures differ. The two-week window
  matches the 7-2-2 protocol's own timescale. The first reading's context (arm,
  posture, before/after medication) is prefilled from the most recent stored
  reading. It is a gentle nudge, not a norm or a target: every value is the
  user's own data, shown and fully editable before it is saved. The form waits
  for a one-shot history read (`SessionRepository.recentHistory`) before it
  opens, so the numbers never change under the user (roadmap ease-of-use
  principle; the audience skews older).
- Design foundation: the approved "warm & reassuring" visual language turned
  into a Material 3 theme (`lib/ui/theme/`). An explicit warm `ColorScheme` —
  teal as the structural accent, one reserved terracotta "clay" action colour,
  warm paper/sand surfaces — and Hanken Grotesk, bundled as a single
  variable-weight app asset under the SIL Open Font License 1.1 rather than the
  network-fetching `google_fonts` package (CLAUDE.md §2), with card,
  filled-button, app-bar, and floating-action-button component themes. Wired into
  `MaterialApp`, so the existing screens re-skin centrally. Colour is never used
  to grade a reading and no threshold line is drawn (CLAUDE.md §1, §4). The "Add
  a reading" button is now a labelled extended FAB. A golden test pins the
  readings-list empty state, through a tolerant comparator so one committed
  baseline holds across the maintainer's macOS and the Linux CI runner.
- Session detail (S4): tapping an occasion in the list opens a read-only detail
  screen showing its individual readings — each with its time, pulse, and any
  recorded context and note (`ReadingDetail`) — and, when the occasion holds more
  than one, their average above them (`Session.average`, CLAUDE.md §4). The
  average is shown as a fact about the occasion, never coloured or labelled good
  or bad and with no threshold (CLAUDE.md §1, §4); a single-reading occasion
  shows just the reading, since its average would only repeat it. This replaces
  the S2d in-place row expansion with one consistent path to a session's
  readings, and is where editing and deleting (a later slice) will live.
- Delete an occasion (S5a): the session detail screen can remove the whole
  occasion and its readings. It confirms first with a dialog, then — on success
  — leaves the screen and shows an "Undo" that restores the occasion as it was
  (CLAUDE.md §6, data-loss-adjacent actions confirm and are reversible). Backed
  by a new `SessionRepository.delete(SessionId)` (readings cascade away with the
  session; deleting an absent session is a no-op that still succeeds) and a small
  `SessionDetailCubit` so the UI reaches the store through a cubit, not directly
  (CLAUDE.md §3).
- Edit and remove readings (S5b): on the session detail screen, tap a reading to
  correct its values, pulse, note and context in a focused editor (reusing the
  entry steppers, context pickers and `ReadingInput` validation); the reading
  keeps its identity (`Reading.withId`), so the store updates it rather than
  adding a new one. Editing the time is not part of this slice. A reading can
  also be removed from an occasion that holds more than one, with an "Undo"
  (removing the last one is instead the whole-occasion delete, which keeps its
  dialog). The detail screen now tracks the store, so an edit's new values show
  without a stale snapshot. Backed by a new `SessionRepository.update(Session)`
  (replaces an occasion's readings in one transaction) and the domain helpers
  `Session.withReadingReplaced` / `withoutReading` (the latter returns `null`
  when it would empty the occasion, encoding the ≥1-reading rule, CLAUDE.md §4).
- The readings list now shows each occasion as a card, matching the approved
  visual design; colour, border, radius and spacing come from the theme's
  `cardTheme`.
- Add another reading to a saved occasion (S5c): an "Add another reading" button
  on the session detail screen appends a reading to an occasion that was saved
  too soon — a common slip for the audience the app serves. It opens the
  single-reading form seeded from the occasion's latest reading (numbers and
  context carried over, note cleared, time about a minute later), all editable,
  and appends on save (`Session.withReadingAdded`).
- The reading form now lets the **time** be edited too, not just the values —
  the same date/time picker the entry form uses, extracted into a shared
  `TakenAtField` so a reading's time is picked one way everywhere (the entry
  edit screen from S5b is generalised into `ReadingFormScreen`, serving both
  edit and add; the reading's identity is decided by the caller).
