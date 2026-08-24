# Project status

A living, git-tracked handoff note — the shared "memory" that travels between
machines and sessions. Keep it current: when you finish a slice or make a
decision worth remembering, update this file in the same commit. It complements
`CHANGELOG.md` (which records *what shipped*); this file records *where things
stand and what's next*.

**Last updated:** 2026-08-24

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
  the tile still showed only the first reading). A row **expands in place** to
  show its individual readings, each with its own time, pulse and any recorded
  context/note (`Session.readingsByTime`; first place context surfaces in the
  UI) — **S2d**; a lone reading with no extra detail does not expand.
- **Tests:** domain + data covered; an end-to-end smoke test (incl. a
  two-reading occasion, a context round-trip, and expanding a row to reveal its
  readings). All green (90).
- **Verified running:** debug APK builds and runs on a physical Android device
  (as of the "log a session" slice).

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

**Next up:** **S3 — fast entry** per the roadmap; it touches the same entry form
S2 just reworked, so mind the overlap when scoping. The entry form's sub-widgets
are split out (`banked_readings.dart`, `reading_context_details.dart`) to keep
`session_entry_screen.dart` under the ~300-line smell line (CLAUDE.md §6).

## Working reminders

- Vertical slices, one branch per slice; a slice over ~400 lines of diff was two.
- Definition of done: `CLAUDE.md` §8 (CI green, tests, docs, CHANGELOG, no
  hardcoded strings, no second way to do an existing thing). Never silence a lint.
- Defer domain/clinical modelling decisions to the maintainer (`CLAUDE.md` §10);
  push back on non-idiomatic Flutter.
