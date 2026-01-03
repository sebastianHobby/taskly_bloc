import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
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

/// Type converter for `List<Section>` stored as JSON text.
final JsonTypeConverter2<List<Section>, String, Object?>
sectionsConfigConverter = TypeConverter.json2(
  fromJson: (json) {
    final list = _parseJsonListWithDoubleEncodingFallback(json);
    return list.map(Section.fromJson).toList();
  },
  toJson: (List<Section> sections) =>
      sections.map((section) => section.toJson()).toList(),
);

/// Type converter for `List<SupportBlock>` stored as JSON text.
final JsonTypeConverter2<List<SupportBlock>, String, Object?>
supportBlocksConfigConverter = TypeConverter.json2(
  fromJson: (json) {
    final list = _parseJsonListWithDoubleEncodingFallback(json);
    return list.map(SupportBlock.fromJson).toList();
  },
  toJson: (List<SupportBlock> blocks) =>
      blocks.map((block) => block.toJson()).toList(),
);

/// Handles potentially double-encoded JSON list data.
List<Map<String, dynamic>> _parseJsonListWithDoubleEncodingFallback(
  Object? json,
) {
  if (json == null) {
    return [];
  }
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().toList();
  }
  if (json is String) {
    final decoded = jsonDecode(json);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
  return [];
}
