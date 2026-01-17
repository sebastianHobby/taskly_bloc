import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_data/drift_converters.dart';

void main() {
  group('JsonStringListConverter', () {
    const converter = JsonStringListConverter();

    test('round-trips a list of strings', () {
      const input = <String>['reviewed', 'snoozed', 'dismissed'];
      final encoded = converter.toSql(input);
      final decoded = converter.fromSql(encoded);
      expect(decoded, input);
    });

    test('decodes a double-encoded JSON array string', () {
      // Outer JSON string contains an inner JSON array string.
      const doubleEncoded = r'"[\"a\",\"b\"]"';
      final decoded = converter.fromSql(doubleEncoded);
      expect(decoded, const <String>['a', 'b']);
    });

    test('throws when decoded JSON is not a list', () {
      expect(
        () => converter.fromSql('{"actions":["reviewed"]}'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
