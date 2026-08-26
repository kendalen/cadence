import 'package:cadence/ui/theme/cadence_extra_colors.dart';
import 'package:cadence/ui/theme/cadence_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCadenceTheme', () {
    test('defaults to the light theme', () {
      final theme = buildCadenceTheme();
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('Brightness.dark builds an actually-dark theme', () {
      final theme = buildCadenceTheme(Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      // A dark surface, not the light paper — guards against forgetting to swap
      // the palette when the brightness flips.
      expect(theme.scaffoldBackgroundColor.computeLuminance(), lessThan(0.1));
    });

    test('carries the CadenceExtraColors extension in both brightnesses', () {
      final light = buildCadenceTheme(Brightness.light)
          .extension<CadenceExtraColors>();
      final dark = buildCadenceTheme(Brightness.dark)
          .extension<CadenceExtraColors>();
      expect(light, CadenceExtraColors.light);
      expect(dark, CadenceExtraColors.dark);
      // The two palettes must differ, or dark silently reused light's series.
      expect(dark!.systolic, isNot(light!.systolic));
      expect(dark.sand, isNot(light.sand));
    });
  });
}
