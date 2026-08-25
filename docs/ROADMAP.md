# Roadmap to v1.0

The plan for a complete, Play-Store-shippable **v1.0** of Cadence. This file
records *the shape of the release and the order of work*; it complements
`STATUS.md` (where things stand right now) and `CHANGELOG.md` (what has shipped).

Each slice below is a heading, not a spec. When work on one begins it gets its
own brainstorm → design → TDD build cycle per `CLAUDE.md` §7–§8. This document
is the map; the slices are the territory.

**Last updated:** 2026-08-24

---

## The v1.0 goal

A blood-pressure **diary** (not a device — `CLAUDE.md` §1) that a person can use
to: record a measurement occasion the way the home-monitoring protocol expects,
read back what they logged and its simple arithmetic, see how well they are
keeping to the protocol, and get the data out — to a doctor (CSV) and to a
restorable backup (JSON). Offline-only, no accounts, no telemetry (`CLAUDE.md`
§2).

Shipped in **English and Italian**. Given the older audience (below), Italian is
likely the *primary* language its real users read, not a second-class add-on.

This is a *fuller* v1.0 than the leanest possible one: 7-2-2 coverage, the
reading context fields, and Italian localisation were deliberately pulled in,
trading a later launch for a more complete first release.

---

## Cross-cutting principle: ease of use for an older audience

The likely user is older than the developer — less-steady hands, older eyes,
less tolerance for fiddly UI. **Ease of use is a first-class requirement, not
polish applied at the end.** Every product slice is judged against it:

- Large, legible default type; respect and test large system font scales.
- High contrast; no information carried by colour alone.
- Generous tap targets (comfortably above the Material 48dp minimum).
- The fewest steps that do the job; sensible prefilled defaults over blank
  fields.
- Forgiving and reversible: mistakes are easy to fix (S5), destructive actions
  confirm (`CLAUDE.md` §6).
- Plain wording in UI copy; no jargon, no abbreviations.

This principle is *why* S3 (fast entry) is a headline slice rather than a
nicety, and it sets the bar for S5 and S9.

---

## Product track — slices in build order

Dependencies run top-to-bottom: earlier slices unblock later ones.

### Phase 1 — finish the data and the entry experience

These three all touch the entry form and/or the schema, so they form one
cluster and are best built in sequence.

- **S1 · Context fields → schema v2.** Add the optional context `Reading` has
  always promised but never modelled (`CLAUDE.md` §4): arm, posture, and
  before/after medication. Requires a schema-version bump with an explicit
  migration, a committed `drift_dev schema dump` snapshot, and passing migration
  tests (`CLAUDE.md` §5). *Done now, before any real user data exists, this is
  cheap; done after launch it is a migration over live data.*
- **S2 · Multiple readings per session.** The entry flow records exactly one
  reading today; the schema already holds many. Let an occasion carry the
  protocol's two-per-occasion (and more), so the UI stops breaking a promise the
  data model makes.
- **S3 · Fast entry.** Big systolic/diastolic (and pulse) values with −/+
  steppers either side, prefilled with a sensible default. Open question for the
  slice's own design: default to the *last reading* (BP numbers cluster, so the
  last value is the closest guess) rather than an all-time average. This slice
  carries the ease-of-use principle above.

### Phase 2 — compute and read back

- **S4 · Session detail + session average.** A screen showing one session's
  readings and the mean of them (`CLAUDE.md` §4). The simplest real arithmetic
  the app owes.
- **S5 · Edit / delete.** Correct a mistyped reading; remove a session. A diary
  with no fix path is both frustrating and quietly data-unsafe. Destructive
  actions confirm and are reversible where possible (`CLAUDE.md` §6).
- **S6 · 7-2-2 coverage.** Readings collected vs expected (e.g. 9/14 this week),
  with under-sampled averages labelled as such (`CLAUDE.md` §4). The heaviest
  domain slice and the app's differentiator. **See the flagged dependency
  below** — this may pull a monitoring-period average, the discard-day-1
  setting, and a Settings screen above the line with it.

### Phase 3 — get the data out

- **S7 · JSON backup export + import.** The only restorable backup format
  (`CLAUDE.md` §2, §5): versioned, tolerant of unknown fields, never silently
  dropping data. Goes through the Android share sheet / SAF.
- **S8 · CSV + PDF export.** Export-only, for handing a doctor the numbers. The
  killer use of a BP diary. (PDF was pulled forward from 1.x into this slice.)
  Both export the **whole** diary for now; a date-range option is deferred —
  see below.

### Phase 4 — pre-flight

