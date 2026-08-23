/// Source of new, unique entity identifiers.
///
/// Injected rather than called statically so that the domain layer stays pure
/// and tests can supply deterministic identifiers. The production
/// implementation (UUID v7) lives in the data layer.
abstract interface class IdGenerator {
  /// Returns a new identifier, distinct from every one returned before it.
  String newId();
}
