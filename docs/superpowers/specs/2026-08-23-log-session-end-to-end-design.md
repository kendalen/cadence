# Design — Log a blood pressure session end-to-end

- **Date:** 2026-08-23
- **Status:** Approved (pending spec review)
- **Slice:** First vertical slice. One screen to enter a session, persisted via
  Drift, visible in a flat list.

This design refers throughout to the constraints in `CLAUDE.md`; section numbers
(e.g. §4) point there. §4's domain model is treated as given.

---

## 1. Goal and scope

Prove the full write→persist→read loop for a blood pressure session: a user
opens an entry screen, types one reading, saves it, and sees it appear in a flat
list that survives app restarts.

**In scope**

- A single Drift-backed `Sessions`/`Readings` schema (v1) with migration
  tooling in place.
- Domain entities (`Session`, `Reading`), a validated `ReadingInput`, and a
  `SessionRepository` interface.
- Two screens (list + entry) driven by `flutter_bloc` Cubits.
- Localised strings (English ARB) and correct timezone handling.
- Tests: full TDD on domain, thorough data tests, golden tests on the two
  screens.

**Out of scope (do not build toward these)**

Charts, statistics (including session/period averages and the 135/85 threshold),
7-2-2 protocol logic, coverage reporting, export (CSV/PDF/JSON), reminders,
settings, editing, and deleting. Multi-reading sessions, and the
arm/posture/medication context fields, are deferred to later slices (see §10).

**Explicitly not painting into a corner**

- The schema is `Session`→`Readings` one-to-many from v1, so multi-reading entry
  is later an additive UI change, not a migration.
- IDs are client-generated and stable, so a future JSON backup/restore can
  reconcile identity.
- The migration harness ships in v1, so deferred columns arrive as safe, tested
  migrations.

---

## 2. Decisions (with rationale)

1. **Single reading per save.** The entry screen captures one reading, persisted
   as a session containing exactly that reading. Exercises the whole path with a
   trivial form; multi-reading entry is a later additive slice.
2. **Fields this slice:** `systolic` and `diastolic` required; `pulse` and
   `notes` optional; `takenAt` defaults to now and is editable. Pulse is optional
   because readings from older/manual instruments often omit it.
3. **Read-only list.** Newest-first; a FAB opens the entry screen. No
   edit/delete this slice — deletion is data-loss-adjacent and gets its own slice
   with confirm-and-undo (§6).
4. **State management: `flutter_bloc` (Cubits), app-wide (§3).** Constructor-
   injected dependencies, widget-tree-scoped `BlocProvider` — explicit DI, no
   service locator (§6). This is the single approach for the whole app; a second
   one is never introduced.
5. **IDs: UUID v7 strings**, generated behind an injected `IdGenerator`
   abstraction so `domain` stays pure and tests are deterministic. v7 is
   time-ordered (k-sortable): stable identity that survives export/import and
   restore-into-non-empty-DB, with good index locality. The `uuid` dependency
   lives only in `data`/composition.
6. **Defer arm/posture/medication.** Not added as columns in v1. Modelling their
   semantics (enum values, representation) is a domain decision out of this
   slice's scope; adding them later is a safe, tested migration given the v1
   migration machinery. Avoids speculative unused columns (§6 YAGNI).
