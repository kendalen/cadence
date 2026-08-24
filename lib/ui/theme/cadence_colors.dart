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
}
