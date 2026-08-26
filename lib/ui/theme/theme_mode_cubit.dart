import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/settings/app_theme_mode.dart';
import '../../domain/settings/settings_repository.dart';

/// Holds the app's current [AppThemeMode] and persists changes to it.
///
/// It lives above `MaterialApp` so both the app (which feeds the mode to
/// `MaterialApp.themeMode`) and the Settings screen (which changes it) share one
/// source of truth — the app's single state-management approach (CLAUDE.md §3),
/// rather than a bespoke listenable.
///
/// The initial value is passed in — read from the store before the app starts,
/// so the first frame already has the right theme and nothing flashes.
class ThemeModeCubit extends Cubit<AppThemeMode> {
  /// Starts at [initial] and writes later changes to [_settings].
  ThemeModeCubit(this._settings, AppThemeMode initial) : super(initial);

  final SettingsRepository _settings;

  /// Switches to [mode] immediately and persists it. The UI updates from the
  /// emit; the write is best-effort (a failure just means the choice is not
  /// remembered next launch — see [SettingsRepository.setThemeMode]).
  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _settings.setThemeMode(mode);
  }
}