7. **Timestamps stored as UTC ISO-8601 text** (`storeDateTimeAsText: true`,
   drift's current recommendation). Correct across timezones/DST; converted to
   local only for display.
8. **`Result`/`Either` hand-rolled** as a small Dart 3 sealed type in `domain`
   (§6). No `fpdart`/`dartz` dependency — more readable for a solo maintainer.

---

## 3. Architecture by layer

Dependencies flow one way and are lint-enforced (§3): `domain` is pure;
`data` depends on `domain`; `ui` depends on both.

### 3.1 Domain (`lib/domain/`, pure Dart)

```
SessionId, ReadingId        // typed identifiers (Dart 3 extension types over String)

Reading {                   // immutable, value-equal
  ReadingId id
  int systolic
  int diastolic
  int? pulse
  DateTime takenAt          // UTC
  String? notes
}

Session {                   // immutable, value-equal
  SessionId id
  List<Reading> readings    // non-empty; exactly one in this slice
  DateTime get occurredAt   // derived: earliest reading's takenAt (not stored)
}

ReadingInput {              // raw form values, no identity yet
  Result<Reading, ValidationFailure> validate(IdGenerator, {DateTime takenAt})
}

abstract SessionRepository {
  Future<Result<Unit, PersistenceFailure>> add(Session session);
  Stream<List<Session>> watchAll();      // newest occurredAt first
}

abstract IdGenerator { String newId(); } // impl (UUID v7) lives in data/composition

sealed Result<T, E> = Ok<T,E>(T value) | Err<T,E>(E error);
sealed ValidationFailure  // e.g. missingSystolic, systolicOutOfRange(min,max), ...
sealed PersistenceFailure // e.g. writeFailed(cause)
```

- **Derived values are computed, never stored** (§4): `occurredAt` is a getter.
  No pulse-pressure/MAP getters this slice (that is statistics — out of scope).
- Value equality via `equatable`.

### 3.2 Data (`lib/data/`)

- **Drift tables** in `app_database.dart` (+ generated `app_database.g.dart`):
  - `Sessions`: `id TEXT PK`.
  - `Readings`: `id TEXT PK`, `sessionId TEXT` → `Sessions.id`
    (`onDelete: cascade`), `systolic INT`, `diastolic INT`, `pulse INT?`,
    `takenAt TEXT` (UTC ISO-8601), `notes TEXT?`.
- `schemaVersion = 1`. `MigrationStrategy`:
  - `onCreate`: `m.createAll()`.
  - `beforeOpen`: under `kDebugMode`, run `validateDatabaseSchema()` (§5).
  - PRAGMA `foreign_keys = ON` in `beforeOpen`.
- **Connection** via `driftDatabase(name: 'cadence')` from `drift_flutter`,
  which stores the file in `getApplicationDocumentsDirectory()` (§5 — never a
  cache dir). WAL is drift's default; the export slice will add the
  `wal_checkpoint(TRUNCATE)` step (§5) — noted, not built now.
- **`DriftSessionRepository implements SessionRepository`**: maps rows↔domain in
  a dedicated `session_mappers.dart`. **No Drift-generated type appears in any
  signature outside `lib/data/`** (§3). `watchAll()` is backed by a drift
  `.watch()` query joining sessions to their readings, ordered by earliest
  `takenAt` descending.
- **`UuidIdGenerator implements IdGenerator`** wraps `Uuid().v7()`.

### 3.3 UI (`lib/ui/`, flutter_bloc)

- **`lib/main.dart` (new composition root):** builds `AppDatabase` once, wraps it
  in `DriftSessionRepository`, exposes the repository via `RepositoryProvider`,
  hosts `MaterialApp` with the l10n delegates; `home` is the list screen. The
  database is closed on app teardown.
- **List:** `SessionListCubit` subscribes to `repo.watchAll()` and emits
  `loading | empty | loaded(List<Session>)`. `SessionListScreen` renders the flat
  list — each row `142/91`, `· 72 bpm` when pulse present, and the local
  date-time — with a FAB opening the entry screen.
- **Entry:** `SessionEntryCubit` holds `editing(values, fieldErrors) |
  submitting | success | failure(message)`. On submit it validates via
  `ReadingInput.validate(...)`, wraps the `Reading` in a new single-reading
  `Session`, and calls `repo.add`. `SessionEntryScreen` is the form (systolic,
  diastolic, pulse, notes, and a date-time picker defaulting to now). On success
  it pops; the list updates through its stream.
- All user-facing text via the ARB (§9); dates formatted with `intl` in local
  time. Cubit dependencies constructor-injected via `BlocProvider` (§6).

---

## 4. Validation rules

Pure, in `ReadingInput.validate()`, TDD-first:

- `systolic`, `diastolic`: required; parse to `int`; **plausibility** bounds
  10–300 mmHg.
- `pulse`: optional; if present, parse to `int`; plausibility 20–300 bpm.
- `notes`: optional free text; trimmed; empty → `null`.
- `takenAt`: the date-time picker's `lastDate` is now, so a future time cannot be
  selected in the UI; `validate()` additionally rejects a future `takenAt`
  defensively. Default is now.

Bounds are **typo guards, not clinical thresholds** — commented as such. No
diagnostic colouring or labelling of any reading (§4). `systolic > diastolic` is
**not** enforced (real readings occasionally violate it; blocking would be
wrong).

---

## 5. Error handling

- Expected failures use `Result` (§6): validation errors surface per-field in the
  form; a persistence failure surfaces as a single user-facing message
  ("Couldn't save this reading. Please try again.") — never a raw exception
  string (§6). All messages are localised.
- Programming errors remain exceptions.

---

## 6. Persistence & §5 compliance checklist

- [x] DB in `getApplicationDocumentsDirectory()` (via `drift_flutter` default).
- [x] `validateDatabaseSchema()` in `beforeOpen` under debug.
- [x] `schemaVersion = 1`; `drift_dev schema dump` snapshot committed; migration-
      test harness in place so any future bump needs a passing test to merge.
- [ ] `android:allowBackup="false"` **and** Android 12+ backup opt-out
      (`android:dataExtractionRules` / `fullBackupContent` disabling backup) set
      in the manifest. The `flutter create` template leaves backup unset (i.e.
      enabled), so this slice must set it (§5).
- [ ] `wal_checkpoint(TRUNCATE)` before copy/export — deferred with the export
      slice; recorded here so it is not forgotten.

---

## 7. Dependencies (§9)

Runtime: `drift`, `drift_flutter`, `path_provider`, `flutter_bloc`, `equatable`,
`uuid`. Dev: `drift_dev`, `build_runner`. All MIT except `path_provider`
(BSD-3, flutter.dev). Necessity, licences, and maintenance were verified against
current pub.dev pages on 2026-08-23. `sqlite3_flutter_libs` is **not** used — it
is deprecated/EOL as of `sqlite3` 3.x; `drift_flutter` replaces it.

---

## 8. Testing (§7)

- **domain (full TDD):** `ReadingInput.validate()` across bounds and
  required/optional/error cases; `Session.occurredAt`; entity value equality;
  `Result` behaviour.
- **data (thorough):** row↔domain mapper round-trips; `DriftSessionRepository`
  against `NativeDatabase.memory()` (add → `watchAll` emits it; ordering;
  cascade); the v1 schema/migration harness.
- **ui (golden on key screens only):** list empty, list populated, entry form.
  No `Column`-structure assertions. Cubit logic tested directly by driving
  methods and asserting emitted states.

---

## 9. File layout

```
lib/
  main.dart
  domain/
    core/{result.dart, unit.dart}
    sessions/{ids.dart, reading.dart, session.dart, reading_input.dart,
              validation_failure.dart, persistence_failure.dart,
              session_repository.dart, id_generator.dart}
  data/
    database/{app_database.dart, app_database.g.dart, tables.dart}
    sessions/{drift_session_repository.dart, session_mappers.dart}
    ids/uuid_id_generator.dart
    schema/drift_schema_v1.json          # committed schema snapshot
  ui/
    app.dart
    sessions/
      list/{session_list_screen.dart, session_list_cubit.dart, session_list_state.dart}
      entry/{session_entry_screen.dart, session_entry_cubit.dart, session_entry_state.dart}
  l10n/app_en.arb
test/ mirrors the above; plus test/data/schema/ for the migration harness.
```

Files stay under the §6 size smells (~300 lines/file, ~200/class); split if they
grow.

---

## 10. Deferred to later slices

- Multi-reading sessions (entry UI only; schema already supports it).
- arm / posture / before-after-medication context (own slice, modelled properly,
  tested migration to v2).
- Edit and delete (with confirm + undo, §6).
- Statistics, coverage, 7-2-2 protocol, thresholds, export, reminders, settings.

---

## 11. Definition of done (§8)

- [ ] `lefthook run pre-commit` green (`dart format`, `flutter analyze`,
      `dart analyze` boundaries, `flutter test`).
- [ ] Domain and data code covered by tests; golden tests on the two screens.
- [ ] v1 schema snapshot committed and migration-test harness passing.
- [ ] No hardcoded user-facing strings; new keys in the ARB.
- [ ] Public APIs in `domain`/`data` documented (§6).
- [ ] No second way introduced for anything the repo already does.
- [ ] `CHANGELOG.md` updated.
