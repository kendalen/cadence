import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/ids.dart';
import '../../../domain/sessions/reading.dart';
import '../../../l10n/app_localizations.dart';

/// The readings already banked for this occasion, each removable.
class BankedReadings extends StatelessWidget {
  /// Lists [readings] oldest first, calling [onRemove] with a reading's id when
  /// its remove control is tapped.
  const BankedReadings({
    required this.readings,
    required this.onRemove,
    super.key,
  });

  /// The readings banked for this occasion so far.
  final List<Reading> readings;

  /// Called with the id of the reading to drop from the occasion.
  final void Function(ReadingId id) onRemove;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.jm(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.readingsSoFar, style: Theme.of(context).textTheme.titleSmall),
        for (final reading in readings)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.readingPressure(reading.systolic, reading.diastolic),
            ),
            subtitle: Text(time.format(reading.takenAt.toLocal())),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.removeReading,
              onPressed: () => onRemove(reading.id),
            ),
          ),
      ],
    );
  }
}
