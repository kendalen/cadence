import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/sessions/id_generator.dart';
import '../domain/sessions/session_repository.dart';
import '../domain/settings/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'first_run_gate.dart';
import 'theme/cadence_theme.dart';

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
    super.key,
  });

  /// The store the screens read from and write to.
  final SessionRepository sessionRepository;

  /// Source of identifiers for newly entered sessions and readings.
  final IdGenerator idGenerator;

  /// The store of app preferences (the first-run acknowledgement, §1).
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<SessionRepository>.value(value: sessionRepository),
      RepositoryProvider<IdGenerator>.value(value: idGenerator),
      RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
    ],
    child: MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: buildCadenceTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FirstRunGate(),
    ),
  );
}
