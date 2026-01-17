/// Canonical, stable row key builder for feed rows.
///
/// Format (DEC-139A): `v1/<screen>/<rowType>/<k>=<v>...` with percent-encoded
/// UTF-8 values and no raw `/` or `=` in values.
abstract final class RowKey {
  static String v1({
    required String screen,
    required String rowType,
    Map<String, String> params = const <String, String>{},
  }) {
    final normalizedScreen = _cleanSegment(screen);
    final normalizedRowType = _cleanSegment(rowType);

    final entries = params.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    final parts = <String>['v1', normalizedScreen, normalizedRowType];

    for (final e in entries) {
      final key = _cleanSegment(e.key);
      final value = _encodeValue(e.value);
      parts.add('$key=$value');
    }

    return parts.join('/');
  }

  static String _encodeValue(String value) {
    // Uri.encodeComponent performs percent-encoding over UTF-8.
    return Uri.encodeComponent(value);
  }

  static String _cleanSegment(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return 'unknown';
    return trimmed.replaceAll('/', '_').replaceAll('=', '_');
  }
}
