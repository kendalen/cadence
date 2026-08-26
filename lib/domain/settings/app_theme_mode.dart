/// The user's choice of colour theme.
///
/// A pure-domain enum, deliberately separate from Flutter's `ThemeMode` so the
/// domain layer stays free of Flutter imports (CLAUDE.md §3); the UI maps one to
/// the other. [system] means "follow the phone's light/dark setting" and is the
/// default when the user has expressed no preference.
enum AppThemeMode {
  /// Follow the phone's light/dark setting. The default.
  system,

  /// Always use the light theme, regardless of the phone.
  light,

  /// Always use the dark theme, regardless of the phone.
  dark,
}
