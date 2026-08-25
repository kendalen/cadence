import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/core/result.dart';
import '../../../domain/sessions/session.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../l10n/app_localizations.dart';
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
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ReadingDetail(reading),
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