- **S9 · First-run disclaimer + empty/error polish.** "A diary, not a device —
  consult your physician" (`CLAUDE.md` §1). Empty states, error states, and the
  ease-of-use pass across the app. Also the human-facing half of the Play
  health-apps story (B5).
- **S10 · Italian localisation.** Add `app_it.arb` with the full translated
  string set and wire `it` into the supported locales (English stays the source
  locale — `CLAUDE.md` §9). Done here, once the v1.0 string set is stable, so
  strings are translated once rather than re-translated as they churn. Budget
  real effort for wording quality: the copy is read by older users and brushes a
  medical context, so it must be plain and correct Italian, not a machine gloss.
  *Working rule from now on:* new user-facing strings are still authored in
  English source first; this slice is where the accumulated set gets its Italian.

---

## Release track — parallel, mechanical

Independent of the product slices; can proceed alongside them. All are required
to ship.

- **B1 · Release signing keystore.** Generate a real upload key; keep it out of
  git; document the process. Release currently signs with debug keys (a `TODO`
  in `android/app/build.gradle.kts`).
- **B2 · App icon + name.** *Done (2026-08-25).* `android:label="Cadence"` and a
  custom launcher icon generated via `flutter_launcher_icons`; both are in the
  signed build.
- **B3 · `targetSdk` / manifest audit.** Confirm `targetSdk` meets Play's
  current minimum; review the manifest. (`allowBackup="false"` is already
  correctly set — `CLAUDE.md` §5.)
- **B4 · Privacy policy.** A public URL is required even for a zero-data app.
- **B5 · Play Console paperwork.** Data Safety form (declare *nothing collected
  or shared* — a strong story for a local-only app), content-rating
  questionnaire, health-apps declaration.
- **B6 · Store listing.** Title, short and full description, screenshots,
  feature graphic.
- **B7 · Release build + rollout.** Build an `.aab`, run it through an internal
  test track → closed → production; stamp version `1.0.0`.

---

## Deferred to 1.x (explicitly out of v1.0)

- **Reference-range display** (e.g. average against the 135/85 home threshold).
  Permitted by `CLAUDE.md` §4 *only* when attributed to ESH/AHA and paired with
  a "consult your physician" pointer, and interpretive features are a maintainer
  decision (`CLAUDE.md` §1, §10). Off the v1.0 line by default; if it goes in, it
  is designed with the maintainer signing off on the exact wording.
- **PDF export** — *done*, pulled forward into S8.
- **Date-bounded exports (CSV/PDF).** S8 exports the whole diary; a from–to range
  (or a "last N days" / "this monitoring period" shortcut) would make the numbers
  handed to a doctor far more meaningful — a visit usually concerns a recent
  window, not years. The backup stays a **complete** snapshot (it must, §5); only
  the human-facing CSV/PDF gain the range. Design note: `buildReadingRows`
  already takes the session list, so filtering is a pure pre-step; the open
  question is the picker UX for the older audience (a plain from–to vs named
  shortcuts). Surfaced 2026-08-25 by the maintainer while shipping S8.
- **Bolder PDF export headers.** The PDF embeds the bundled Hanken *variable*
  font; `pdf` (dart_pdf) cannot select the weight axis, so the header row renders
  at body weight. Making it visibly bolder needs a real bold instance — either
  a static Hanken-Bold TTF bundled as a PDF-only asset (consistent typeface,
  ~+130 KB), or falling back to the built-in Helvetica-Bold for the header cells
  only (zero asset, but a second typeface and Latin-only). Minor polish, deferred
  2026-08-25 at the maintainer's call.
- **Trends / charts** over time.
- **Discard-day-1 toggle** and a Settings screen — unless S6 pulls them in.
- **Time-format preference (12-hour vs 24-hour).** Times currently follow the
  locale (English shows AM/PM, Italian shows 24-hour) via `DateFormat.jm`. An
  explicit user override belongs on the same Settings screen as the
  discard-day-1 toggle. Surfaced 2026-08-24 while testing the expanded
  reading-time display.
- **Locales beyond English and Italian** (the ARB i18n infrastructure supports
  them; v1.0 ships EN + IT — `CLAUDE.md` §9).

---

## Flagged dependencies and open questions

Resolved when the relevant slice is designed, not now:

- **S6 may widen.** Coverage lives on a *monitoring period*, and `CLAUDE.md` §4
  puts the 135/85 threshold and the *period* average — the things the optional,
  user-configurable "discard day 1" choice bites — at that same level. So S6 may
  drag a period-average concept, the discard-day-1 setting, and a minimal
  Settings screen above the line. How much of the "period" concept v1.0 needs is
  a domain-modelling decision for the maintainer (`CLAUDE.md` §10).
- **S3 prefill default** — last reading vs average — to be confirmed at design
  time.
