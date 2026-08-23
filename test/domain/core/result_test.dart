import 'package:cadence/domain/core/result.dart';
import 'package:cadence/domain/core/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('is matched exhaustively by a switch over its two variants', () {
      const Result<int, String> ok = Ok(1);
      const Result<int, String> err = Err('boom');

      String describe(Result<int, String> result) => switch (result) {
        Ok(:final value) => 'ok $value',
        Err(:final error) => 'err $error',
      };

      expect(describe(ok), 'ok 1');
      expect(describe(err), 'err boom');
    });

    test('compares by value, not identity', () {
      expect(const Ok<int, String>(1), const Ok<int, String>(1));
      expect(const Ok<int, String>(1), isNot(const Ok<int, String>(2)));
      expect(const Err<int, String>('a'), const Err<int, String>('a'));
      expect(const Ok<int, String>(1), isNot(const Err<int, String>('a')));
    });
  });

  group('Unit', () {
    test('has exactly one value', () {
      expect(unit, same(unit));
    });
  });
}
