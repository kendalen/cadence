import 'package:cadence/domain/settings/settings_repository.dart';

/// In-memory [SettingsRepository] for tests: no drift, no async event loop.
class FakeSettingsRepository implements SettingsRepository {
  /// Starts with the disclaimer [acknowledged] (default not).
  FakeSettingsRepository({this.acknowledged = false});

  /// Whether the disclaimer is currently acknowledged.
  bool acknowledged;

  /// How many times [acknowledgeDisclaimer] was called, for assertions.
  int acknowledgeCount = 0;

  @override
  Future<bool> isDisclaimerAcknowledged() async => acknowledged;

  @override
  Future<void> acknowledgeDisclaimer() async {
    acknowledged = true;
    acknowledgeCount++;
  }
}
