import 'package:cadence/domain/sessions/date_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tests are timezone-independent: instants are already the "local" time, and
  // toLocal is the identity. What matters is the calendar-date arithmetic.
  DateTime identity(DateTime d) => d;

  // A window of `days` dates ending on 2026-08-26.
  DateWindow windowOf(int days) =>
      DateWindow.lastDays(days, DateTime(2026, 8, 26, 15), identity);

  group('lastDays', () {
    test('includes today and the day (days - 1) before the start', () {
      final window = windowOf(7); // Aug 20..26

      expect(window.contains(DateTime(2026, 8, 26, 23), identity), isTrue);
      expect(window.contains(DateTime(2026, 8, 20), identity), isTrue);
      expect(window.contains(DateTime(2026, 8, 19, 23), identity), isFalse);
    });

    test('excludes a future-dated instant', () {
      // The bug CQ-04 fixes: without an upper bound a tomorrow-dated session
      // (possible via the tolerant import) fell inside the window.
      final window = windowOf(7);

      expect(window.contains(DateTime(2026, 8, 27), identity), isFalse);
    });

    test('a one-day window is just today', () {
      final window = windowOf(1);

      expect(window.contains(DateTime(2026, 8, 26), identity), isTrue);
      expect(window.contains(DateTime(2026, 8, 25, 23), identity), isFalse);
      expect(window.contains(DateTime(2026, 8, 27), identity), isFalse);
    });

    test('rejects a non-positive window length', () {
      expect(
        () => DateWindow.lastDays(0, DateTime(2026, 8, 26), identity),
        throwsArgumentError,
      );
      expect(
        () => DateWindow.lastDays(-3, DateTime(2026, 8, 26), identity),
        throwsArgumentError,
      );
    });

    test('crossing a spring-forward DST boundary keeps the window N dates wide', () {
      // Italy springs forward on 2026-03-29. Counting by date parts (not a
      // 24h × N duration) means the window is still exactly 7 dates even though
      // one of those days is 23 hours long.
      final window = DateWindow.lastDays(
        7,
        DateTime(2026, 3, 31, 12),
        identity,
      );

      expect(window.contains(DateTime(2026, 3, 25), identity), isTrue); // start
      expect(window.contains(DateTime(2026, 3, 24, 23), identity), isFalse);
      expect(
        window.contains(DateTime(2026, 3, 31, 23), identity),
        isTrue,
      ); // end
      expect(window.contains(DateTime(2026, 4, 1), identity), isFalse);
    });
  });

  group('upToToday', () {
    test('includes any past date up to today but not the future', () {
      final window = DateWindow.upToToday(DateTime(2026, 8, 26, 9), identity);

      expect(window.contains(DateTime(2020, 1, 1), identity), isTrue);
      expect(window.contains(DateTime(2026, 8, 26, 23), identity), isTrue);
      expect(window.contains(DateTime(2026, 8, 27), identity), isFalse);
    });
  });
}
