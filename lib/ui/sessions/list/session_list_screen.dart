import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../domain/sessions/weekly_coverage.dart';
import '../../../l10n/app_localizations.dart';
import '../../system_insets.dart';
import '../detail/session_detail_screen.dart';
import '../entry/session_entry_screen.dart';
import '../pressure_text.dart';
import '../trends/trends_screen.dart';
import 'session_list_cubit.dart';
import 'session_list_state.dart';
import 'session_overflow_menu.dart';
import 'weekly_coverage_card.dart';

/// The recorded readings, newest first.
///
/// The list itself is read-only: an occasion is opened, edited, and deleted on
/// the [SessionDetailScreen] a tap away, not from here.
class SessionListScreen extends StatelessWidget {
  /// Shows the sessions held by the repository provided above this widget.
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => SessionListCubit(context.read<SessionRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.show_chart),
              tooltip: l10n.trendsTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const TrendsScreen(),
                ),
              ),
            ),
            const SessionOverflowMenu(),
          ],
        ),
        body: BlocBuilder<SessionListCubit, SessionListState>(
          builder: (context, state) => switch (state) {
            SessionListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SessionListLoaded(:final sessions) when sessions.isEmpty =>
              const _EmptyList(),
            SessionListLoaded(:final sessions) => Column(
              children: [
                // The week's coverage stays pinned while the occasions scroll,
                // so the older audience never loses the "am I keeping up?"
                // summary. The clock lives here, keeping weeklyCoverage pure.
                // Side-only SafeArea so the card clears a landscape side bar
                // without gaining a bottom gap above the list.
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: WeeklyCoverageCard(
                      weeklyCoverage(sessions, now: DateTime.now()),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    // Room at the end so the last card can scroll clear of the
                    // floating "Add a reading" button (and the nav bar) instead
                    // of hiding behind it.
                    padding: withSystemInsets(
                      context,
                      const EdgeInsets.only(bottom: 88),
                    ),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) =>
                        _SessionTile(sessions[index]),
                  ),
                ),
              ],
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

    // A card per occasion, matching the approved visual design; the card's
    // colour, border, radius and spacing come from the theme's cardTheme.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Row(
          children: [
            PressureText(average.systolic, average.diastolic),
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
