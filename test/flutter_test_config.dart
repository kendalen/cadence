import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Suite-wide test bootstrap. Flutter runs the `testExecutable` in a file named
/// `flutter_test_config.dart` once, wrapping every test under this directory.
///
/// It swaps in a golden comparator that tolerates the tiny anti-aliasing
/// differences between the platform a golden was generated on (a maintainer's
/// macOS) and the one CI verifies on (Linux). Flutter goldens are otherwise only
/// guaranteed on a single platform, and `flutter test` runs in both places (the
/// lefthook pre-commit hook locally, GitHub Actions on Linux). A small pixel
/// tolerance lets one committed baseline serve both without hiding real
/// regressions: a wrong colour, a moved element, or an unapplied theme changes
/// far more of the image than the threshold allows.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenComparator(comparator.basedir);
  }
  await testMain();
}

/// A [LocalFileComparator] that passes as long as at most [_maxDiffFraction] of
/// the pixels differ.
class _TolerantGoldenComparator extends LocalFileComparator {
  // [LocalFileComparator] derives its own `basedir` from the directory of the
  // file passed here, so point it at a notional file inside the real basedir to
  // preserve it (the argument's own name is never read).
  _TolerantGoldenComparator(Uri basedir)
    : super(Uri.parse('${basedir}flutter_test_config.dart'));

  /// The fraction of differing pixels tolerated before a comparison fails (2%).
  /// Comfortably above cross-platform text anti-aliasing on the sparse screens
  /// tested here, comfortably below any genuine visual regression.
  static const double _maxDiffFraction = 0.02;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _maxDiffFraction) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
