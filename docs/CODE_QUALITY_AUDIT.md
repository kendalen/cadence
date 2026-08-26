# Code Quality Audit

> **Resolution log (2026-08-26, branch `audit-correctness-fixes`, pushed):**
> - **CQ-13** fixed — pulse tooltip resolved by x per line; crash gone.
> - **CQ-05** fixed — settings adapter defaults-safe on storage failure (the §1
>   notice can't be skipped); the Trends stream-error half also fixed (message,
>   not an endless spinner). *Remaining CQ-05 items: broad `on Exception` in
>   transfer/About, and the StreamBuilder-vs-Cubit architecture choice — open.*
> - **CQ-01** fixed — both destructive-undo paths await the restore and report a
>   failure.
> - **CQ-04** fixed — one `DateWindow` value (inclusive lower + upper bound,
>   positive-length validation) now backs coverage, ranged export, and trends;
>   future-dated readings excluded; three copies collapsed to one.
> - Also folded in: chart tabs no longer clip the last point (maintainer report).
>
> **Still open — maintainer's call (§10):** CQ-14 (label an under-sampled
> average — clinical threshold), CQ-02 (backup-import validation policy), CQ-03
> (release-safe domain invariants + immutable collections).
> **Open — low value / optional:** CQ-06, CQ-07, CQ-08, CQ-09, CQ-10, CQ-11,
> CQ-12, CQ-15, and the two CQ-05 items noted above.

**Audit date:** 2026-08-25

**Branch:** `s-settings-and-ranged-export`

**Previous snapshot:** `111531f47c546c94ffae1884b8a56acc16833c15`

**Integrated snapshot:** `b3d46e8a5c961ba5177653fbc4c6efc481b5b238`

**Audit focus:** readability, correctness, module design, pattern use,
duplication, tests, documentation, and common AI-generated-code failure modes.

## Executive summary

Cadence still does **not** read as generic AI slop. The new work preserves the
project's domain vocabulary, layered imports, explicit composition root,
transactional Drift adapter, schema-migration discipline, localization, and
behavior-focused tests. The settings-table migration is additive and tested;
trend aggregation is kept in pure Dart; export sharing still crosses one adapter;
and extracting the overflow menu reduced `session_list_screen.dart` from 447 to
225 lines.

The update also demonstrates the main risk of fast AI-assisted iteration: a
large amount of polished code and confident commentary landed while important
unhappy paths remained untested. Two newly introduced correctness defects deserve
attention before release:

1. The Pulse chart can use an index from the complete point list against a list
   from which null-pulse points were removed. Tapping a later point can therefore
   select the wrong point or throw a range error.
2. The first-run disclaimer's repository contract promises safe read/write
   fallback, but neither the adapter nor the gate implements it. A settings read
   failure can bypass the notice with an unhandled asynchronous exception.

The original high-priority data-safety findings remain open: undo writes are
ignored, backup import is not honest about malformed optional data, and core
domain invariants disappear in release builds. The old eight-calendar-day
coverage bug is fixed, but all three new/current "last N days" implementations
still accept future-dated sessions and now constitute duplicated domain logic.

**Overall assessment:** strong engineering foundation and automated hygiene, but
not yet release-quality for data safety and failure handling. The most visible
"AI slop" signals are now documentation drift, over-produced comments, repeated
calendar-window logic, and large UI state classes—not naming, formatting, or a
lack of tests.

## Scope and method

- This is a delta review of `111531f...HEAD`, followed by an integration of the
  new evidence into the original audit. The comparison contains 53 changed files,
  4,643 insertions, and 420 deletions.
- The code-review graph was queried before source scanning, as required by the
  repository instructions. At the integrated snapshot it covered 103 files, 605
  nodes, and 4,928 resolved edges. Its impact analysis classified the change as
  high impact: 330 directly changed nodes and 144 affected nodes across 60
  additional files.
- Graph execution-flow and automated test-link results were not treated as
  authoritative: the graph reported no affected flows and misclassified many
  Dart test nodes. Tests and source were therefore checked directly after graph
  exploration.
- Generated Drift and localization sources were excluded from readability and
  file-size judgments. Their migration path and integration were still reviewed.
- The working tree was active during the audit. Findings and line references were
  rechecked against `b3d46e8`; later changes are outside this snapshot.

## Verification result

