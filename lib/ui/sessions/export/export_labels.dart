import '../../../data/export/reading_export.dart';
import '../../../domain/sessions/reading_context.dart';
import '../../../l10n/app_localizations.dart';
import '../reading_context_labels.dart';

/// Gathers the localised text a CSV/PDF export needs from [l10n].
///
/// This is the one place the export's wording is assembled, so the data-layer
/// builders ([buildReadingRows] and the encoders) stay free of Flutter and of
/// any one language (CLAUDE.md §3, §9). Context values reuse the same
/// enum→label mapping the entry form uses (`reading_context_labels.dart`), so
/// the app grows no second way to name an arm or a posture (CLAUDE.md §8).
///
/// The column headers are listed in the order [buildReadingRows] emits cells;
/// several reuse existing field labels rather than adding new strings.
ExportLabels exportLabels(AppLocalizations l10n) => ExportLabels(
  title: l10n.exportTitle,
  disclaimer: l10n.exportDisclaimer,
  columnHeaders: [
    l10n.exportColumnDate,
    l10n.exportColumnTime,
    l10n.exportColumnOccasion,
    l10n.fieldSystolic,
    l10n.fieldDiastolic,
    l10n.fieldPulse,
    l10n.siteFieldLabel,
    l10n.postureFieldLabel,
    l10n.medicationFieldLabel,
    l10n.exportColumnNote,
  ],
  site: {
    for (final site in MeasurementSite.values) site: siteLabel(site, l10n),
  },
  posture: {
    for (final posture in Posture.values) posture: postureLabel(posture, l10n),
  },
  medication: {
    for (final timing in MedicationTiming.values)
      timing: medicationTimingLabel(timing, l10n),
  },
);
