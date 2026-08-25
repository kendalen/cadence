import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../detail/session_detail_screen.dart';
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEntryForm(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.addReading),
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

/// One occasion in the list, shown as the average of its readings (CLAUDE.md §4).
///
/// The average of a single reading is that reading, so a one-off entry reads as
/// itself; a badge marks the occasions holding more than one so the averaged row
/// is never mistaken for a single measurement. Tapping the row opens the
/// occasion in full ([SessionDetailScreen]) — the one place its individual
/// readings, context and notes are shown.
class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session);

  final Session session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final average = session.average;
    final readingCount = session.readings.length;
    final locale = Localizations.localeOf(context).toString();
    final takenAt = DateFormat.yMMMd(locale)
        .add_jm()
        .format(session.occurredAt.toLocal());

    return ListTile(
      title: Row(
        children: [
          Text(l10n.readingPressure(average.systolic, average.diastolic)),
          if (readingCount > 1) ...[
            const SizedBox(width: 8),
            _ReadingCountBadge(readingCount),
          ],
          const Spacer(),
          if (average.pulse != null) Text(l10n.readingPulse(average.pulse!)),
        ],
      ),
      subtitle: Text(takenAt),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => SessionDetailScreen(session),
        ),
      ),
    );
  }
}

/// A small pill showing how many readings an occasion holds.
///
/// The count is a numeral; the word "readings" lives in the accessible label
/// and tooltip, so screen-reader and long-press users hear "N readings" while
/// the row stays compact.
class _ReadingCountBadge extends StatelessWidget {
  const _ReadingCountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = l10n.readingCount(count);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
