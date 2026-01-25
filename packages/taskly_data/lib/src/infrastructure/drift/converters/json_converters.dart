import 'dart:convert';

import 'package:drift/drift.dart';

/// Handles potentially double-encoded JSON data.
///
/// Some data in the database may have been incorrectly double-encoded
/// (stored as a JSON string containing another JSON string). This helper
/// detects and handles that case.
Object? _decodePossiblyDoubleEncodedJson(String json) {
  final decoded = jsonDecode(json);

  // If the first decode yields another JSON string, decode again.
  if (decoded is String) {
    return jsonDecode(decoded);
  }

  return decoded;
}

Map<String, dynamic> _parseJsonWithDoubleEncodingFallback(Object? json) {
  if (json == null) {
    throw ArgumentError('JSON value cannot be null');
  }
  if (json is Map<String, dynamic>) {
    return json;
  }
  if (json is String) {
    // Data may be incorrectly double-encoded.
    final decoded = _decodePossiblyDoubleEncodedJson(json);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ArgumentError(
      'Expected Map<String, dynamic> after decoding String, got ${decoded.runtimeType}',
    );
  }
  throw ArgumentError(
    'Expected Map<String, dynamic> or String, got ${json.runtimeType}',
  );
}

Map<String, dynamic> _parseJsonMapOrWrappedListWithDoubleEncodingFallback(
  Object? json, {
  required String listKey,
}) {
  if (json == null) {
    throw ArgumentError('JSON value cannot be null');
  }

  if (json is Map<String, dynamic>) return json;
  if (json is List) return <String, dynamic>{listKey: json};

  if (json is String) {
    final decoded = _decodePossiblyDoubleEncodedJson(json);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return <String, dynamic>{listKey: decoded};

    throw ArgumentError(
      'Expected Map<String, dynamic> or List after decoding String, got ${decoded.runtimeType}',
    );
  }

  throw ArgumentError(
    'Expected Map<String, dynamic>, List, or String, got ${json.runtimeType}',
  );
}

/// Generic converter for a map from String keys to dynamic values as JSON text.
///
/// Used by attention system tables for flexible JSON storage of trigger_config,
/// entity_selector, display_config, resolution_actions, and action_details.
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return _parseJsonWithDoubleEncodingFallback(fromDb);
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}

/// Converter for JSON text that may be either a map or a list.
///
/// This is used for legacy/remote data where a column sometimes stores a JSON
/// array (e.g. `resolution_actions`), but the application wants to treat it as
/// a map-shaped payload.
///
/// When the stored value is a JSON array, the list is wrapped under [listKey].
class JsonMapOrWrappedListConverter
    extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapOrWrappedListConverter({this.listKey = 'actions'});

  final String listKey;

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return _parseJsonMapOrWrappedListWithDoubleEncodingFallback(
      fromDb,
      listKey: listKey,
    );
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}

/// Converter for JSON text that must be a string list.
///
/// Stored format: a JSON array string (e.g. `["reviewed","snoozed"]`).
class JsonStringListConverter extends TypeConverter<List<String>, String> {
  const JsonStringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = _decodePossiblyDoubleEncodedJson(fromDb);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList(growable: false);
    }
    throw ArgumentError(
      'Expected JSON array after decoding String, got ${decoded.runtimeType}',
    );
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}

/// Converter for JSON text that must be an int list.
///
/// Stored format: a JSON array string (e.g. `[1,2,3]`).
class JsonIntListConverter extends TypeConverter<List<int>, String> {
  const JsonIntListConverter();

  @override
  List<int> fromSql(String fromDb) {
    final decoded = _decodePossiblyDoubleEncodedJson(fromDb);
    if (decoded is List) {
      return decoded
          .whereType<num>()
          .map((e) => e.toInt())
          .toList(growable: false);
    }
    throw ArgumentError(
      'Expected JSON array after decoding String, got ${decoded.runtimeType}',
    );
  }

  @override
  String toSql(List<int> value) {
    return jsonEncode(value);
  }
}
