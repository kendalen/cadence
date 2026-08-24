# Project status

A living, git-tracked handoff note — the shared "memory" that travels between
machines and sessions. Keep it current: when you finish a slice or make a
decision worth remembering, update this file in the same commit. It complements
`CHANGELOG.md` (which records *what shipped*); this file records *where things
stand and what's next*.

**Last updated:** 2026-08-24

---

## Current state

Early scaffolding with one vertical slice complete: **log a session
end-to-end**.

- **Domain:** `Session` / `Reading` entities, typed ids, `ReadingInput.validate()`
  (plausibility bounds — typo guards, not clinical thresholds), a sealed `Result`
  type, and the `SessionRepository` / `IdGenerator` interfaces.
- **Data:** drift schema v1 (`Sessions` 1‑to‑many `Readings`, cascade delete),
  UTC ISO‑8601 timestamps, `DriftSessionRepository`, UUID v7 ids, committed
  schema snapshot + migration test harness.
- **UI:** readings list + entry form on `flutter_bloc` Cubits; all strings in ARB.
- **Tests:** domain + data covered; an end-to-end smoke test. All green (49).
- **Verified running:** debug APK builds and runs on a physical Android device.

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

## Candidate next slices

Not yet decided — pick one, then design it (brainstorm first, TDD the domain per
`CLAUDE.md` §7). Ideas, roughly in dependency order:

- Session average display (mean of a session's readings).
- 7‑2‑2 coverage reporting: readings collected vs expected, with under-sampled
  averages labelled as such (`CLAUDE.md` §4).
- Readings history / session detail view.
- Optional, user-configurable "discard day 1" setting (literature is divided —
  do not hardcode either behaviour).
- Export: versioned JSON backup first (the only restorable format), then CSV/PDF
  export-only, via the Android share sheet / SAF.

## Working reminders

- Vertical slices, one branch per slice; a slice over ~400 lines of diff was two.
- Definition of done: `CLAUDE.md` §8 (CI green, tests, docs, CHANGELOG, no
  hardcoded strings, no second way to do an existing thing). Never silence a lint.
- Defer domain/clinical modelling decisions to the maintainer (`CLAUDE.md` §10);
  push back on non-idiomatic Flutter.
