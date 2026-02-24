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

    testSafe('JsonMapConverter throws for non-map payloads', () async {
      const converter = JsonMapConverter();
      expect(() => converter.fromSql('[1,2,3]'), throwsA(isA<ArgumentError>()));
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
      'JsonMapOrWrappedListConverter decodes map and throws on scalar',
      () async {
        const converter = JsonMapOrWrappedListConverter();
        expect(converter.fromSql('{"a":1}'), equals(<String, dynamic>{'a': 1}));
        expect(() => converter.fromSql('42'), throwsA(isA<ArgumentError>()));
        expect(jsonDecode(converter.toSql(const {'x': 1})), {'x': 1});
      },
    );

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

    testSafe('JsonIntListConverter decodes ints and filters non-numbers', () async {
      const converter = JsonIntListConverter();
      final decoded = converter.fromSql('[1,2.8,"x",true]');
      expect(decoded, equals([1, 2]));
      expect(jsonDecode(converter.toSql(decoded)), equals([1, 2]));
    });

    testSafe('JsonIntListConverter throws for non-list', () async {
      const converter = JsonIntListConverter();
      expect(() => converter.fromSql('{"a":1}'), throwsA(isA<ArgumentError>()));
    });
  });
}
