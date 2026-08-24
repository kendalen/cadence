import 'package:flutter/material.dart';

import 'cadence_colors.dart';

/// The Material 3 theme for Cadence: the approved "warm & reassuring" visual
/// direction (STATUS.md, 2026-08-24) expressed as a [ThemeData].
///
/// Teal is the structural accent and fills Material's [ColorScheme.primary]; the
/// single terracotta "clay" action colour is reserved for the entry
/// [FloatingActionButton] via [ThemeData.floatingActionButtonTheme], so it stays
/// a deliberate highlight rather than a general button colour. Colour is never
/// used to grade a reading (CLAUDE.md §1, §4).
ThemeData buildCadenceTheme() {
  final colorScheme = _cadenceColorScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    // Hanken Grotesk, bundled as an app asset (pubspec.yaml) rather than fetched
    // by the google_fonts package: the app is offline-first (CLAUDE.md §2).
    fontFamily: _hankenGrotesk,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: CadenceColors.surface,
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
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: CadenceColors.clay,
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

/// The warm palette mapped onto Material's colour roles.
///
/// Seeded from teal so every role Cadence does not set explicitly still lands on
/// a harmonious warm neutral; the identity colours are then pinned to their
/// exact tokens ([CadenceColors]).
final ColorScheme _cadenceColorScheme =
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
