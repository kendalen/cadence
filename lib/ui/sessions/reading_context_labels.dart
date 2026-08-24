import '../../domain/sessions/reading_context.dart';
import '../../l10n/app_localizations.dart';

/// Turns reading-context enum values into the labels shown for them.
///
/// Wording lives here rather than in the domain so the domain stays free of
/// presentation and every string comes from the ARB (CLAUDE.md §9). This mirrors
/// the `validation_messages.dart` pattern — the one way this app maps a domain
/// value to a localised string.

/// The label for a [MeasurementSite].
String siteLabel(MeasurementSite site, AppLocalizations l10n) => switch (site) {
  MeasurementSite.leftArm => l10n.siteLeftArm,
  MeasurementSite.rightArm => l10n.siteRightArm,
  MeasurementSite.leftWrist => l10n.siteLeftWrist,
  MeasurementSite.rightWrist => l10n.siteRightWrist,
};

/// The label for a [Posture].
String postureLabel(Posture posture, AppLocalizations l10n) =>
    switch (posture) {
      Posture.sitting => l10n.postureSitting,
      Posture.standing => l10n.postureStanding,
      Posture.lying => l10n.postureLying,
    };

/// The label for a [MedicationTiming].
String medicationTimingLabel(MedicationTiming timing, AppLocalizations l10n) =>
    switch (timing) {
      MedicationTiming.before => l10n.medicationBefore,
      MedicationTiming.after => l10n.medicationAfter,
    };
