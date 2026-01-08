import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/domain/models/screens/actions_config.dart';
import 'package:taskly_bloc/domain/models/screens/content_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';

/// Handles potentially double-encoded JSON data.
///
/// Some data in the database may have been incorrectly double-encoded
/// (stored as a JSON string containing another JSON string). This helper
/// detects and handles that case.
Map<String, dynamic> _parseJsonWithDoubleEncodingFallback(Object? json) {
  if (json == null) {
    throw ArgumentError('JSON value cannot be null');
  }
  if (json is Map<String, dynamic>) {
    return json;
  }
  if (json is String) {
    // Data was double-encoded - parse the string as JSON
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ArgumentError(
      'Expected Map<String, dynamic> after decoding String, got ${decoded.runtimeType}',
    );
  }
  throw ArgumentError(
    'Expected Map<String, dynamic> or String, got ${json.runtimeType}',
  );
}

/// Type converter for [EntitySelector] stored as JSON text.
final JsonTypeConverter2<EntitySelector, String, Object?>
entitySelectorConverter = TypeConverter.json2(
  fromJson: (json) =>
      EntitySelector.fromJson(_parseJsonWithDoubleEncodingFallback(json)),
  toJson: (EntitySelector selector) => selector.toJson(),
);

/// Type converter for [DisplayConfig] stored as JSON text.
final JsonTypeConverter2<DisplayConfig, String, Object?>
displayConfigConverter = TypeConverter.json2(
  fromJson: (json) =>
      DisplayConfig.fromJson(_parseJsonWithDoubleEncodingFallback(json)),
  toJson: (DisplayConfig config) => config.toJson(),
);

/// Type converter for [TriggerConfig] stored as JSON text.
final JsonTypeConverter2<TriggerConfig, String, Object?>
triggerConfigConverter = TypeConverter.json2(
  fromJson: (json) =>
      TriggerConfig.fromJson(_parseJsonWithDoubleEncodingFallback(json)),
  toJson: (TriggerConfig config) => config.toJson(),
);

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

/// Type converter for [ContentConfig] stored as JSON text.
///
/// ContentConfig combines sections and support blocks into a single blob.
final JsonTypeConverter2<ContentConfig, String, Object?>
contentConfigConverter = TypeConverter.json2(
  fromJson: (json) {
    if (json == null) return ContentConfig.empty;
    final map = _parseJsonWithDoubleEncodingFallback(json);
    return ContentConfig.fromJson(map);
  },
  toJson: (ContentConfig config) => config.toJson(),
);

/// Type converter for [ActionsConfig] stored as JSON text.
///
/// ActionsConfig combines FAB operations, AppBar actions, and settings route.
final JsonTypeConverter2<ActionsConfig, String, Object?>
actionsConfigConverter = TypeConverter.json2(
  fromJson: (json) {
    if (json == null) return ActionsConfig.empty;
    final map = _parseJsonWithDoubleEncodingFallback(json);
    return ActionsConfig.fromJson(map);
  },
  toJson: (ActionsConfig config) => config.toJson(),
);
