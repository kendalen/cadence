# Multiple readings per session (+ reading context) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the entry flow build up an occasion of one or more readings and save them as a single `Session`, and capture the optional arm / posture / medication context on each reading.

**Architecture:** The data layer already stores multi-reading sessions atomically (`SessionRepository.add(Session)`), so this slice is a UI + Cubit-state rework plus one additive domain change (`ReadingInput` carries context). Readings are assembled in the Cubit as validated `Reading` objects (a "banked" list) and written in one `add`. No schema change, no migration.

**Tech Stack:** Flutter, `flutter_bloc` (Cubits), Drift (unchanged here), `equatable`, ARB localisation (English source), `intl` for date formatting.

**Spec:** `docs/superpowers/specs/2026-08-24-multiple-readings-per-session-design.md`

## Global Constraints

Copied from the spec / CLAUDE.md; every task implicitly includes these.

- **Layers are one-way and lint-enforced:** `domain` is pure Dart (no Flutter/Drift/IO); `data` depends on `domain`; `ui` depends on both. Never cross a boundary.
- **TDD:** domain is test-first, no exceptions; Cubit logic is tested by driving methods and asserting emitted states; UI is covered by the integration ("smoke") test only — no `Column`-structure widget tests (§7).
- **No hardcoded user-facing strings.** Every visible string is authored in `lib/l10n/app_en.arb` (English source) and read through `AppLocalizations`. Italian is S10, not now.
- **No second way to do an existing thing.** Reuse the `validation_messages.dart` pattern for mapping a domain value to a localised string; reuse existing ARB keys (`readingPressure`, etc.).
- **Never silence a lint** (`// ignore:`, downgrades). If a rule blocks you, stop and ask.
- **File-size smell:** flag/​split files over ~300 lines, classes over ~200 (§6). `session_entry_screen.dart` is near this — extract private widgets as directed.
- **Definition of done per commit:** `lefthook run pre-commit` green (`dart format --set-exit-if-changed`, `flutter analyze --fatal-infos --fatal-warnings`, `dart analyze` boundaries, `flutter test`). Update `CHANGELOG.md` and `docs/STATUS.md` at the end of each part (S2a, S2b).
- **Regenerating l10n:** after editing `app_en.arb`, run `flutter gen-l10n`. The output (`lib/l10n/app_localizations*.dart`) is **gitignored** — do not commit it; it regenerates on build.
- **Commits:** work on branch `s2-multiple-readings` (already created; the design doc is its first commit). Prefix messages `S2a:` (Tasks 1–4) or `S2b:` (Tasks 5–7). End every commit message with:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`

---

# Part S2a — multiple readings

## Task 1: Bank a reading in the Cubit

Carry a list of already-validated readings in the entry state, and add a method that validates the current form and appends its reading, resetting the moment for the next one.

**Files:**
- Modify: `lib/ui/sessions/entry/session_entry_state.dart`
- Modify: `lib/ui/sessions/entry/session_entry_cubit.dart`
- Test: `test/ui/sessions/session_entry_cubit_test.dart`

**Interfaces:**
- Consumes: `ReadingInput.validate(IdGenerator, {required DateTime now}) -> Result<Reading, List<ValidationFailure>>` (unchanged); `Reading` (has `id`, `systolic`, `diastolic`, `takenAt` UTC).
- Produces:
  - `SessionEntryState.bankedReadings : List<Reading>` (on the base, defaults `const []`).
  - `SessionEntryCubit.addReading({required String systolic, required String diastolic, required String pulse, required String notes}) -> void`.
  - Reset rule: after a successful add, the form's `takenAt` becomes `previous + 1 minute`, but never after `now` (so the prefilled time is never already-invalid; a refinement of the spec's "+1 minute").

- [ ] **Step 1: Write the failing tests**

Add to `test/ui/sessions/session_entry_cubit_test.dart` (inside `main()`):

```dart
test('adds a valid reading to the banked list and clears the form of errors',
    () async {
  final earlier = now.subtract(const Duration(hours: 2));
  cubit.takenAtChanged(earlier);

  cubit.addReading(systolic: '120', diastolic: '80', pulse: '70', notes: '');

  final state = cubit.state as SessionEntryEditing;
  expect(state.bankedReadings, hasLength(1));
  expect(state.bankedReadings.single.systolic, 120);
  expect(state.failures, isEmpty);
});

test('resets the moment to one minute after the reading just banked', () async {
  final earlier = now.subtract(const Duration(hours: 2));
  cubit.takenAtChanged(earlier);

  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');

  expect(cubit.state.takenAt, earlier.add(const Duration(minutes: 1)));
});

test('never resets the moment past now', () async {
  // takenAt defaults to now; +1 minute would be in the future, so it clamps.
  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');

  expect(cubit.state.takenAt, now);
});

test('an invalid reading is not banked and its errors are shown', () async {
  cubit.addReading(systolic: '', diastolic: '400', pulse: '', notes: '');

  final state = cubit.state as SessionEntryEditing;
  expect(state.bankedReadings, isEmpty);
  expect(state.failures, isNotEmpty);
});

