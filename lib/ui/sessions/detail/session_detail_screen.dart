import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/session.dart';
import '../../../l10n/app_localizations.dart';
import 'reading_detail.dart';

/// One occasion in full: its readings and, when it holds more than one, their
/// average (CLAUDE.md §4).
///
/// Read-only. It takes the [Session] the list already holds rather than
/// re-reading the store; editing and deleting are a later slice that will hang
/// off this screen. Nothing here is coloured or labelled as good or bad, and no
/// threshold is shown — the average is a fact about the occasion, not a verdict
/// (CLAUDE.md §1, §4).
class SessionDetailScreen extends StatelessWidget {
  /// Shows [session].
  const SessionDetailScreen(this.session, {super.key});

  /// The occasion to show.
  final Session session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMd(locale)
        .add_jm()
        .format(session.occurredAt.toLocal());
    final readings = session.readingsByTime;

    // The average of a lone reading is that reading, so an average block would
    // only repeat it. It earns its place only when it aggregates two or more.
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
