import 'package:equatable/equatable.dart';

/// The outcome of an operation that is expected to be able to fail.
///
/// Expected failures are values ([Err]); exceptions are reserved for
/// programming errors (CLAUDE.md §6). Exhaustive `switch` over the sealed
/// hierarchy forces the caller to handle both cases.
sealed class Result<T, E> extends Equatable {
  /// Const base constructor for the two variants.
  const Result();
}

/// A successful [Result] carrying [value].
final class Ok<T, E> extends Result<T, E> {
  /// Wraps the success [value] of an operation.
  const Ok(this.value);

  /// The value the operation produced.
  final T value;

  @override
  List<Object?> get props => [value];
}

/// A failed [Result] carrying [error].
final class Err<T, E> extends Result<T, E> {
  /// Wraps the expected failure [error] of an operation.
  const Err(this.error);

  /// The failure that occurred.
  final E error;

  @override
  List<Object?> get props => [error];
}