test('changing the moment keeps the banked readings', () async {
  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');
  final banked = cubit.state.bankedReadings;

  cubit.takenAtChanged(now.subtract(const Duration(hours: 1)));

  expect(cubit.state.bankedReadings, banked);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart --plain-name "banked"`
Expected: FAIL — `addReading` and `bankedReadings` do not exist yet.

- [ ] **Step 3: Add `bankedReadings` to the state**

In `lib/ui/sessions/entry/session_entry_state.dart`, put `bankedReadings` on the base and thread it through the subclasses. Import `Reading`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/sessions/reading.dart';
import '../../../domain/sessions/validation_failure.dart';

/// Where the entry form has got to.
///
/// [takenAt] and [bankedReadings] are on the base because every state carries
/// them: the chosen moment and the readings already banked for this occasion
/// both survive submitting, saving, and a failed save.
sealed class SessionEntryState extends Equatable {
  /// Base constructor recording the current form's moment and the readings
  /// already banked for this occasion.
  const SessionEntryState(this.takenAt, {this.bankedReadings = const []});

  /// The moment the user says the current reading was taken, in local time.
  final DateTime takenAt;

  /// The readings already banked for this occasion, oldest first. Empty until
  /// the user banks one with "add another reading".
  final List<Reading> bankedReadings;

  @override
  List<Object?> get props => [takenAt, bankedReadings];
}

/// The user is filling the form in.
final class SessionEntryEditing extends SessionEntryState {
  /// Shows the form, with [failures] marking any fields found invalid on the
  /// last attempt, and [bankedReadings] listing what is already banked.
  const SessionEntryEditing(
    super.takenAt, {
    super.bankedReadings,
    this.failures = const [],
  });

  /// Why the last attempt was rejected; empty before the first one.
  final List<ValidationFailure> failures;

  @override
  List<Object?> get props => [takenAt, bankedReadings, failures];
}

/// A valid occasion is being written.
final class SessionEntrySubmitting extends SessionEntryState {
  /// Marks the write as in flight, keeping the banked readings for display.
  const SessionEntrySubmitting(super.takenAt, {super.bankedReadings});
}

/// The occasion was stored; the screen closes on this.
final class SessionEntrySaved extends SessionEntryState {
  /// Marks the write as done.
  const SessionEntrySaved(super.takenAt);
}

/// The store refused the write.
///
/// Carries no detail: the underlying cause is for diagnosis, never for the
/// user (CLAUDE.md §6). Keeps the banked readings so the user can retry.
final class SessionEntrySaveFailed extends SessionEntryState {
  /// Marks the write as failed, leaving the banked readings in place.
  const SessionEntrySaveFailed(super.takenAt, {super.bankedReadings});
}
```

- [ ] **Step 4: Add `addReading` and update `takenAtChanged`**

In `lib/ui/sessions/entry/session_entry_cubit.dart`, update `takenAtChanged` to preserve the banked list, and add `addReading`. Update the class dartdoc to drop the "exactly one reading" claim.

```dart
  /// Records the moment picked in the date and time pickers, keeping any
  /// readings already banked and clearing failures shown for the old form.
  void takenAtChanged(DateTime takenAt) => emit(
    SessionEntryEditing(
      takenAt.toLocal(),
      bankedReadings: state.bankedReadings,
    ),
  );

  /// Validates the typed values and banks the reading for this occasion.
  ///
  /// On valid input the reading joins [SessionEntryState.bankedReadings], the
  /// form is cleared of errors, and the moment resets to one minute after the
  /// banked reading — but never past [now], so the prefilled time is never
  /// already in the future. On invalid input nothing is banked and the
  /// failures are reported so the form can mark the bad fields.
  void addReading({
    required String systolic,
    required String diastolic,
    required String pulse,
    required String notes,
  }) {
    final takenAt = state.takenAt;
    final input = ReadingInput(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      notes: notes,
      takenAt: takenAt,
    );

    final validated = input.validate(_idGenerator, now: _now());
    if (validated case Err<Reading, List<ValidationFailure>>(:final error)) {
      emit(
        SessionEntryEditing(
          takenAt,
          bankedReadings: state.bankedReadings,
          failures: error,
        ),
      );
      return;
    }

    final reading = (validated as Ok<Reading, List<ValidationFailure>>).value;
    final nextMoment = takenAt.add(const Duration(minutes: 1));
    final clockNow = _now();
    emit(
      SessionEntryEditing(
        nextMoment.isAfter(clockNow) ? clockNow : nextMoment,
        bankedReadings: [...state.bankedReadings, reading],
      ),
    );
  }
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart`
Expected: PASS (new tests plus the existing single-reading tests, unchanged).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/sessions/entry/session_entry_state.dart \
        lib/ui/sessions/entry/session_entry_cubit.dart \
        test/ui/sessions/session_entry_cubit_test.dart
git commit -m "$(cat <<'EOF'
S2a: bank readings in the entry cubit

Carry a banked-readings list on the entry state and add addReading, which
validates the current form and appends its reading, resetting the moment to
one minute later (clamped to now).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Remove a banked reading before saving

Let the user drop a reading they banked by mistake, before the occasion is saved.

**Files:**
- Modify: `lib/ui/sessions/entry/session_entry_cubit.dart`
- Test: `test/ui/sessions/session_entry_cubit_test.dart`

**Interfaces:**
- Consumes: `ReadingId` (`import '../../../domain/sessions/ids.dart';` — check whether the cubit already imports it; it imports `ids.dart` for `SessionId`, so `ReadingId` is available).
- Produces: `SessionEntryCubit.removeBankedReading(ReadingId id) -> void`.

- [ ] **Step 1: Write the failing test**

```dart
test('removes a banked reading by id, leaving the rest', () async {
  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');
  cubit.addReading(systolic: '118', diastolic: '79', pulse: '', notes: '');
  final first = cubit.state.bankedReadings.first;

  cubit.removeBankedReading(first.id);

  final remaining = cubit.state.bankedReadings;
  expect(remaining, hasLength(1));
  expect(remaining.single.systolic, 118);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart --plain-name "removes a banked reading"`
Expected: FAIL — `removeBankedReading` not defined.

- [ ] **Step 3: Add `removeBankedReading`**

In `session_entry_cubit.dart`:

```dart
  /// Drops the banked reading with [id] from this occasion.
  ///
  /// Used to correct a reading banked by mistake before the occasion is saved;
  /// editing or deleting an already-stored reading is a separate concern.
  void removeBankedReading(ReadingId id) => emit(
    SessionEntryEditing(
      state.takenAt,
      bankedReadings: state.bankedReadings
          .where((reading) => reading.id != id)
          .toList(),
    ),
  );
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart --plain-name "removes a banked reading"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/sessions/entry/session_entry_cubit.dart \
        test/ui/sessions/session_entry_cubit_test.dart
git commit -m "$(cat <<'EOF'
S2a: remove a banked reading before saving

Add removeBankedReading so a reading banked by mistake can be dropped from the
occasion before it is written.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Save the whole occasion (banked + current form)

Rework `save` to write the banked readings plus the in-progress form reading, if one has been started, as a single `Session`.

**Files:**
- Modify: `lib/ui/sessions/entry/session_entry_cubit.dart`
- Test: `test/ui/sessions/session_entry_cubit_test.dart`

**Interfaces:**
- Consumes: `SessionRepository.add(Session)`, `Session(id:, readings:)` (readings non-empty), `SessionId`.
- Produces: unchanged `save({required String systolic, required String diastolic, required String pulse, required String notes})` signature, new behaviour:
  - "started" iff `systolic` or `diastolic` is non-blank.
  - started + valid → write `bankedReadings + [current]`.
  - started + invalid → emit `Editing` with failures, write nothing.
  - not started + banked non-empty → write `bankedReadings`.
  - not started + banked empty → emit `Editing` with the empty-form "value missing" failures (nothing to save).
  - a refused write emits `SessionEntrySaveFailed` keeping `bankedReadings`.

- [ ] **Step 1: Write the failing tests**

```dart
test('saves the banked readings and the current form as one session',
    () async {
  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');

  // The current form holds a second, not-yet-banked reading.
  await cubit.save(systolic: '118', diastolic: '79', pulse: '', notes: '');

  final session = repository.added.single;
  expect(session.readings, hasLength(2));
  expect(session.readings.map((r) => r.systolic), containsAll([120, 118]));
});

test('saves the banked readings alone when the form is empty', () async {
  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');
  cubit.addReading(systolic: '118', diastolic: '79', pulse: '', notes: '');

  await cubit.save(systolic: '', diastolic: '', pulse: '', notes: '');

  expect(repository.added.single.readings, hasLength(2));
});

test('rejects a started-but-invalid form even when readings are banked',
    () async {
  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');

  await cubit.save(systolic: '400', diastolic: '', pulse: '', notes: '');

  expect(repository.added, isEmpty);
  expect((cubit.state as SessionEntryEditing).failures, isNotEmpty);
  expect(cubit.state.bankedReadings, hasLength(1));
});

test('refuses to save an empty occasion', () async {
  await cubit.save(systolic: '', diastolic: '', pulse: '', notes: '');

  expect(repository.added, isEmpty);
  expect((cubit.state as SessionEntryEditing).failures, isNotEmpty);
});

test('a refused write keeps the banked readings', () async {
  repository.refuseWith = const WriteFailed('disk full');
  cubit.addReading(systolic: '120', diastolic: '80', pulse: '', notes: '');

  await cubit.save(systolic: '118', diastolic: '79', pulse: '', notes: '');

  expect(cubit.state, isA<SessionEntrySaveFailed>());
  expect(cubit.state.bankedReadings, hasLength(1));
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart --plain-name "saves the banked"`
Expected: FAIL — current `save` ignores banked readings and never combines them.

- [ ] **Step 3: Rewrite `save`**

Replace the body of `save` in `session_entry_cubit.dart`:

```dart
  /// Validates and writes the occasion: the banked readings plus the reading
  /// currently in the form, if one has been started.
  ///
  /// The form is "started" when a systolic or diastolic has been typed; a
  /// started form is validated and included, so logging a single reading stays
  /// one action (fill, save). Emits [SessionEntryEditing] with failures if a
  /// started form is invalid or there is nothing to save; [SessionEntrySaved]
  /// or [SessionEntrySaveFailed] once the write has been attempted. Does
  /// nothing while a write is already in flight.
  Future<void> save({
    required String systolic,
    required String diastolic,
    required String pulse,
    required String notes,
  }) async {
    if (state is SessionEntrySubmitting) {
      return;
    }

    final takenAt = state.takenAt;
    final banked = state.bankedReadings;
    final started = systolic.trim().isNotEmpty || diastolic.trim().isNotEmpty;

    final readings = [...banked];
    if (started || banked.isEmpty) {
      final input = ReadingInput(
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        notes: notes,
        takenAt: takenAt,
      );
      final validated = input.validate(_idGenerator, now: _now());
      if (validated case Err<Reading, List<ValidationFailure>>(:final error)) {
        emit(SessionEntryEditing(takenAt, bankedReadings: banked, failures: error));
        return;
      }
      readings.add((validated as Ok<Reading, List<ValidationFailure>>).value);
    }

    emit(SessionEntrySubmitting(takenAt, bankedReadings: banked));

    final session = Session(id: SessionId(_idGenerator.newId()), readings: readings);
    final stored = await _repository.add(session);

    emit(switch (stored) {
      Ok() => SessionEntrySaved(takenAt),
      Err() => SessionEntrySaveFailed(takenAt, bankedReadings: banked),
    });
  }
```

Note: `readings` is guaranteed non-empty when it reaches `Session(...)` — either `banked` is non-empty, or the `started || banked.isEmpty` branch appended a valid reading (and if `banked` is empty and the form is not started, the empty-form validation fails and returns before this point).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart`
Expected: PASS — new tests and the existing single-reading save tests.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/sessions/entry/session_entry_cubit.dart \
        test/ui/sessions/session_entry_cubit_test.dart
git commit -m "$(cat <<'EOF'
S2a: save an occasion of banked plus current readings

save now writes the banked readings plus the started form reading as one
Session; a single reading stays one action, an empty occasion is refused, and a
refused write keeps the banked readings.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Entry screen — "add another reading" and the banked list

Wire the new Cubit behaviour into the form: a button to bank the current reading, a list of banked readings each with a remove control, and clearing the input fields when a reading is banked. Prove the path end-to-end with a two-reading smoke test.

**Files:**
- Modify: `lib/ui/sessions/entry/session_entry_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `test/ui/log_session_smoke_test.dart`

**Interfaces:**
- Consumes: `cubit.addReading(...)`, `cubit.removeBankedReading(ReadingId)`, `state.bankedReadings`, `l10n.readingPressure(sys, dia)` (existing).
- Produces (ARB keys): `addAnotherReading`, `readingsSoFar`, `removeReading`.

- [ ] **Step 1: Add the ARB strings**

Add to `lib/l10n/app_en.arb` (before the closing `}`, with a comma after the previous entry):

```json
  "addAnotherReading": "Add another reading",
  "@addAnotherReading": {
    "description": "Button that banks the current reading and starts another one in the same occasion."
  },
  "readingsSoFar": "Readings so far",
  "@readingsSoFar": {
    "description": "Header above the list of readings already added to the occasion being entered."
  },
  "removeReading": "Remove",
  "@removeReading": {
    "description": "Tooltip of the button that removes a reading from the occasion before it is saved."
  }
```

- [ ] **Step 2: Regenerate localisations**

Run: `flutter gen-l10n`
Expected: no errors; `lib/l10n/app_localizations.dart` now has `addAnotherReading`, `readingsSoFar`, `removeReading` getters. (This file is gitignored — do not stage it.)

- [ ] **Step 3: Write the failing smoke test**

Add to `test/ui/log_session_smoke_test.dart`. First add a helper next to the existing `save` helper:

```dart
  Future<void> addAnother(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Add another reading'),
    );
    await settle(tester);
  }
```

Then the test:

```dart
  testWidgets('an occasion can hold two readings', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);

    await enter(tester, 'Systolic (mmHg)', '120');
    await enter(tester, 'Diastolic (mmHg)', '80');
    await addAnother(tester);

    await enter(tester, 'Systolic (mmHg)', '118');
    await enter(tester, 'Diastolic (mmHg)', '79');
    await save(tester);

    // One occasion in the list, holding two reading rows in storage.
    final sessions = await database.select(database.sessions).get();
    final readings = await database.select(database.readings).get();
    expect(sessions, hasLength(1));
    expect(readings, hasLength(2));

    await disposeApp(tester);
  });
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `flutter test test/ui/log_session_smoke_test.dart --plain-name "two readings"`
Expected: FAIL — there is no "Add another reading" button yet.

