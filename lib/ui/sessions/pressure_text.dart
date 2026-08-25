import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A blood-pressure value, `systolic/diastolic`, always shown in bold.
///
/// The bold weight is a design invariant — the pressure is the number the user
/// is here to read, so it carries the same emphasis everywhere it appears
/// (list, coverage summary, session average, each reading). Kept in one place
/// so that invariant, and the one formatting of the value, live in a single
/// widget (CLAUDE.md §8). [style] is the base type scale for the context; the
/// bold weight is layered on top of it.
class PressureText extends StatelessWidget {
  /// Shows [systolic] over [diastolic] in bold, over the optional base [style].
  const PressureText(this.systolic, this.diastolic, {this.style, super.key});

  /// Systolic pressure, in mmHg.
  final int systolic;

  /// Diastolic pressure, in mmHg.
  final int diastolic;

  /// The base text style to bold, or `null` to bold the ambient text style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.readingPressure(systolic, diastolic),
      style: (style ?? const TextStyle()).copyWith(fontWeight: FontWeight.w700),
    );
  }
}
