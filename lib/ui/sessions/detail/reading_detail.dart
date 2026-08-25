import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/reading.dart';
import '../../../l10n/app_localizations.dart';
import '../reading_context_labels.dart';

/// One reading shown in the session detail screen.
///
/// Shows the reading's own pressure, time and pulse, with any recorded context
/// (arm, posture, medication) as chips and the note beneath. This is where a
/// reading's context surfaces to the user; it is a record of fact, not
/// interpreted (CLAUDE.md §4).
class ReadingDetail extends StatelessWidget {
  /// Shows [reading] as a row in the session detail screen.
  const ReadingDetail(this.reading, {super.key});

  /// The reading to show.
  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.jm(locale).format(reading.takenAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.readingPressure(reading.systolic, reading.diastolic),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(time, style: theme.textTheme.bodyMedium),
              if (reading.pulse != null) ...[
                const SizedBox(width: 16),
                Text(
                  l10n.readingPulse(reading.pulse!),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
          if (reading.hasContext) ...[
            const SizedBox(height: 6),
            _ContextChips(reading),
          ],
          if (reading.notes != null) ...[
            const SizedBox(height: 6),
            Text(
              reading.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The reading's recorded context as small chips, in a fixed order.
class _ContextChips extends StatelessWidget {
  const _ContextChips(this.reading);

  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final site = reading.site;
    final posture = reading.posture;
    final medicationTiming = reading.medicationTiming;
    final labels = [
      if (site != null) siteLabel(site, l10n),
      if (posture != null) postureLabel(posture, l10n),
      if (medicationTiming != null)
        medicationTimingLabel(medicationTiming, l10n),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [for (final label in labels) _ContextChip(label)],
    );
  }
}

/// A single neutral pill holding one context label.
class _ContextChip extends StatelessWidget {
  const _ContextChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
