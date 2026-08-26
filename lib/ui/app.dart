import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/sessions/id_generator.dart';
import '../domain/sessions/session_repository.dart';
import '../domain/settings/app_theme_mode.dart';
import '../domain/settings/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'first_run_gate.dart';
import 'theme/cadence_theme.dart';
import 'theme/theme_mode_cubit.dart';

/// The application widget.
///
/// Takes its dependencies rather than building them, so `main` is the only
/// place that knows about drift and a test can run the app against fakes
/// (CLAUDE.md §6 — explicit injection, no service locator).
class CadenceApp extends StatelessWidget {
  /// Runs the app against [sessionRepository] and [idGenerator].
  const CadenceApp({
    required this.sessionRepository,
    required this.idGenerator,
    required this.settingsRepository,
    required this.initialThemeMode,
    super.key,
  });

  /// The store the screens read from and write to.
  final SessionRepository sessionRepository;

  /// Source of identifiers for newly entered sessions and readings.
  final IdGenerator idGenerator;

  /// The store of app preferences (the first-run acknowledgement §1, the theme).
  final SettingsRepository settingsRepository;

  /// The theme mode read from [settingsRepository] before startup, so the first
  /// frame already renders in the user's chosen theme.
  final AppThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<SessionRepository>.value(value: sessionRepository),
      RepositoryProvider<IdGenerator>.value(value: idGenerator),
      RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
    ],
    child: BlocProvider(
      create: (_) => ThemeModeCubit(settingsRepository, initialThemeMode),
      child: BlocBuilder<ThemeModeCubit, AppThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          // Light and dark are both defined; themeMode picks between them —
          // system follows the phone, or the user's explicit choice overrides it.
          theme: buildCadenceTheme(Brightness.light),
          darkTheme: buildCadenceTheme(Brightness.dark),
          themeMode: _flutterThemeMode(themeMode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FirstRunGate(),
        ),
      ),
    ),
  );
}

/// Maps the domain [AppThemeMode] to Flutter's [ThemeMode] (the domain stays
/// free of Flutter types, CLAUDE.md §3).
ThemeMode _flutterThemeMode(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};
