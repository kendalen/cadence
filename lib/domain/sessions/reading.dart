import 'package:equatable/equatable.dart';

import 'ids.dart';
import 'reading_context.dart';

/// One blood-pressure measurement, typed in by the user from their own monitor.
///
/// Derived values such as pulse pressure and mean arterial pressure are
/// computed where they are needed, never stored (CLAUDE.md §4).
final class Reading extends Equatable {
  /// Creates a reading.
  ///
  /// [takenAt] must be in UTC; convert to local time only for display. The
  /// context fields ([site], [posture], [medicationTiming]) are optional and
  /// default to `null` when the user did not record them (CLAUDE.md §4).
  Reading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.takenAt,
    this.pulse,
    this.notes,
    this.site,
    this.posture,
    this.medicationTiming,
  }) : assert(takenAt.isUtc, 'takenAt must be UTC');

  /// Identity of this reading.
  final ReadingId id;

  /// Systolic pressure, in mmHg.
  final int systolic;

  /// Diastolic pressure, in mmHg.
  final int diastolic;

  /// Pulse in beats per minute, or `null` when the monitor reported none.
  final int? pulse;

  /// When the measurement was taken, in UTC.
  final DateTime takenAt;

  /// Note the user attached, or `null` when they wrote none.
  final String? notes;

  /// Where the cuff was placed, or `null` when the user did not record it.
  final MeasurementSite? site;

  /// The body position the reading was taken in, or `null` when unrecorded.
  final Posture? posture;

  /// Whether the reading was before or after medication, or `null` when
  /// unrecorded.
  final MedicationTiming? medicationTiming;

  @override
  List<Object?> get props => [
    id,
    systolic,
    diastolic,
    pulse,
    takenAt,
    notes,
    site,
    posture,
    medicationTiming,
  ];
}
