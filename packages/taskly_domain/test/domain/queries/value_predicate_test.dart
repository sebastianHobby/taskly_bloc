@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/queries/value_predicate.dart';

void main() {
  testSafe('ValuePredicate.fromJson throws on unknown type', () async {
    expect(
      () => ValuePredicate.fromJson(const <String, dynamic>{'type': 'nope'}),
      throwsArgumentError,
    );
  });

  testSafe('ValueNamePredicate JSON roundtrip uses default operator', () async {
    const p = ValueNamePredicate(value: 'hi');

    final decoded = ValuePredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ValueNamePredicate.fromJson uses operator when provided', () async {
    final decoded = ValueNamePredicate.fromJson(const <String, dynamic>{
      'type': 'name',
      'value': 'hi',
      'operator': 'startsWith',
    });

    expect(decoded.operator, StringOperator.startsWith);
    expect(decoded.value, 'hi');
  });

  testSafe('ValueColorPredicate JSON roundtrip', () async {
    const p = ValueColorPredicate(colorHex: '#ffffff');

    final decoded = ValuePredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ValueIdPredicate JSON roundtrip', () async {
    const p = ValueIdPredicate(valueId: 'v1');

    final decoded = ValuePredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ValueIdsPredicate JSON roundtrip preserves list order', () async {
    const p = ValueIdsPredicate(valueIds: ['a', 'b']);

    final decoded = ValuePredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('ValueIdsPredicate equality is order-sensitive', () async {
    const a = ValueIdsPredicate(valueIds: ['a', 'b']);
    const b = ValueIdsPredicate(valueIds: ['b', 'a']);

    expect(a, isNot(equals(b)));
  });
}