- [ ] **Step 5: Update the screen**

In `lib/ui/sessions/entry/session_entry_screen.dart`:

(a) Add an `_addReading` method beside `_save`, and make the listener clear the input fields when the banked list grows. Add a field `int _bankedCount = 0;` to `_SessionEntryFormState`, and in `_onStateChanged` handle the growth:

```dart
  void _onStateChanged(BuildContext context, SessionEntryState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.bankedReadings.length > _bankedCount) {
      _clearInputs();
    }
    _bankedCount = state.bankedReadings.length;

    switch (state) {
      case SessionEntrySaved():
        Navigator.of(context).pop();
      case SessionEntrySaveFailed():
        // The typed values stay in place, so the user can simply try again.
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
      case SessionEntryEditing():
      case SessionEntrySubmitting():
        break;
    }
  }

  void _clearInputs() {
    _systolic.clear();
    _diastolic.clear();
    _pulse.clear();
    _notes.clear();
  }

  void _addReading() => context.read<SessionEntryCubit>().addReading(
    systolic: _systolic.text,
    diastolic: _diastolic.text,
    pulse: _pulse.text,
    notes: _notes.text,
  );
```

(b) In `build`, after the `_TakenAtField` and before the `FilledButton`, add the "add another reading" button and the banked list. Replace the trailing `const SizedBox(height: 24)` + `FilledButton` block with:

```dart
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: submitting ? null : _addReading,
                icon: const Icon(Icons.add),
                label: Text(l10n.addAnotherReading),
              ),
              _BankedReadings(
                readings: state.bankedReadings,
                onRemove: (id) =>
                    context.read<SessionEntryCubit>().removeBankedReading(id),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submitting ? null : _save,
                child: Text(l10n.saveReading),
              ),
```

(c) Add the `_BankedReadings` widget at the bottom of the file (keeps the form method small — §6):

```dart
/// The readings already banked for this occasion, each removable.
class _BankedReadings extends StatelessWidget {
  const _BankedReadings({required this.readings, required this.onRemove});

  final List<Reading> readings;
  final void Function(ReadingId id) onRemove;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.jm(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.readingsSoFar, style: Theme.of(context).textTheme.titleSmall),
        for (final reading in readings)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.readingPressure(reading.systolic, reading.diastolic),
            ),
            subtitle: Text(time.format(reading.takenAt.toLocal())),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.removeReading,
              onPressed: () => onRemove(reading.id),
            ),
          ),
      ],
    );
  }
}
```

(d) Add the imports the new widget needs at the top of the file:

```dart
import '../../../domain/sessions/ids.dart';
import '../../../domain/sessions/reading.dart';
```

- [ ] **Step 6: Run the smoke test to verify it passes**