The documented `lefthook run pre-commit` command skipped all four checks because
there were no matching staged files. It was therefore not counted as evidence.
The commands were run directly against the integrated snapshot instead:

- `dart format --output=none --set-exit-if-changed .`: 103 files checked, 0
  changed.
- `flutter analyze --fatal-infos --fatal-warnings`: no issues.
- `dart analyze --fatal-infos --fatal-warnings`: no issues, including import
  boundaries.
- `flutter test --reporter compact`: 249 tests passed.

This is a materially stronger suite than the 204-test previous snapshot. The
remaining findings are behaviors the analyzer cannot prove and scenarios the
suite does not exercise.

## What improved in this update

- The inclusive rolling 168-hour coverage calculation was replaced with an exact
  seven-local-date window, and a regression test now proves the boundary cannot
  produce eight logged dates.
- `SessionOverflowMenu` was extracted and `SessionListScreen` became focused on
  list layout and navigation. This is a real improvement to locality, not a
  cosmetic file split.
- Schema v3 follows the established pattern: explicit migration, committed schema
  snapshot, generated migration helper, and migration test.
- Trends separate pure aggregation from chart rendering. `TrendRange`,
  `TimeOfDayFilter`, `TrendPoint`, and `TrendSeries` are meaningful domain
  names, and the domain suite covers aggregation, filtering, buckets, and
  timezone injection in depth.
- Sharing remains centralized in `shareExportBytes`; JSON, CSV, and PDF do not
  each grow their own plugin integration.
- The full English/Italian ARB wiring and native-behavior tests improve product
  completeness. The remaining Italian wording review is documented honestly.

## Findings

### CQ-01 — High, open: destructive-action undo can fail silently

The whole-session and single-reading undo actions still invoke repository writes
and discard `Future<Result<...>>`:

- `lib/ui/sessions/detail/session_detail_screen.dart:142-160`
- `lib/ui/sessions/detail/session_detail_screen.dart:286-300`

If deletion succeeds and restoration fails, the UI offered an undo that did not
restore the data. The `ponytail:` comment at lines 152-154 says the write "all but
never fails", exactly the assumption the repository's `Result` type is intended
to prevent.

**Recommendation:** await undo through the detail controller/cubit, map `Err` to
a localized restore-failed state, and test both undo failure paths.

### CQ-02 — High, open: backup import silently discards or accepts bad data

`_decodeReading` still turns malformed optional values into absence without a
warning: non-integer pulse, non-string notes, and unknown context enums become
`null` (`lib/data/backup/backup_decoder.dart:151-208`). It also bypasses
`ReadingInput` bounds, so negative or implausible pressures/pulse, empty IDs, and
duplicate IDs can reach the domain or fail later as a generic transaction error.

This contradicts the documented import rule that unusable data is surfaced rather
than silently dropped (`CLAUDE.md:144-146`, `CHANGELOG.md:110-114`).

**Recommendation:** define a structured import-validation policy, distinguish
missing optional fields from malformed supplied fields, validate ranges and IDs,
and detect duplicates before confirmation.

### CQ-03 — High, open and expanded: domain values are not reliably immutable

`Session` enforces a non-empty reading list only with `assert` and stores the
caller's mutable list (`lib/domain/sessions/session.dart:12-20`). `Reading`
enforces UTC only with `assert` (`lib/domain/sessions/reading.dart:11-26`). In a
release build these contracts disappear; after construction, a caller can also
clear `Session.readings`, destabilizing equality and breaking reductions.

The new `TrendSeries` repeats the mutable-list problem for `daily` and
`averaged` (`lib/domain/sessions/trend_series.dart:84-106`).

**Recommendation:** use validating factories/constructors whose production
semantics do not depend on assertions, and make defensive unmodifiable copies of
collections. Add mutation-resistance tests.

### CQ-04 — Medium, partially resolved: date-window logic is duplicated and has no upper bound

The original eight-of-seven defect is fixed. However, these three domain paths
independently implement local-calendar lower-bound filtering:

- `weeklyCoverage` (`lib/domain/sessions/weekly_coverage.dart:78-103`)
- `sessionsInLastDays` (`lib/domain/sessions/sessions_in_last_days.dart:16-32`)
- `buildTrendSeries` (`lib/domain/sessions/trend_series.dart:115-140`)

