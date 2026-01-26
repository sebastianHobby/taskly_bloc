@Tags(['unit'])
library;

import '../../../../helpers/test_imports.dart';

import 'dart:convert';

import 'package:taskly_data/drift_converters.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('Json converters', () {
    testSafe('JsonMapConverter decodes map JSON', () async {
      const converter = JsonMapConverter();
      final decoded = converter.fromSql('{"a":1,"b":"x"}');
      expect(decoded, equals(<String, dynamic>{'a': 1, 'b': 'x'}));

      final reEncoded = converter.toSql(decoded);
      expect(
        jsonDecode(reEncoded),
        equals(<String, dynamic>{'a': 1, 'b': 'x'}),
      );
    });

    testSafe('JsonMapConverter handles double-encoded JSON map', () async {
      const converter = JsonMapConverter();
      final doubleEncoded = jsonEncode('{"a":1}');
      final decoded = converter.fromSql(doubleEncoded);
      expect(decoded, equals(<String, dynamic>{'a': 1}));
    });

    testSafe('JsonMapOrWrappedListConverter wraps list payload', () async {
      const converter = JsonMapOrWrappedListConverter(listKey: 'items');
      final decoded = converter.fromSql('["a","b"]');
      expect(
        decoded,
        equals(<String, dynamic>{
          'items': ['a', 'b'],
        }),
      );
    });

    testSafe(
      'JsonStringListConverter decodes list and stringifies entries',
      () async {
        const converter = JsonStringListConverter();
        final decoded = converter.fromSql('["a", 2, true]');
        expect(decoded, equals(['a', '2', 'true']));
      },
    );

    testSafe('JsonStringListConverter throws for non-list', () async {
      const converter = JsonStringListConverter();
      expect(() => converter.fromSql('{"a":1}'), throwsA(isA<ArgumentError>()));
    });
  });
}
