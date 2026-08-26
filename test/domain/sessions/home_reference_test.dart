import 'package:cadence/domain/sessions/home_reference.dart';
import 'package:cadence/domain/sessions/session_average.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('below when both values are under the reference', () {
    expect(
      compareToHomeReference(
        const SessionAverage(systolic: 128, diastolic: 82),
      ),
      ReferenceComparison.below,
    );
  });

  test('at or above when only systolic reaches the reference', () {
    expect(
      compareToHomeReference(
        const SessionAverage(systolic: 136, diastolic: 80),
      ),
      ReferenceComparison.atOrAbove,
    );
  });

  test('at or above when only diastolic reaches the reference', () {
    expect(
      compareToHomeReference(
        const SessionAverage(systolic: 128, diastolic: 88),
      ),
      ReferenceComparison.atOrAbove,
    );
  });

  test('at or above when both reach the reference', () {
    expect(
      compareToHomeReference(
        const SessionAverage(systolic: 140, diastolic: 90),
      ),
      ReferenceComparison.atOrAbove,
    );
  });

  test('the exact 135/85 boundary is at or above', () {
    expect(
      compareToHomeReference(
        const SessionAverage(systolic: 135, diastolic: 85),
      ),
      ReferenceComparison.atOrAbove,
    );
  });
}
