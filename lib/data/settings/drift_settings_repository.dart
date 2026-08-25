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
    final row =
        await (_database.select(_database.appSettings)
              ..where((setting) => setting.settingKey.equals(_disclaimerKey)))
            .getSingleOrNull();
    return row?.settingValue == 'true';
  }

  @override
  Future<void> acknowledgeDisclaimer() => _database
      .into(_database.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          settingKey: _disclaimerKey,
          settingValue: 'true',
        ),
      );
}
