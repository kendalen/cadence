import 'package:flutter/material.dart';

import 'cadence_colors.dart';
import 'cadence_extra_colors.dart';

/// The Material 3 theme for Cadence: the approved "warm & reassuring" visual
/// direction (STATUS.md, 2026-08-24) expressed as a [ThemeData].
///
/// Teal is the structural accent and fills Material's [ColorScheme.primary]; the
/// single terracotta "clay" action colour is reserved for the entry
/// [FloatingActionButton] via [ThemeData.floatingActionButtonTheme], so it stays
/// a deliberate highlight rather than a general button colour. Colour is never
/// used to grade a reading (CLAUDE.md §1, §4).
///
/// Pass [Brightness.dark] for the warm-dark palette used when the phone is in
/// dark mode; the default is the light theme. The argument is optional so the
/// widget-test pump helpers that call `buildCadenceTheme()` need no change.
ThemeData buildCadenceTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final colorScheme = dark ? _darkColorScheme : _lightColorScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    // Hanken Grotesk, bundled as an app asset (pubspec.yaml) rather than fetched
    // by the google_fonts package: the app is offline-first (CLAUDE.md §2).
    fontFamily: _hankenGrotesk,
    extensions: [dark ? CadenceExtraColors.dark : CadenceExtraColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      // The lifted card surface, brightness-aware: white on light, a warm
      // charcoal a step above the page on dark.
      color: dark ? CadenceColors.darkSurface : CadenceColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Large targets for the older audience the app serves (STATUS.md
        // accessibility note; roadmap ease-of-use principle).
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? CadenceColors.darkClay : CadenceColors.clay,
      foregroundColor: CadenceColors.onAccent,
      // A gentle lift, not Material's default 6dp: the rest of the theme is
      // flat (elevation-0 app bar and cards), and the calm, warm direction
      // wants a soft shadow rather than a hard halo under the one raised button.
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
    ),
  );
}

const _hankenGrotesk = 'HankenGrotesk';

/// The warm light palette mapped onto Material's colour roles.
///
/// Seeded from teal so every role Cadence does not set explicitly still lands on
/// a harmonious warm neutral; the identity colours are then pinned to their
/// exact tokens ([CadenceColors]).
final ColorScheme _lightColorScheme =
    ColorScheme.fromSeed(
      seedColor: CadenceColors.teal,
      brightness: Brightness.light,
    ).copyWith(
      primary: CadenceColors.teal,
      onPrimary: CadenceColors.onAccent,
      primaryContainer: CadenceColors.tealTint,
      onPrimaryContainer: CadenceColors.tealInk,
      secondary: CadenceColors.tealInk,
      onSecondary: CadenceColors.onAccent,
      secondaryContainer: CadenceColors.tealTint,
      onSecondaryContainer: CadenceColors.tealInk,
      tertiary: CadenceColors.clay,
      onTertiary: CadenceColors.onAccent,
      tertiaryContainer: CadenceColors.clayTint,
      onTertiaryContainer: CadenceColors.clayInk,
      surface: CadenceColors.paper,
      onSurface: CadenceColors.ink,
      onSurfaceVariant: CadenceColors.inkSecondary,
      outline: CadenceColors.inkTertiary,
      outlineVariant: CadenceColors.border,
      error: CadenceColors.error,
      onError: CadenceColors.onAccent,
    );

/// The warm-dark palette mapped onto Material's colour roles.
///
/// Same structure as the light scheme, seeded dark from the brightened teal so
/// the unset roles land on warm dark neutrals; the identity colours are pinned
/// to the `dark…` tokens. On dark the brightened accents carry dark text
/// ([onPrimary]/[onTertiary] = [CadenceColors.darkPaper]) for legible contrast.
final ColorScheme _darkColorScheme =
    ColorScheme.fromSeed(
      seedColor: CadenceColors.darkTeal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: CadenceColors.darkTeal,
      onPrimary: CadenceColors.darkPaper,
      primaryContainer: CadenceColors.darkTealTint,
      onPrimaryContainer: CadenceColors.darkInk,
      secondary: CadenceColors.darkTeal,
      onSecondary: CadenceColors.darkPaper,
      secondaryContainer: CadenceColors.darkTealTint,
      onSecondaryContainer: CadenceColors.darkInk,
      tertiary: CadenceColors.darkClay,
      onTertiary: CadenceColors.darkPaper,
      tertiaryContainer: CadenceColors.darkClayTint,
      onTertiaryContainer: CadenceColors.darkInk,
      surface: CadenceColors.darkPaper,
      onSurface: CadenceColors.darkInk,
      onSurfaceVariant: CadenceColors.darkInkSecondary,
      outline: CadenceColors.darkInkTertiary,
      outlineVariant: CadenceColors.darkBorder,
      error: CadenceColors.darkError,
      onError: CadenceColors.darkPaper,
    );
