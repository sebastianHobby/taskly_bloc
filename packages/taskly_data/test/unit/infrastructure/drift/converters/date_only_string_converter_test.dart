@Tags(['unit'])
library;

import '../../../../helpers/test_imports.dart';

import 'package:taskly_data/drift_converters.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('DateOnlyStringConverter', () {
    const converter = dateOnlyStringConverter;

    testSafe('toSql encodes YYYY-MM-DD', () async {
      final encoded = converter.toSql(DateTime(2025, 1, 5, 23, 59));
      expect(encoded, equals('2025-01-05'));
    });

    testSafe('fromSql parses YYYY-MM-DD to UTC midnight', () async {
      final decoded = converter.fromSql('2025-01-05');
      expect(decoded, equals(DateTime.utc(2025, 1, 5)));
    });

    testSafe('fromSql throws for invalid value', () async {
      expect(
        () => converter.fromSql('not-a-date'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