None excludes local dates after `today`. Future timestamps can enter through the
tolerant backup path, so coverage can again exceed seven days and ranged exports
or trends can include data outside a window described as "ending today".
`sessionsInLastDays` also does not validate that `days > 0`.

The duplication matters because this is now the third implementation and the
files explicitly claim there is "one notion" of day boundaries.

**Recommendation:** introduce one tested civil-date window/value function with
inclusive lower and upper bounds, reuse it from coverage/export/trends, validate
the window length, and add future-date and DST-boundary tests.

### CQ-05 — High/Medium, regressed: expected failure handling is internally inconsistent

Several new paths either swallow too much or handle nothing:

- `SettingsRepository` says failed reads default safely and failed writes are not
  fatal (`lib/domain/settings/settings_repository.dart:9-12`), but
  `DriftSettingsRepository` lets both throw and `FirstRunGate` catches neither
  (`lib/data/settings/drift_settings_repository.dart:18-35`,
  `lib/ui/first_run_gate.dart:31-40`). A read failure leaves the underlying diary
  reachable without the mandatory notice; a write failure becomes unhandled.
- `TrendsScreen` treats a stream error as `!hasData` and displays a permanent
  spinner (`lib/ui/sessions/trends/trends_screen.dart:54-69`). It also introduces
  `StreamBuilder` beside the project's declared single Cubit state-management
  approach.
- Settings export performs `repository.recentHistory()` outside its `try` block,
  despite the method comment promising that preparation failures are reported
  (`lib/ui/settings/settings_screen.dart:120-147`).
- Broad `on Exception` catches remain in transfer UI and were added to About;
  these collapse expected plugin failures and programming defects into the same
  generic outcome.

**Recommendation:** make the repository contract truthful, model explicit
loading/error states, catch only known operational failures at adapters, and
report unexpected exceptions while showing safe localized UI. Add failing-read,
failing-write, stream-error, and history-read-error tests.

### CQ-06 — Medium, improved but open: orchestration remains concentrated in widgets

The list/overflow extraction is a good improvement. The remaining concentrations
are now:

- `session_detail_screen.dart`: 400 lines;
- `trend_line_chart.dart`: 381 lines, with a state class of about 251 lines;
- `trends_screen.dart`: 322 lines, with a state class of about 251 lines;
- `settings_screen.dart`: 217 lines and owns repository reads, filtering, asset
  loading, encoding, sharing, and outcome mapping.

The trend files exceed the repository's ~300-line file / ~200-line class smell
thresholds (`CLAUDE.md:163-164`).

**Recommendation:** extract behavior at stable seams: a typed transfer workflow,
a detail mutation/undo controller, and chart interaction/bounds helpers. Avoid
splitting into one-method widget files; the goal is smaller interfaces and
independently testable behavior.

### CQ-07 — Medium, open: duplicated reading forms have diverged

Entry and edit/add still assemble the same pressure, pulse, notes, context, time,
and validation concept separately. Empty pulse starts at 60 in one path and 20 in
the other because only the entry form supplies `startWhenEmpty`.

**Recommendation:** extract a reading-draft form model/module and pin shared
behavior with contract tests, while leaving screen-specific navigation and
banking outside it.

### CQ-08 — Medium, open: the fake repository is not contract-faithful

The fake still differs materially from Drift: missing-session update returns
`Ok`, `watchAll` does not emit current state on subscription, `recentHistory`
is independent from accepted writes, and duplicate import IDs behave differently
(`test/support/fake_session_repository.dart:13-103`). The new trends/settings
tests depend more heavily on this seam, increasing the cost of that mismatch.

**Recommendation:** define repository adapter contract tests and run them against
both Drift and the fake.

### CQ-09 — Medium, partially resolved: authoritative documentation still conflicts

README was substantially improved, but drift remains:

- README says the chart screen is still next after the full Trends screen landed
  (`README.md:33-34`).
- ROADMAP still says release signing is pending and trends/date-bounded export are
  explicitly outside v1.0 (`docs/ROADMAP.md:124-126`, `144-168`), while STATUS
  and the code call all of them done/current work.
- The architecture arrow still says `ui -> domain -> data`, contradicting the
  prose and enforced `data -> domain` dependency (`CLAUDE.md:58-69`).
- CHANGELOG has repeated `Added` and `Changed` headings in one Unreleased
  section and still contains historical claims that About/export live in the
  overflow menu after they moved (`CHANGELOG.md:9-24`, `38-88`).
