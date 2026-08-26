import 'package:cadence/domain/sessions/ids.dart';
import 'package:cadence/domain/sessions/reading.dart';
import 'package:cadence/domain/sessions/session.dart';
import 'package:cadence/domain/sessions/sessions_in_last_days.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps every generated id distinct; identity does not matter here.
int _seq = 0;

Session occasion({required DateTime takenAt}) => Session(
  id: SessionId('s${_seq++}'),
  readings: [
    Reading(
      id: ReadingId('r${_seq++}'),
      systolic: 120,
      diastolic: 80,
      takenAt: takenAt,
    ),
  ],
);

void main() {
  // Treat the stored UTC instant as local, so the window is computed from these
  // exact wall-clock dates regardless of the machine's timezone (same trick as
  // the weekly-coverage tests).
  final nowUtc = DateTime.utc(2026, 8, 24, 8);
  DateTime identity(DateTime utc) => utc;

  List<Session> lastDays(List<Session> history, int days) =>
      sessionsInLastDays(history, days: days, now: nowUtc, toLocal: identity);

  Session daysAgo(int days) =>
      occasion(takenAt: nowUtc.subtract(Duration(days: days)));

  group('sessionsInLastDays', () {
    test('is empty with no history', () {
      expect(lastDays(const [], 7), isEmpty);
    });

    test('keeps an occasion from today', () {
      final today = occasion(takenAt: nowUtc);
      expect(lastDays([today], 7), [today]);
    });

    test('keeps an occasion on the first day of the window (days-1 back)', () {
      // "Last 7 days" is today and the six days before it, so six days back is
      // the earliest day still inside the window (same meaning as weeklyCoverage).
      expect(lastDays([daysAgo(6)], 7), hasLength(1));
    });

    test('drops an occasion the day before the window (days back)', () {
      expect(lastDays([daysAgo(7)], 7), isEmpty);
    });

    test('keeps only the in-window occasions', () {
      final within = daysAgo(2);
      final history = [within, daysAgo(8), daysAgo(40)];
      expect(lastDays(history, 7), [within]);
    });

    test('a wider window keeps what a narrow one drops', () {
      final history = [daysAgo(2), daysAgo(20), daysAgo(80)];
      expect(lastDays(history, 7), hasLength(1));
      expect(lastDays(history, 30), hasLength(2));
      expect(lastDays(history, 90), hasLength(3));
    });

    test('groups by local calendar day, not UTC', () {
      // 3 days back at 23:00 UTC; a +2h local shift moves it to the next local
      // day, pulling it from outside a 3-day window to inside it.
      final late = occasion(
        takenAt: nowUtc
            .subtract(const Duration(days: 3))
            .add(
              const Duration(
                hours: 15,
              ), // 08:00 - 3d + 15h = 23:00 three days back
            ),
      );
      DateTime plusTwo(DateTime utc) => utc.add(const Duration(hours: 2));
      expect(
        sessionsInLastDays([late], days: 3, now: nowUtc, toLocal: identity),
        isEmpty,
      );
      expect(
        sessionsInLastDays([late], days: 3, now: nowUtc, toLocal: plusTwo),
        hasLength(1),
      );
    });

    test('excludes a future-dated occasion (CQ-04 upper bound)', () {
      // A tomorrow-dated session (possible via the tolerant import) must not be
      // handed to a clinician under "last 30 days" — the window ends today.
      final future = occasion(takenAt: nowUtc.add(const Duration(days: 1)));
      expect(lastDays([future], 30), isEmpty);
    });

    test('rejects a non-positive window length', () {
      expect(() => lastDays(const [], 0), throwsArgumentError);
    });
  });
}
