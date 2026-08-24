import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/sessions/id_generator.dart';
import '../domain/sessions/session_repository.dart';
import '../l10n/app_localizations.dart';
import 'sessions/list/session_list_screen.dart';
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
    super.key,
  });

  /// The store the screens read from and write to.
  final SessionRepository sessionRepository;

  /// Source of identifiers for newly entered sessions and readings.
  final IdGenerator idGenerator;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<SessionRepository>.value(value: sessionRepository),
      RepositoryProvider<IdGenerator>.value(value: idGenerator),
    ],
    child: MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: buildCadenceTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SessionListScreen(),
    ),
  );
}