- STATUS retains an obsolete `ponytail:` reference to `pdf_report.dart`, while
  two unexplained `ponytail:` markers remain elsewhere.

This remains a stronger AI-generated-code smell than formatting: prose is
abundant and confident, but not reconciled as behavior changes.

**Recommendation:** choose one v1.0 scope authority, reconcile ROADMAP/STATUS/
README/CHANGELOG in the same change, fix the dependency diagram, and remove
agent-workflow markers from product source.

### CQ-10 — Low, open: comments remain over-produced

The new files continue to document most constructors, fields, obvious layout
choices, and local statements, often citing `CLAUDE.md` sections. Some comments
record valuable DST, clinical, and plugin constraints; others narrate the next
line and make already-large classes longer. The contrast between comment volume
and missing unhappy-path tests is a recognizable generated-code texture.

**Recommendation:** retain comments for invariants, persistence compatibility,
clinical constraints, and non-obvious workarounds. Prefer named code and tests for
ordinary control flow; trim comments only as touched code is refactored.

### CQ-11 — Low, open: export filenames use UTC calendar dates

`_exportFilename` still converts the human-visible filename date to UTC
(`lib/ui/sessions/export/share_export.dart:56-60`). Just after local midnight in
a positive offset, the file can carry yesterday's date.

**Recommendation:** use local wall-clock date, or make and test an explicit zone
policy. The precise UTC instant already lives inside JSON backup content.

### CQ-12 — Low, open: picker label bypasses localization

`XTypeGroup(label: 'Cadence backup')` remains hardcoded
(`lib/ui/sessions/backup/pick_backup.dart:9-14`).

**Recommendation:** pass a localized label into the picker adapter if surfaced by
the platform, or document that the target platform ignores it.

### CQ-13 — Medium, new: sparse Pulse data can corrupt tooltip selection or crash

The chart derives `selectedIndex` from the complete `data.averaged` list
(`lib/ui/sessions/trends/trend_line_chart.dart:82-86`). `_lineBar` then removes
every point for which the selected series returns `null`, as Pulse legitimately
does (`trend_line_chart.dart:218-235`). The original index is subsequently used
against the shortened `spots` list, including a direct
`averagedBars[i].spots[selectedIndex]` access (`trend_line_chart.dart:157-167`).

For example, if the first bucket has no pulse and the second does, tapping the
second Pulse point yields index 1 against a one-element Pulse spot list. Existing
tests cover all-pulse and no-pulse states, not mixed gaps or tooltip interaction.

**Recommendation:** track selection by x-coordinate per bar, resolve the matching
spot index after null filtering, and omit an indicator for a series without that
x. Add mixed-null Pulse tests that tap the first and later visible points.

### CQ-14 — Medium, newly identified spec gap: under-sampled averages are not labelled

The product rules require an average based on insufficient data to be labelled as
such (`CLAUDE.md:116-118`, `docs/ROADMAP.md:86-90`). `WeeklyCoverageCard`
renders the ordinary `Average` label whenever even one occasion exists; it shows
counts nearby but has no under-sampled state or explicit wording
(`lib/ui/sessions/list/weekly_coverage_card.dart:48-65`, `111-138`).

**Recommendation:** define the sufficiency threshold/domain state, expose it from
coverage, localize the label, and test one-occasion, partial, and complete weeks.

### CQ-15 — Low/Medium, new: native launcher labels bypass localization

Gradle hardcodes `Cadence` and `Cadence Debug` as manifest placeholders
(`android/app/build.gradle.kts:46-48`, `62-80`). These are user-visible launcher
labels and contradict the no-hardcoded-UI-string rule (`CLAUDE.md:51-52`).

**Recommendation:** use Android string resources with locale-qualified values for
the release and debug labels, or explicitly document the launcher-name exception
to the Flutter ARB rule.

## Pattern and duplication assessment

