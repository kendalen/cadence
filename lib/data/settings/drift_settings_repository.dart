import '../../domain/settings/settings_repository.dart';
import '../database/app_database.dart';

/// [SettingsRepository] backed by the drift [AppSettings] key-value table.
///
/// Each preference owns a key and encodes its own value as text. The one key so
/// far is the first-run acknowledgement, stored as `'true'` once set; a missing
/// row reads as not-yet-acknowledged (CLAUDE.md §1).
class DriftSettingsRepository implements SettingsRepository {
  /// Reads and writes settings on [_database].
  DriftSettingsRepository(this._database);

  final AppDatabase _database;

  /// Key of the first-run acknowledgement flag.
  static const String _disclaimerKey = 'disclaimerAcknowledged';

  @override
  Future<bool> isDisclaimerAcknowledged() async {
    // A read failure must default to the safe answer (SettingsRepository
    // contract): "not acknowledged", so the mandatory §1 notice shows rather
    // than being silently skipped on a storage error. The catch is deliberately
    // broad — a closed database throws a StateError (an Error, not an
    // Exception) — because for this regulated path showing the notice again is
    // always safe, and a genuine bug here surfaces as the notice reappearing.
    try {
      final row =
          await (_database.select(_database.appSettings)
                ..where((setting) => setting.settingKey.equals(_disclaimerKey)))
              .getSingleOrNull();
      return row?.settingValue == 'true';
    } on Object {
      return false;
    }
  }

  @override
  Future<void> acknowledgeDisclaimer() async {
    // A write failure is not fatal (contract): the worst case is the one-time
    // notice showing once more next launch. Swallow it rather than surface a
    // storage error to the user. Broad for the same reason as the read above.
    try {
      await _database
          .into(_database.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              settingKey: _disclaimerKey,
              settingValue: 'true',
            ),
          );
    } on Object {
      // Intentionally ignored — see contract note above.
    }
  }
}
