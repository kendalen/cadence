import 'package:equatable/equatable.dart';

import '../../../domain/sessions/reading_context.dart';

/// The values a new occasion's first reading opens on.
///
/// Built once when the entry form is opened — from the user's own history, or a
/// neutral default when there is none — and applied to the form's fields before
/// the user starts. The numbers are a gentle nudge, not a norm or a target
/// (CLAUDE.md §4): they are the user's own data and stay editable before they
/// are saved.
final class EntrySeed extends Equatable {
  /// Creates a seed. [pulse] and the context fields are absent by default, as
  /// they are for a first reading with no history to draw on.
  const EntrySeed({
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.site,
    this.posture,
    this.medicationTiming,
  });

  /// Systolic value to open on, in mmHg.
  final int systolic;

  /// Diastolic value to open on, in mmHg.
  final int diastolic;

  /// Pulse to open on in bpm, or `null` to leave the optional pulse field empty.
  final int? pulse;

  /// Measurement site to pre-select, or `null` for none.
  final MeasurementSite? site;

  /// Body position to pre-select, or `null` for none.
  final Posture? posture;

  /// Medication timing to pre-select, or `null` for none.
  final MedicationTiming? medicationTiming;

  @override
  List<Object?> get props => [
    systolic,
    diastolic,
    pulse,
    site,
    posture,
    medicationTiming,
  ];
}
