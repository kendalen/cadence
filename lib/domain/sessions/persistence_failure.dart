import 'package:equatable/equatable.dart';

/// A reason a store operation could not be completed.
///
/// Expected failures only; a bug in a query or a mapping surfaces as an
/// exception instead (CLAUDE.md §6).
sealed class PersistenceFailure extends Equatable {
  /// Const base constructor for the variants.
  const PersistenceFailure();
}

/// The write did not complete and nothing was stored.
final class WriteFailed extends PersistenceFailure {
  /// Records the underlying [cause], for diagnosis — never for display.
  const WriteFailed(this.cause);

  /// The error the store reported.
  final Object cause;

  @override
  List<Object?> get props => [cause];
}