| Pattern / practice | Assessment after update |
| --- | --- |
| Repository | Appropriate and useful. Settings adds a legitimate boundary, but its failure contract and fake behavior need correction. |
| Result/Either | Appropriate for expected writes. Ignored undo results and exception-based settings reads weaken consistency. |
| Explicit dependency injection | Strong at the composition root. Direct workflow orchestration in widgets remains inconsistent with the Cubit/controller style. |
| State management | Cubit is established; the Trends `StreamBuilder` is a second approach and lacks an error state. |
| Adapter seams | Share and picker are centralized. Transfer orchestration, clock, chart interaction, and asset loading still need more testable seams. |
| Value objects | Typed IDs, averages, ranges, filters, and trend points clarify intent. Runtime invariants and collection immutability remain incomplete. |
| Strategy/factory/inheritance | No pattern ceremony, deep inheritance, or speculative framework was found. |
| Generated persistence code | Correctly isolated; schema v3 migration discipline is strong. |

There is still no widespread utility-level copy/paste. The important duplication
is conceptual:

- three calendar-window implementations now need one domain abstraction;
- two reading forms already differ behaviorally;
- responsive Trends controls have separate horizontal/vertical renderers, though
  their option data is correctly single-sourced;
- repository/plugin failure-to-snackbar mapping is repeated instead of returning
  typed workflow outcomes.

## Delta review: Standards

- **Hard violation:** Android adds hardcoded user-visible launcher labels, contrary
  to the localization rule.
- **Hard violation:** Trends introduces `StreamBuilder` despite the one-state-
  management-approach rule and has no stream-error UI.
- **Hard violation:** first-run settings failures escape despite the repository's
  documented safe-failure contract.
- **Hard violation:** broad `on Exception` handling in transfer/About paths can
  collapse programming defects into generic fallback UI.
- **Judgment-call smell:** `trend_line_chart.dart` and its state class exceed the
  documented size thresholds.
- **Judgment-call smell:** `trends_screen.dart` and its state class exceed the
  documented size thresholds; responsive control rendering has some duplication.

Prior findings CQ-01 through CQ-03, CQ-07, CQ-08, and CQ-10 through CQ-12 remain
open. CQ-04 and CQ-06 improved but are only partially resolved; CQ-05 worsened;
CQ-09 improved in README but remains open elsewhere.

## Delta review: Spec

- **Missing:** S6 requires under-sampled averages to be labelled; the coverage
  card does not implement a distinct under-sampled state.
- **Partial:** S10 wiring is complete, but STATUS and CHANGELOG still record the
  native-speaker wording pass—especially medical/disclaimer strings—as pending.
- **Specification conflict:** ROADMAP defers trends and date-bounded export to
  1.x, while STATUS records maintainer reprioritization and completion. The
  documents must be reconciled before these can be classified cleanly as scope
  creep or required v1.0 work.
- **Possible scope creep:** B1 required upload-key setup and documentation; a
  separate user-visible debug app is a defensible data-safety measure but was not
  in the stated B1 requirement.

**Delta summary:** 6 Standards findings (4 hard, 2 judgment calls) and 4 Spec
findings. The worst Standards issue is unhandled launch/stream failure behavior;
the worst Spec issue is the missing under-sampled-average state.

## Recommended remediation order

1. Fix sparse-Pulse selection/indexing and add an interaction regression test.
2. Make first-run, Trends stream, and Settings history failures explicit and
   tested.
3. Make both destructive undo paths failure-safe.
4. Define and enforce an honest backup-import validation contract.
5. Enforce production domain invariants and immutable collections.
6. Centralize civil-date windows with both lower and upper bounds.
7. Model and label under-sampled coverage averages.
8. Add repository adapter contract tests and make the fake faithful.
9. Move transfer/detail/chart behavior behind small typed seams; then unify the
   reading-draft form.
10. Reconcile product/release documentation and native localization; add an
    explicit release lane that fails closed if a distributable signing key is
    absent.

## Suggested quality bar for future vibe-coded slices

- Record domain/data invariants and state how each is enforced in release builds.
- Add at least one unhappy-path test for every repository or platform operation.
- Run a contract suite whenever both production and fake adapters implement a
  seam.
- Search for existing time, formatting, serialization, and error-mapping concepts
  before adding another implementation.
- Trigger design review at 300 lines per hand-written file or 200 per class.
- Test nullable/sparse series, empty data, first/last points, and interaction—not
  only fully populated chart examples.
- Reconcile README, ROADMAP, STATUS, and CHANGELOG in the same feature change.
- Treat confident comments about fallback, "cannot fail", or broad catches as a
  request for a failure-path test.

With these controls, openly describing the project as vibe-coded should not harm
its credibility: the engineering evidence will be stronger than the generation
method.
