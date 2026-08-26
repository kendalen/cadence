import 'session_average.dart';

/// Systolic half of the ESH home-monitoring reference blood pressure
/// (CLAUDE.md §4).
///
/// Home monitoring uses 135/85 mmHg — the home equivalent of the 140/90 office
/// threshold (ESH 2023 guidelines). This is a value to *compare against*, never
/// a diagnosis, a target the app tells the user to reach, or a grade on a single
/// reading (CLAUDE.md §1).
const int homeReferenceSystolic = 135;

/// Diastolic half of the ESH home-monitoring reference (see
/// [homeReferenceSystolic]).
const int homeReferenceDiastolic = 85;

/// Where a period average sits relative to the ESH home reference.
enum ReferenceComparison {
  /// Both systolic and diastolic are under the reference.
  below,

  /// Systolic and/or diastolic reaches the reference.
  atOrAbove,
}

/// Classifies [average] against the ESH home reference.
///
/// At-or-above when the systolic **or** the diastolic reaches its reference
/// (the ESH "and/or" rule — either component crossing counts, e.g. 128/88 is
/// at-or-above via diastolic); below only when both are under. States a
/// position, never a judgement of the numbers (CLAUDE.md §1).
ReferenceComparison compareToHomeReference(SessionAverage average) =>
    (average.systolic >= homeReferenceSystolic ||
        average.diastolic >= homeReferenceDiastolic)
    ? ReferenceComparison.atOrAbove
    : ReferenceComparison.below;
