/// A type with exactly one value, [unit].
///
/// Used as the success type of a [Result] whose operation succeeds without
/// producing anything meaningful, so that success still has to be matched on.
final class Unit {
  const Unit._();
}

/// The single value of [Unit].
const Unit unit = Unit._();
