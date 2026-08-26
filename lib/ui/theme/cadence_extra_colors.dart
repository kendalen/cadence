import 'package:flutter/material.dart';

import 'cadence_colors.dart';

/// The Cadence colours that are not Material colour roles: the three chart
/// series ([systolic], [diastolic], [pulse]) and the coverage-card [sand] fill.
///
/// A data-series colour is not a Material role, so it cannot live on
/// [ColorScheme]. Carrying these four on a [ThemeExtension] instead of reading
/// [CadenceColors] directly lets them switch with brightness (light vs dark) the
/// same way the rest of the theme does — screens read them from
/// `Theme.of(context)` and never learn which palette is in effect.
///
/// Colour is never used to grade a reading, and the series stay colour-blind-safe
/// against each other in both palettes (CLAUDE.md §1, §4).
@immutable
class CadenceExtraColors extends ThemeExtension<CadenceExtraColors> {
  /// Bundles the four extra colours for one brightness.
  const CadenceExtraColors({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.sand,
  });

  /// The light-palette values (STATUS.md, 2026-08-24).
  static const light = CadenceExtraColors(
    systolic: CadenceColors.systolic,
    diastolic: CadenceColors.diastolic,
    pulse: CadenceColors.pulse,
    sand: CadenceColors.sand,
  );

  /// The warm-dark values, used when the phone is in dark mode.
  static const dark = CadenceExtraColors(
    systolic: CadenceColors.darkSystolic,
    diastolic: CadenceColors.darkDiastolic,
    pulse: CadenceColors.darkPulse,
    sand: CadenceColors.darkSand,
  );

  /// Systolic chart series colour.
  final Color systolic;

  /// Diastolic chart series colour.
  final Color diastolic;

  /// Pulse chart series colour.
  final Color pulse;

  /// The coverage-card ("Last 7 days") background fill.
  final Color sand;

  @override
  CadenceExtraColors copyWith({
    Color? systolic,
    Color? diastolic,
    Color? pulse,
    Color? sand,
  }) => CadenceExtraColors(
    systolic: systolic ?? this.systolic,
    diastolic: diastolic ?? this.diastolic,
    pulse: pulse ?? this.pulse,
    sand: sand ?? this.sand,
  );

  @override
  CadenceExtraColors lerp(CadenceExtraColors? other, double t) {
    if (other == null) return this;
    return CadenceExtraColors(
      systolic: Color.lerp(systolic, other.systolic, t)!,
      diastolic: Color.lerp(diastolic, other.diastolic, t)!,
      pulse: Color.lerp(pulse, other.pulse, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
    );
  }
}
