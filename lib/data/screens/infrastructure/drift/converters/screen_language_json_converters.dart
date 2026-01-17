import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/domain/screens/language/models/actions_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/content_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/entity_selector.dart';
import 'package:taskly_bloc/domain/screens/language/models/trigger_config.dart';

Object? _decodePossiblyDoubleEncodedJson(String json) {
  final decoded = jsonDecode(json);

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
