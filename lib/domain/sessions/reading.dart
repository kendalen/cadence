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
  ///
  /// Throws [ArgumentError] if [takenAt] is not UTC — the store keeps every
  /// timestamp in UTC, and a local time would silently mis-place the reading in
  /// time. A throw (not an `assert`) holds this in release builds too.
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
  }) {
    if (!takenAt.isUtc) {
      throw ArgumentError.value(takenAt, 'takenAt', 'must be in UTC');
    }
  }

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

  /// This reading with its identity changed to [id], every other field kept.
  ///
  /// Used when editing: the entry validation ([ReadingInput.validate]) mints a
  /// fresh id, but an edited reading must keep the identity the store knows it
  /// by, so its validated values are re-stamped with the original [ReadingId].
  Reading withId(ReadingId id) => Reading(
    id: id,
    systolic: systolic,
    diastolic: diastolic,
    takenAt: takenAt,
    pulse: pulse,
    notes: notes,
    site: site,
    posture: posture,
    medicationTiming: medicationTiming,
  );

  /// Whether any measurement context was recorded for this reading.
  ///
  /// True when [site], [posture] or [medicationTiming] is set. Notes are not
  /// context (CLAUDE.md §4) and do not count here.
  bool get hasContext =>
      site != null || posture != null || medicationTiming != null;

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
