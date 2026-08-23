import 'package:uuid/uuid.dart';

import '../../domain/sessions/id_generator.dart';

/// An [IdGenerator] producing UUID v7 strings.
///
/// v7 is time-ordered, so ids sort by creation and index well, and it stays
/// unique across devices — which a later backup and restore relies on.
class UuidIdGenerator implements IdGenerator {
  /// Creates a generator drawing on the platform random source.
  const UuidIdGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String newId() => _uuid.v7();
}