Run: `flutter test test/ui/log_session_smoke_test.dart`
Expected: PASS — the new two-reading test and the three existing ones.

- [ ] **Step 7: Update CHANGELOG and STATUS, run the full gate, commit**

Add to `CHANGELOG.md` under `## [Unreleased] → ### Added`:

```markdown
- Multiple readings per occasion in the entry flow: bank a reading with "add
  another reading", review and remove banked readings, and save the occasion as
  one multi-reading session (CLAUDE.md §4). Logging a single reading is
  unchanged — fill and save.
```

Update `docs/STATUS.md` "Current state → UI" line and "Next up" to reflect S2a landed (S2b/context pickers next). Then:

Run: `lefthook run pre-commit`
Expected: all four checks green.

```bash
git add lib/ui/sessions/entry/session_entry_screen.dart \
        lib/l10n/app_en.arb \
        test/ui/log_session_smoke_test.dart \
        CHANGELOG.md docs/STATUS.md
git commit -m "$(cat <<'EOF'
S2a: enter multiple readings per occasion

Add an "add another reading" button and a removable list of banked readings to
the entry form, clearing the inputs after each bank. A smoke test logs a
two-reading occasion end-to-end. Data layer already stored multi-reading
sessions; this is the UI catching up.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

# Part S2b — reading context pickers

## Task 5: `ReadingInput` carries context (domain)

Give the form's input object the three optional context fields and pass them into the `Reading` it builds.

**Files:**
- Modify: `lib/domain/sessions/reading_input.dart`
- Test: `test/domain/sessions/reading_input_test.dart`

**Interfaces:**
- Consumes: `MeasurementSite`, `Posture`, `MedicationTiming` (`domain/sessions/reading_context.dart`); `Reading(... site:, posture:, medicationTiming:)` (already accepts them).
- Produces: `ReadingInput({..., MeasurementSite? site, Posture? posture, MedicationTiming? medicationTiming})`; `validate` passes them through.

- [ ] **Step 1: Write the failing tests**

Add to `test/domain/sessions/reading_input_test.dart`. Match the file's existing helper style (it constructs `ReadingInput` and calls `validate(FakeIdGenerator(), now: ...)`; reuse whatever local helpers already exist there). Import the context enums:

```dart
import 'package:cadence/domain/sessions/reading_context.dart';
```

Tests:

```dart
test('carries the context through to the built reading', () {
  final input = ReadingInput(
    systolic: '120',
    diastolic: '80',
    takenAt: DateTime(2026, 8, 23, 9),
    site: MeasurementSite.leftArm,
    posture: Posture.sitting,
    medicationTiming: MedicationTiming.before,
  );

  final result = input.validate(FakeIdGenerator(), now: DateTime(2026, 8, 23, 10));

  final reading = (result as Ok<Reading, List<ValidationFailure>>).value;
  expect(reading.site, MeasurementSite.leftArm);
  expect(reading.posture, Posture.sitting);
  expect(reading.medicationTiming, MedicationTiming.before);
});

test('leaves context null when none was chosen', () {
  final input = ReadingInput(
    systolic: '120',
    diastolic: '80',
    takenAt: DateTime(2026, 8, 23, 9),
  );

  final result = input.validate(FakeIdGenerator(), now: DateTime(2026, 8, 23, 10));

  final reading = (result as Ok<Reading, List<ValidationFailure>>).value;
  expect(reading.site, isNull);
  expect(reading.posture, isNull);
  expect(reading.medicationTiming, isNull);
});
```

(If the test file does not already import `Reading` / `Ok` / `ValidationFailure`, add those imports.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain/sessions/reading_input_test.dart --plain-name "context"`
Expected: FAIL — `ReadingInput` has no `site`/`posture`/`medicationTiming`.

- [ ] **Step 3: Add the fields and pass them through**

In `lib/domain/sessions/reading_input.dart`:

Add the import:

```dart
import 'reading_context.dart';
```

Add the constructor parameters (after `notes`):

```dart
    this.pulse = '',
    this.notes = '',
    this.site,
    this.posture,
    this.medicationTiming,
  });
```

Add the fields (after `takenAt`), with dartdoc:

```dart
  /// Where the cuff was placed, or `null` when the user did not record it.
  final MeasurementSite? site;

  /// The body position the reading was taken in, or `null` when unrecorded.
  final Posture? posture;

  /// Whether the reading was before or after medication, or `null` when
  /// unrecorded.
  final MedicationTiming? medicationTiming;
```

In `validate`, pass them into the built `Reading` (in the `Ok(Reading(...))` block):

```dart
        takenAt: takenAt.toUtc(),
        notes: trimmedNotes.isEmpty ? null : trimmedNotes,
        site: site,
        posture: posture,
        medicationTiming: medicationTiming,
      ),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/domain/sessions/reading_input_test.dart`
Expected: PASS — new tests and all existing validation tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/sessions/reading_input.dart \
        test/domain/sessions/reading_input_test.dart
