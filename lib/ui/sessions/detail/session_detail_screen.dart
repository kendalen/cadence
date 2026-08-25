import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/core/result.dart';
import '../../../domain/sessions/ids.dart';
import '../../../domain/sessions/reading.dart';
import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../system_insets.dart';
import '../entry/edit_reading_screen.dart';
import 'reading_detail.dart';
import 'session_detail_cubit.dart';

/// One occasion in full: its readings and, when it holds more than one, their
/// average (CLAUDE.md §4), with the option to delete the whole occasion.
///
/// Nothing here is coloured or labelled as good or bad, and no threshold is
/// shown — the average is a fact about the occasion, not a verdict (CLAUDE.md
/// §1, §4). Deleting is data-loss-adjacent, so it confirms first and offers an
/// undo afterwards (CLAUDE.md §6).
class SessionDetailScreen extends StatelessWidget {
  /// Shows [session].
  const SessionDetailScreen(this.session, {super.key});

  /// The occasion to show.
  final Session session;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        SessionDetailCubit(context.read<SessionRepository>(), session),
    child: const _SessionDetailView(),
  );
}

class _SessionDetailView extends StatelessWidget {
  const _SessionDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return BlocBuilder<SessionDetailCubit, Session>(
      builder: (context, session) {
        final title = DateFormat.yMMMd(locale)
            .add_jm()
            .format(session.occurredAt.toLocal());
        final readings = session.readingsByTime;

        // The average of a lone reading is that reading, so an average block
        // would only repeat it. It earns its place only when it aggregates
        // two or more.
        final showsAverage = readings.length > 1;

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: withSystemBottomInset(
              context,
              const EdgeInsets.symmetric(vertical: 8),
            ),
            children: [
              if (showsAverage) ...[
                _AverageCard(session),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    l10n.sessionReadingsTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
              for (final reading in readings)
                _ReadingRow(
                  reading: reading,
                  // Removing a lone reading is the same as deleting the
                  // occasion, so it is offered only when others remain; the
                  // "Delete this occasion" button covers the single-reading
                  // case.
                  canRemove: readings.length > 1,
                  onEdit: () => _editReading(context, reading),
                  onRemove: () => _removeReading(context, reading.id),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmAndDelete(context),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteSession),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Confirms, deletes, and — on success — leaves the screen and offers an undo.
  ///
  /// References that outlive this route (the navigator, the app-root messenger,
  /// the repository) are captured before the awaits, so nothing reaches for a
  /// disposed context afterwards. Undo restores the kept [Session] as-is: its
  /// id is free again once the delete has landed, so re-adding cannot collide.
  Future<void> _confirmAndDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmDelete(context, l10n);
    if (confirmed != true || !context.mounted) {
      return;
    }

    final cubit = context.read<SessionDetailCubit>();
    final repository = context.read<SessionRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final session = cubit.state;

    switch (await cubit.delete()) {
      case Ok():
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.sessionDeleted),
              action: SnackBarAction(
                label: l10n.undo,
                // ponytail: fire-and-forget restore. A re-add of a just-valid
                // session on a freed id all but never fails; surface it only if
                // that assumption stops holding.
                onPressed: () => repository.add(session),
              ),
            ),
          );
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorDeleteFailed)));
    }
  }

  /// Asks the user to confirm removing the whole occasion. Returns `true` only
  /// if they tapped Delete; `null`/`false` on cancel or a dismissed dialog.
  Future<bool?> _confirmDelete(BuildContext context, AppLocalizations l10n) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteSessionConfirmTitle),
          content: Text(l10n.deleteSessionConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );

  /// Opens the editor for [reading] and, if it comes back corrected, saves it.
  ///
  /// The editor returns the corrected reading (same id, see [Reading.withId])
  /// or `null` if the user backs out. On success the store change flows back
  /// through the cubit's watch and refreshes the display; a write failure is
  /// surfaced and the readings are left as they were. Handles that outlive the
  /// editor route are captured before the await.
  Future<void> _editReading(BuildContext context, Reading reading) async {
    final cubit = context.read<SessionDetailCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final edited = await Navigator.of(context).push<Reading>(
      MaterialPageRoute<Reading>(
        builder: (context) => EditReadingScreen(reading),
      ),
    );
    if (edited == null) {
      return;
    }

    if (await cubit.save(cubit.state.withReadingReplaced(edited)) is Err) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    }
  }

  /// Removes one reading from a multi-reading occasion, with an undo.
  ///
  /// The occasion stays (the row offering this is shown only when more than one
  /// reading remains), so the store keeps it and undo simply writes the
  /// previous readings back. No confirmation dialog: the removal is small and
  /// immediately reversible; the whole-occasion delete keeps its dialog.
  Future<void> _removeReading(BuildContext context, ReadingId id) async {
    final cubit = context.read<SessionDetailCubit>();
    final repository = context.read<SessionRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final before = cubit.state;
    final remaining = before.withoutReading(id);
    if (remaining == null) {
      return; // The last reading; use "Delete this occasion" instead.
    }

    switch (await cubit.save(remaining)) {
      case Ok():
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.readingRemoved),
              action: SnackBarAction(
                label: l10n.undo,
                onPressed: () => repository.update(before),
              ),
            ),
          );
      case Err():
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
    }
  }
}

/// One reading on the detail screen, with edit and (optionally) remove actions.
///
/// The reading fills the row; the actions sit at its trailing edge as icon
/// buttons with spoken labels, kept to the >48dp target for the older audience
/// (roadmap ease-of-use principle).
class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    required this.reading,
    required this.canRemove,
    required this.onEdit,
    required this.onRemove,
  });

  final Reading reading;
  final bool canRemove;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ReadingDetail(reading)),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editReading,
            onPressed: onEdit,
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.removeReading,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// The occasion's mean, shown prominently above its readings.
class _AverageCard extends StatelessWidget {
  const _AverageCard(this.session);

  final Session session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final average = session.average;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sessionAverageTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  l10n.readingPressure(average.systolic, average.diastolic),
                  style: theme.textTheme.displaySmall,
                ),
                if (average.pulse != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    l10n.readingPulse(average.pulse!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.readingCount(session.readings.length),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
