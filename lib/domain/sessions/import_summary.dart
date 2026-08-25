import 'package:equatable/equatable.dart';

/// The outcome of importing sessions into the store (CLAUDE.md §5).
///
/// Import merges by id and never overwrites: a session whose id is already
/// stored is left untouched. This records how the incoming set split so the
/// user can be told what happened — nothing is dropped silently.
final class ImportSummary extends Equatable {
  /// Records that [added] sessions were new and [alreadyPresent] were skipped
  /// because their id was already stored.
  const ImportSummary({required this.added, required this.alreadyPresent});

  /// How many incoming sessions were new and were stored.
  final int added;

  /// How many incoming sessions were skipped because their id already existed
  /// (local data wins on a clash).
  final int alreadyPresent;

  @override
  List<Object?> get props => [added, alreadyPresent];
}