git commit -m "$(cat <<'EOF'
S2b: ReadingInput carries optional context

The form input now accepts site, posture and medication timing and passes them
into the validated Reading; unset context stays null.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Cubit `addReading` / `save` carry context

Thread the three optional context values from the Cubit methods into `ReadingInput`.

**Files:**
- Modify: `lib/ui/sessions/entry/session_entry_cubit.dart`
- Test: `test/ui/sessions/session_entry_cubit_test.dart`

**Interfaces:**
- Consumes: `ReadingInput(... site:, posture:, medicationTiming:)` (from Task 5).
- Produces: optional named params `{MeasurementSite? site, Posture? posture, MedicationTiming? medicationTiming}` added to both `addReading` and `save`, defaulting to `null` (so Task 4's call sites keep compiling).

- [ ] **Step 1: Write the failing tests**

Add to `test/ui/sessions/session_entry_cubit_test.dart` (import `package:cadence/domain/sessions/reading_context.dart`):

```dart
test('a banked reading carries the chosen context', () async {
  cubit.addReading(
    systolic: '120',
    diastolic: '80',
    pulse: '',
    notes: '',
    site: MeasurementSite.rightArm,
    posture: Posture.sitting,
    medicationTiming: MedicationTiming.after,
  );

  final reading = cubit.state.bankedReadings.single;
  expect(reading.site, MeasurementSite.rightArm);
  expect(reading.posture, Posture.sitting);
  expect(reading.medicationTiming, MedicationTiming.after);
});

test('context on the current form flows into the saved session', () async {
  await cubit.save(
    systolic: '120',
    diastolic: '80',
    pulse: '',
    notes: '',
    site: MeasurementSite.leftWrist,
  );

  final reading = repository.added.single.readings.single;
  expect(reading.site, MeasurementSite.leftWrist);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart --plain-name "context"`
Expected: FAIL — the methods take no context params.

- [ ] **Step 3: Add the params and pass them into `ReadingInput`**

In `session_entry_cubit.dart`, add the import:

```dart
import '../../../domain/sessions/reading_context.dart';
```

Add the three optional params to `addReading` and `save` (same shape for both), e.g. for `addReading`:

```dart
  void addReading({
    required String systolic,
    required String diastolic,
    required String pulse,
    required String notes,
    MeasurementSite? site,
    Posture? posture,
    MedicationTiming? medicationTiming,
  }) {
```

and pass them into that method's `ReadingInput(...)`:

```dart
      notes: notes,
      takenAt: takenAt,
      site: site,
      posture: posture,
      medicationTiming: medicationTiming,
    );
```

Do the identical addition in `save` (params on the signature, forwarded into its `ReadingInput(...)`). Update both dartdocs to note context is carried through.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/ui/sessions/session_entry_cubit_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/sessions/entry/session_entry_cubit.dart \
        test/ui/sessions/session_entry_cubit_test.dart
git commit -m "$(cat <<'EOF'
S2b: entry cubit carries reading context

addReading and save take the optional site, posture and medication timing and
forward them into ReadingInput.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Entry screen — the collapsible context pickers

Add the optional "Add details" section with three dropdowns, wire them into the Cubit calls, reset them when a reading is banked, and prove the path with a context round-trip in the smoke test.

**Files:**
- Create: `lib/ui/sessions/reading_context_labels.dart`
- Modify: `lib/ui/sessions/entry/session_entry_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `test/ui/log_session_smoke_test.dart`

**Interfaces:**
- Consumes: `siteLabel/postureLabel/medicationTimingLabel(value, l10n)`; `cubit.addReading(... site:, posture:, medicationTiming:)`, `cubit.save(... site:, posture:, medicationTiming:)`.
- Produces (ARB keys): `contextDetails`, `contextNotRecorded`, `siteFieldLabel`, `siteLeftArm`, `siteRightArm`, `siteLeftWrist`, `siteRightWrist`, `postureFieldLabel`, `postureSitting`, `postureStanding`, `postureLying`, `medicationFieldLabel`, `medicationBefore`, `medicationAfter`.

- [ ] **Step 1: Add the ARB strings**

Add to `lib/l10n/app_en.arb` (comma after the previous entry):

```json
  "contextDetails": "Add details (optional)",
  "@contextDetails": {
    "description": "Title of the collapsible section holding the optional arm, body position and medication fields."
  },
  "contextNotRecorded": "Not recorded",
  "@contextNotRecorded": {
    "description": "Default option for each optional context dropdown, meaning the user did not record it."
  },
  "siteFieldLabel": "Where measured",
  "@siteFieldLabel": {
    "description": "Label of the dropdown choosing where the cuff was placed (arm or wrist)."
  },
  "siteLeftArm": "Left arm",
  "@siteLeftArm": { "description": "Cuff placed on the left upper arm." },
  "siteRightArm": "Right arm",
  "@siteRightArm": { "description": "Cuff placed on the right upper arm." },
  "siteLeftWrist": "Left wrist",
  "@siteLeftWrist": { "description": "Monitor placed on the left wrist." },
  "siteRightWrist": "Right wrist",
  "@siteRightWrist": { "description": "Monitor placed on the right wrist." },
  "postureFieldLabel": "Body position",
  "@postureFieldLabel": {
    "description": "Label of the dropdown choosing the body position the reading was taken in."
  },
  "postureSitting": "Sitting",
  "@postureSitting": { "description": "Reading taken while seated." },
  "postureStanding": "Standing",
  "@postureStanding": { "description": "Reading taken while standing." },
  "postureLying": "Lying down",
  "@postureLying": { "description": "Reading taken while lying down." },
  "medicationFieldLabel": "Medication",
  "@medicationFieldLabel": {
    "description": "Label of the dropdown choosing whether the reading was before or after medication."
  },
  "medicationBefore": "Before medication",
  "@medicationBefore": { "description": "Reading taken before taking medication." },
  "medicationAfter": "After medication",
  "@medicationAfter": { "description": "Reading taken after taking medication." }
```

Run: `flutter gen-l10n`
Expected: no errors; the new getters exist. (Gitignored — do not stage.)

- [ ] **Step 2: Create the labels helper**

Create `lib/ui/sessions/reading_context_labels.dart`:

```dart
import '../../domain/sessions/reading_context.dart';
import '../../l10n/app_localizations.dart';

/// Turns reading-context enum values into the labels shown for them.
///
/// Wording lives here rather than in the domain so the domain stays free of
/// presentation and every string comes from the ARB (CLAUDE.md §9). This mirrors
/// the `validation_messages.dart` pattern — the one way this app maps a domain
/// value to a localised string.

/// The label for a [MeasurementSite].
String siteLabel(MeasurementSite site, AppLocalizations l10n) => switch (site) {
  MeasurementSite.leftArm => l10n.siteLeftArm,
  MeasurementSite.rightArm => l10n.siteRightArm,
  MeasurementSite.leftWrist => l10n.siteLeftWrist,
  MeasurementSite.rightWrist => l10n.siteRightWrist,
};

/// The label for a [Posture].
String postureLabel(Posture posture, AppLocalizations l10n) => switch (posture) {
  Posture.sitting => l10n.postureSitting,
  Posture.standing => l10n.postureStanding,
  Posture.lying => l10n.postureLying,
};

/// The label for a [MedicationTiming].
String medicationTimingLabel(MedicationTiming timing, AppLocalizations l10n) =>
    switch (timing) {
      MedicationTiming.before => l10n.medicationBefore,
      MedicationTiming.after => l10n.medicationAfter,
    };
```

- [ ] **Step 3: Write the failing smoke test (context round-trip)**

Add to `test/ui/log_session_smoke_test.dart`. Selecting an item in a dropdown that shares "Not recorded" text with its siblings needs a stable handle, so the screen (Step 4) gives each dropdown a `Key`. Helper + test:

```dart
  Future<void> chooseSite(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const Key('siteDropdown')));
    await settle(tester);
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  testWidgets('a reading keeps the context chosen for it', (tester) async {
    await pumpApp(tester);
    await openEntryForm(tester);
    await enter(tester, 'Systolic (mmHg)', '120');
    await enter(tester, 'Diastolic (mmHg)', '80');

    await tester.tap(find.text('Add details (optional)'));
    await settle(tester);
    await chooseSite(tester, 'Left arm');
    await save(tester);

    final readings = await database.select(database.readings).get();
    expect(readings.single.site, 'leftArm');

    await disposeApp(tester);
  });
