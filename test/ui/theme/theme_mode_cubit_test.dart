import 'package:cadence/domain/settings/app_theme_mode.dart';
import 'package:cadence/ui/theme/theme_mode_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository settings;

  setUp(() => settings = FakeSettingsRepository());

  test('starts at the initial mode', () {
    final cubit = ThemeModeCubit(settings, AppThemeMode.dark);

    expect(cubit.state, AppThemeMode.dark);
  });

  test('setMode emits the new mode and persists it', () async {
    final cubit = ThemeModeCubit(settings, AppThemeMode.system);

    await cubit.setMode(AppThemeMode.dark);

    expect(cubit.state, AppThemeMode.dark);
    expect(await settings.themeMode(), AppThemeMode.dark);
  });

  test('setMode to the current mode does not re-emit or re-write', () async {
    final cubit = ThemeModeCubit(settings, AppThemeMode.light);
    final emitted = <AppThemeMode>[];
    cubit.stream.listen(emitted.add);

    await cubit.setMode(AppThemeMode.light);

    expect(emitted, isEmpty);
  });
}
