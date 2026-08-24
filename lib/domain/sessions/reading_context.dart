/// The optional context a user can attach to a [Reading] (CLAUDE.md §4).
///
/// Each value is persisted by its identifier name: the data layer stores the
/// result of `.name` and reads it back with `values.byName`. **The names are
/// therefore a stored contract — renaming a value here would silently orphan
/// data already written under the old name, so change one only behind a schema
/// migration (CLAUDE.md §5).** In every enum, `null` on the reading means the
/// user simply did not record that context; there is no "unknown" value.
library;

/// Where the cuff was placed for a reading.
///
/// A wrist monitor is not interchangeable with an upper-arm cuff: it is
/// position-sensitive and its numbers are not directly comparable, so which was
/// used is worth recording. This is a record of fact, not a judgement — the app
/// does not interpret it (CLAUDE.md §4).
enum MeasurementSite {
  /// Upper arm, left side.
  leftArm,

  /// Upper arm, right side.
  rightArm,

  /// Wrist, left side.
  leftWrist,

  /// Wrist, right side.
  rightWrist,
}

/// The body position the reading was taken in.
///
/// The home-monitoring protocol is seated (CLAUDE.md §4); the others are
/// recorded when they apply.
enum Posture {
  /// Seated — the home-monitoring norm.
  sitting,

  /// Standing.
  standing,

  /// Lying down.
  lying,
}

/// Whether the reading was taken before or after taking medication.
enum MedicationTiming {
  /// Before medication.
  before,

  /// After medication.
  after,
}