```

(`ReadingRow.site` is the stored enum name string — asserting `'leftArm'` proves the picker→cubit→domain→data path.)

- [ ] **Step 4: Run the test to verify it fails**

Run: `flutter test test/ui/log_session_smoke_test.dart --plain-name "context chosen"`
Expected: FAIL — no "Add details (optional)" section / no `siteDropdown` yet.

- [ ] **Step 5: Add the pickers to the screen**

In `lib/ui/sessions/entry/session_entry_screen.dart`:

(a) Imports:

```dart
import '../../../domain/sessions/reading_context.dart';
import '../reading_context_labels.dart';
```

(b) In `_SessionEntryFormState`, add selection fields and reset them alongside the text controllers:

```dart
  MeasurementSite? _site;
  Posture? _posture;
  MedicationTiming? _medicationTiming;
```

Extend `_clearInputs` (from Task 4) to also reset the dropdowns, wrapped in `setState`:

```dart
  void _clearInputs() {
    _systolic.clear();
    _diastolic.clear();
    _pulse.clear();
    _notes.clear();
    setState(() {
      _site = null;
      _posture = null;
      _medicationTiming = null;
    });
  }
```

(c) Pass the selections into both Cubit calls — update `_addReading` and `_save`:

```dart
  void _addReading() => context.read<SessionEntryCubit>().addReading(
    systolic: _systolic.text,
    diastolic: _diastolic.text,
    pulse: _pulse.text,
    notes: _notes.text,
    site: _site,
    posture: _posture,
    medicationTiming: _medicationTiming,
  );

  void _save() => unawaited(
    context.read<SessionEntryCubit>().save(
      systolic: _systolic.text,
      diastolic: _diastolic.text,
      pulse: _pulse.text,
      notes: _notes.text,
      site: _site,
      posture: _posture,
      medicationTiming: _medicationTiming,
    ),
  );
```

(d) In `build`, insert the collapsible details section after the `_notes` `TextField` and before the `_TakenAtField`:

```dart
              _ContextDetails(
                site: _site,
                posture: _posture,
                medicationTiming: _medicationTiming,
                onSite: (value) => setState(() => _site = value),
                onPosture: (value) => setState(() => _posture = value),
                onMedication: (value) =>
                    setState(() => _medicationTiming = value),
              ),
```

(e) Add the `_ContextDetails` widget at the bottom of the file:

```dart
/// The optional arm / body-position / medication fields, collapsed by default
/// so the fast path (just the numbers) stays uncluttered.
class _ContextDetails extends StatelessWidget {
  const _ContextDetails({
    required this.site,
    required this.posture,
    required this.medicationTiming,
    required this.onSite,
    required this.onPosture,
    required this.onMedication,
  });

