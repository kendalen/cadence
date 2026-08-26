import 'package:cadence/domain/settings/app_theme_mode.dart';
import 'package:cadence/domain/settings/settings_repository.dart';

/// In-memory [SettingsRepository] for tests: no drift, no async event loop.
class FakeSettingsRepository implements SettingsRepository {
  /// Starts with the disclaimer [acknowledged] (default not) and the given
  /// [themeMode] (default system).
  FakeSettingsRepository({
    this.acknowledged = false,
    AppThemeMode themeMode = AppThemeMode.system,
  }) : _storedThemeMode = themeMode;

  /// Whether the disclaimer is currently acknowledged.
  bool acknowledged;

  /// How many times [acknowledgeDisclaimer] was called, for assertions.
  int acknowledgeCount = 0;

  AppThemeMode _storedThemeMode;

  @override
  Future<bool> isDisclaimerAcknowledged() async => acknowledged;

  @override
  Future<void> acknowledgeDisclaimer() async {
    acknowledged = true;
    acknowledgeCount++;
  }

  @override
  Future<AppThemeMode> themeMode() async => _storedThemeMode;

  @override
  Future<void> setThemeMode(AppThemeMode mode) async => _storedThemeMode = mode;
}
