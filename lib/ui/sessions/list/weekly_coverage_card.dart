import 'package:flutter/material.dart';

import '../../../domain/sessions/weekly_coverage.dart';
import '../../../l10n/app_localizations.dart';
import '../pressure_text.dart';

/// A summary of how well the last seven days keep to the 7-2-2 protocol,
/// pinned above the readings list (CLAUDE.md §4).
///
/// Shows occasions logged against occasions expected and days logged against
/// the seven the protocol spans, and — when at least one occasion falls in the
/// window — the period average. It states completeness; it never judges the
/// numbers or shows a threshold (CLAUDE.md §1).
class WeeklyCoverageCard extends StatelessWidget {
  /// Shows [coverage], computed by the caller from the current sessions.
  const WeeklyCoverageCard(this.coverage, {super.key});

  /// The coverage to display.
  final MonitoringCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final average = coverage.periodAverage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.coverageLast7Days, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            // Two dimensions of coverage side by side — how many occasions, and
            // over how many days — wrapping to separate lines under large font
            // scales. Both are plain counts, no judgement (§4, §1).
            Wrap(
              spacing: 8,
              children: [
                Text(
                  l10n.coverageOccasions(
                    coverage.occasionsLogged,
                    coverage.occasionsExpected,
                  ),
                  style: textTheme.bodyLarge,
                ),
                Text(
                  '·',
                  style: textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.coverageDays(coverage.daysLogged, coverage.daysExpected),
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
            if (average != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(l10n.sessionAverageTitle, style: textTheme.labelLarge),
                  const SizedBox(width: 8),
                  PressureText(
                    average.systolic,
                    average.diastolic,
                    style: textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (average.pulse != null)
                    Text(l10n.readingPulse(average.pulse!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