  final MeasurementSite? site;
  final Posture? posture;
  final MedicationTiming? medicationTiming;
  final ValueChanged<MeasurementSite?> onSite;
  final ValueChanged<Posture?> onPosture;
  final ValueChanged<MedicationTiming?> onMedication;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      title: Text(l10n.contextDetails),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        _dropdown<MeasurementSite>(
          key: const Key('siteDropdown'),
          label: l10n.siteFieldLabel,
          value: site,
          values: MeasurementSite.values,
          labelOf: (value) => siteLabel(value, l10n),
          notRecorded: l10n.contextNotRecorded,
          onChanged: onSite,
        ),
        const SizedBox(height: 8),
        _dropdown<Posture>(
          key: const Key('postureDropdown'),
          label: l10n.postureFieldLabel,
          value: posture,
          values: Posture.values,
          labelOf: (value) => postureLabel(value, l10n),
          notRecorded: l10n.contextNotRecorded,
          onChanged: onPosture,
        ),
        const SizedBox(height: 8),
        _dropdown<MedicationTiming>(
          key: const Key('medicationDropdown'),
          label: l10n.medicationFieldLabel,
          value: medicationTiming,
          values: MedicationTiming.values,
          labelOf: (value) => medicationTimingLabel(value, l10n),
          notRecorded: l10n.contextNotRecorded,
          onChanged: onMedication,
        ),
      ],
    );
  }

  Widget _dropdown<T extends Enum>({
    required Key key,
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) labelOf,
    required String notRecorded,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T?>(
    key: key,
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<T?>(value: null, child: Text(notRecorded)),
      for (final option in values)
        DropdownMenuItem<T?>(value: option, child: Text(labelOf(option))),
    ],
    onChanged: onChanged,
  );
}
```

> Note on the SDK: `DropdownButtonFormField` binds its current selection with `initialValue` on recent Flutter and `value` on older SDKs. If `flutter analyze --fatal-infos` flags `initialValue` as undefined, rename that one line to `value:`; if it flags `value` as deprecated, keep `initialValue`. Do not suppress the lint.

- [ ] **Step 6: Run the smoke test to verify it passes**

Run: `flutter test test/ui/log_session_smoke_test.dart`
Expected: PASS — the context round-trip plus all earlier smoke tests.

- [ ] **Step 7: Update CHANGELOG and STATUS, run the full gate, commit**

Add to `CHANGELOG.md` under `### Added`:

```markdown
- Optional context pickers in the entry form: per reading, choose where it was
  measured (arm/wrist), the body position, and before/after medication, in a
  collapsible "Add details" section defaulting to not-recorded (CLAUDE.md §4).
```

Update `docs/STATUS.md`: mark S2 done (both parts), note the entry form now
captures context, and set "Next up" to S3 (fast entry) per the roadmap.

Run: `lefthook run pre-commit`
Expected: all four checks green.

```bash
git add lib/ui/sessions/reading_context_labels.dart \
        lib/ui/sessions/entry/session_entry_screen.dart \
        lib/l10n/app_en.arb \
        test/ui/log_session_smoke_test.dart \
        CHANGELOG.md docs/STATUS.md
git commit -m "$(cat <<'EOF'
S2b: capture reading context in the entry form

Add a collapsible "Add details" section with arm, body-position and medication
dropdowns, wired into the occasion's readings and defaulting to not-recorded. A
smoke test proves a chosen context round-trips into storage.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
EOF
)"
```

---

## Self-review

**Spec coverage:**

- Entry rework / build-up flow → Tasks 1, 3, 4.
- One-reading case stays one action → preserved by the "started form" rule (Task 3) and the existing single-reading Cubit tests, which remain green.
- Pre-save removal → Task 2 (+ UI in Task 4).
- Optional context per reading → Tasks 5 (domain), 6 (cubit), 7 (UI), defaulting to not-recorded.
- `ReadingInput` carries context → Task 5.
- No schema change → confirmed; nothing under `lib/data/` is touched.
- List tolerates multi-reading → already true (`_SessionTile` uses `readings.first` + `occurredAt`); no change, no task needed.
- Strings via ARB, reuse the mapping pattern → Tasks 4 & 7; `reading_context_labels.dart` mirrors `validation_messages.dart`.
- Tests: domain TDD (Task 5), Cubit behaviour (Tasks 1–3, 6), smoke integration for multi-reading (Task 4) and context (Task 7).
- CHANGELOG + STATUS → Tasks 4 (S2a) and 7 (S2b).
- Slice split S2a/S2b → Tasks 1–4 then 5–7.

**Placeholder scan:** none — every step has concrete code or an exact command.

**Type consistency:** `bankedReadings` (`List<Reading>`) is defined in Task 1 and used unchanged in 2, 3, 4. `addReading`/`save` gain the same three optional params in Task 6 and are called with them in Task 7. `siteLabel`/`postureLabel`/`medicationTimingLabel` are defined in Task 7 Step 2 and used in Step 5. Dropdown keys `siteDropdown`/`postureDropdown`/`medicationDropdown` match between the screen (Task 7 Step 5) and the test (Step 3). Reading-context enum values (`leftArm`, etc.) match `reading_context.dart` and the stored-name assertion (`'leftArm'`).

**One deliberate refinement of the spec:** the "+1 minute" moment reset is clamped so it never lands after `now` (Task 1), so the prefilled time for the next reading is never already-invalid. Consistent with the spec's intent; called out here and to the maintainer.
