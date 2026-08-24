import 'package:flutter/material.dart';

import '../../../domain/sessions/reading_context.dart';
import '../../../l10n/app_localizations.dart';
import '../reading_context_labels.dart';

/// The optional arm / body-position / medication fields, collapsed by default
/// so the fast path (just the numbers) stays uncluttered.
class ReadingContextDetails extends StatelessWidget {
  /// Shows the current [site], [posture] and [medicationTiming] selections and
  /// reports changes through [onSite], [onPosture] and [onMedication].
  const ReadingContextDetails({
    required this.site,
    required this.posture,
    required this.medicationTiming,
    required this.onSite,
    required this.onPosture,
    required this.onMedication,
    super.key,
  });

  /// Where the cuff was placed, or `null` when not recorded.
  final MeasurementSite? site;

  /// The body position, or `null` when not recorded.
  final Posture? posture;

  /// Before or after medication, or `null` when not recorded.
  final MedicationTiming? medicationTiming;

  /// Called when the site selection changes.
  final ValueChanged<MeasurementSite?> onSite;

  /// Called when the posture selection changes.
  final ValueChanged<Posture?> onPosture;

  /// Called when the medication-timing selection changes.
  final ValueChanged<MedicationTiming?> onMedication;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      title: Text(l10n.contextDetails),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        _dropdown<MeasurementSite>(
          key: const Key('siteDropdown'),
          label: l10n.siteFieldLabel,
          value: site,
          values: MeasurementSite.values,
          labelOf: (value) => siteLabel(value, l10n),
          notRecorded: l10n.contextNotRecorded,
          onChanged: onSite,
        ),
        const SizedBox(height: 8),
        _dropdown<Posture>(
          key: const Key('postureDropdown'),
          label: l10n.postureFieldLabel,
          value: posture,
          values: Posture.values,
          labelOf: (value) => postureLabel(value, l10n),
          notRecorded: l10n.contextNotRecorded,
          onChanged: onPosture,
        ),
        const SizedBox(height: 8),
        _dropdown<MedicationTiming>(
          key: const Key('medicationDropdown'),
          label: l10n.medicationFieldLabel,
          value: medicationTiming,
          values: MedicationTiming.values,
          labelOf: (value) => medicationTimingLabel(value, l10n),
          notRecorded: l10n.contextNotRecorded,
          onChanged: onMedication,
        ),
      ],
    );
  }

  Widget _dropdown<T extends Enum>({
    required Key key,
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) labelOf,
    required String notRecorded,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T?>(
    key: key,
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<T?>(value: null, child: Text(notRecorded)),
      for (final option in values)
        DropdownMenuItem<T?>(value: option, child: Text(labelOf(option))),
    ],
    onChanged: onChanged,
  );
}
