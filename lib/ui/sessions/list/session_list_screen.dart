import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../entry/session_entry_screen.dart';
import 'session_list_cubit.dart';
import 'session_list_state.dart';

/// The recorded readings, newest first.
///
/// Read-only in this slice: editing and deleting are data-loss-adjacent and
/// get their own slice, with confirmation and undo (CLAUDE.md §6).
class SessionListScreen extends StatelessWidget {
  /// Shows the sessions held by the repository provided above this widget.
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => SessionListCubit(context.read<SessionRepository>()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: BlocBuilder<SessionListCubit, SessionListState>(
          builder: (context, state) => switch (state) {
            SessionListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SessionListLoaded(:final sessions) when sessions.isEmpty =>
              const _EmptyList(),
            SessionListLoaded(:final sessions) => ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) => _SessionTile(sessions[index]),
            ),
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEntryForm(context),
          tooltip: l10n.addReading,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _openEntryForm(BuildContext context) {
    // The list needs no result back: it is watching the store, so a saved
    // session arrives through the stream.
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SessionEntryScreen()),
    );
  }
}

/// What the list shows before anything has been recorded.
class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.sessionListEmpty, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.sessionListEmptyHint, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// One occasion in the list.
class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session);

  final Session session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // This slice records exactly one reading per occasion. When multi-reading
    // entry lands, this row shows the session rather than its first reading.
    final reading = session.readings.first;
    final locale = Localizations.localeOf(context).toString();
    final takenAt = DateFormat.yMMMd(locale)
        .add_jm()
        .format(session.occurredAt.toLocal());

    return ListTile(
      title: Text(l10n.readingPressure(reading.systolic, reading.diastolic)),
      subtitle: Text(takenAt),
      trailing: reading.pulse == null
          ? null
          : Text(l10n.readingPulse(reading.pulse!)),
    );
  }
}
