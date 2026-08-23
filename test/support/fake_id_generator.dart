import 'package:cadence/domain/sessions/id_generator.dart';

/// An [IdGenerator] that hands out predictable identifiers, so a test can
/// assert on the identity a domain object was given.
class FakeIdGenerator implements IdGenerator {
  FakeIdGenerator({this.prefix = 'id'});

  final String prefix;
  int _next = 0;

  @override
  String newId() => '$prefix-${_next++}';
}
