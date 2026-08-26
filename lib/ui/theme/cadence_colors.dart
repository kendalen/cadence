import 'package:flutter/material.dart' show Color, Colors;

/// The Cadence colour palette: the exact values behind the approved
/// "warm & reassuring" visual direction (STATUS.md, 2026-08-24).
///
/// These are raw tokens. Screens should read colour from the [ThemeData] /
/// [ColorScheme] built in `cadence_theme.dart` rather than reach in here; the
/// two chart series colours ([systolic], [diastolic]) are the exception, since a
/// data series is not a Material colour role.
///
/// Colour is never used to grade a reading good or bad, and no threshold line is
/// drawn (CLAUDE.md §1, §4).
abstract final class CadenceColors {
  CadenceColors._();

  /// Warm "paper" page background.
  static const Color paper = Color(0xFFFAF6F1);

  /// Card and sheet surface — the lightest warm neutral.
  static const Color surface = Color(0xFFFFFFFF);

  /// "Sand": a slightly deeper neutral for quiet secondary fills.
  static const Color sand = Color(0xFFF3ECE4);

  /// Hairline border and divider over [paper].
  static const Color border = Color(0xFFEAE0D6);

  /// Primary text ("ink").
  static const Color ink = Color(0xFF2A2521);

  /// Secondary text — subtitles and captions.
  static const Color inkSecondary = Color(0xFF6F655C);

  /// Tertiary text — hints and disabled labels.
  static const Color inkTertiary = Color(0xFFA2968B);

  /// Teal: the structural accent (app bar, selection, links).
  static const Color teal = Color(0xFF2F6E63);

  /// Deep teal, for text or icons on a [tealTint] fill.
  static const Color tealInk = Color(0xFF234F47);

  /// Pale teal fill behind teal-accented content.
  static const Color tealTint = Color(0xFFDCEAE5);

  /// "Clay" terracotta: the single reserved action colour (the entry FAB).
  static const Color clay = Color(0xFFBC6248);

  /// Deep clay, for text or icons on a [clayTint] fill.
  static const Color clayInk = Color(0xFF8F4732);

  /// Pale clay fill behind clay-accented content.
  static const Color clayTint = Color(0xFFF6E2D9);

  /// Error red, kept muted to sit inside the warm palette. It marks input
  /// problems only — never a clinical signal (CLAUDE.md §4).
  static const Color error = Color(0xFFC62828);

  /// On-colour for solid accents ([teal], [clay], [error]).
  static const Color onAccent = Colors.white;

  /// Systolic chart series — validated colour-blind-safe against [diastolic]
  /// (STATUS.md, 2026-08-24). A data-series colour, not a Material role.
  static const Color systolic = Color(0xFF0E8C74);

  /// Diastolic chart series — validated colour-blind-safe against [systolic].
  static const Color diastolic = Color(0xFFB4832E);

  /// Pulse chart series (T3). It lives on its own chart below blood pressure, so
  /// it need not be colour-blind-distinct from [systolic]/[diastolic]. A muted
  /// slate, clear of the warm teal/ochre/clay accents (maintainer's call — the
  /// hex is proposed, retune to taste).
  static const Color pulse = Color(0xFF556B7A);

  // ---------------------------------------------------------------------------
  // Dark
  //
  // The warm-dark counterpart, used when the phone is set to dark mode (the app
  // follows the device — no in-app toggle). It keeps the same warmth as the
  // light palette rather than going cold or pure-black: surfaces are lifted
  // charcoals with a brown cast, accents are brightened so they read on a dark
  // ground. These hexes are deliberate STARTING POINTS for the maintainer to
  // retune on the device (as the light palette and the pulse colour were).
  //
  // Colour still never grades a reading and no threshold is drawn (§1, §4); the
  // two chart series stay colour-blind-safe against each other after brightening.
  // ---------------------------------------------------------------------------

  /// Dark page background — a deep warm charcoal, not pure black.
  static const Color darkPaper = Color(0xFF17130F);

  /// Dark card and sheet surface — lifted a step above [darkPaper].
  static const Color darkSurface = Color(0xFF221D18);

  /// Dark "sand": the quiet secondary fill (the coverage card), lifted again.
  static const Color darkSand = Color(0xFF2A241E);

  /// Hairline border and divider on dark.
  static const Color darkBorder = Color(0xFF38302A);

  /// Primary text on dark — warm off-white, not pure white.
  static const Color darkInk = Color(0xFFF2EAE1);

  /// Secondary text on dark.
  static const Color darkInkSecondary = Color(0xFFC4B8AC);

  /// Tertiary text on dark — hints and disabled labels.
  static const Color darkInkTertiary = Color(0xFF8B8074);

  /// Teal accent brightened to read on a dark ground.
  static const Color darkTeal = Color(0xFF5CB3A3);

  /// Deep-ish teal fill behind teal-accented content on dark.
  static const Color darkTealTint = Color(0xFF24463F);

  /// Clay action colour brightened for dark.
  static const Color darkClay = Color(0xFFE08769);

  /// Clay fill behind clay-accented content on dark.
  static const Color darkClayTint = Color(0xFF4A2C22);

  /// Error red on dark — a light rose, the Material dark convention.
  static const Color darkError = Color(0xFFF2B8B5);

  /// Systolic chart series on dark (brightened; still CVD-safe vs [darkDiastolic]).
  static const Color darkSystolic = Color(0xFF33B79C);

  /// Diastolic chart series on dark (brightened; still CVD-safe vs [darkSystolic]).
  static const Color darkDiastolic = Color(0xFFE0B24A);

  /// Pulse chart series on dark.
  static const Color darkPulse = Color(0xFF8CA6B8);
}
