import 'dart:convert';

import 'package:flutter/foundation.dart';

enum UploadJsonExpectation {
  map,
  list,
  any,
}

/// Upload-time JSON/array expectations for Supabase columns.
///
/// Only includes columns that are `json`, `jsonb`, or array types in Supabase.
///
/// PowerSync stores these as TEXT locally, so we decode JSON strings back into
/// structured values before sending to PostgREST.
final Map<String, Map<String, UploadJsonExpectation>>
uploadJsonExpectationsByTable = {
  'user_profiles': {
    'settings_overrides': UploadJsonExpectation.map,
  },
  'attention_rules': {
    // Legacy attention rule schema columns.
    'trigger_config': UploadJsonExpectation.map,
    'entity_selector': UploadJsonExpectation.map,
    'evaluator_params': UploadJsonExpectation.map,
    'display_config': UploadJsonExpectation.map,
    // Supabase: text[] (PostgREST expects a JSON array)
    'resolution_actions': UploadJsonExpectation.list,
  },
  'pending_notifications': {
    'payload': UploadJsonExpectation.any,
  },
  'tracker_definitions': {
    // Supabase: text[] (PostgREST expects a JSON array)
    'roles': UploadJsonExpectation.list,
    // Supabase: jsonb
    'config': UploadJsonExpectation.map,
    'goal': UploadJsonExpectation.map,
  },
  'tracker_events': {
    // Supabase: jsonb
    'value': UploadJsonExpectation.any,
  },
  'tracker_state_day': {
    // Supabase: jsonb
    'value': UploadJsonExpectation.any,
  },
  'tracker_state_entry': {
    // Supabase: jsonb
    'value': UploadJsonExpectation.any,
  },
  'analytics_snapshots': {
    'metrics': UploadJsonExpectation.map,
  },
  'analytics_insights': {
    'metadata': UploadJsonExpectation.map,
  },
  'analytics_correlations': {
    // Supabase: jsonb
    'performance_metrics': UploadJsonExpectation.map,
    'statistical_significance': UploadJsonExpectation.map,
  },
  'my_day_picks': {
    // Supabase: jsonb/text[] (PostgREST expects a JSON array)
    'reason_codes': UploadJsonExpectation.list,
  },
  'routines': {
    // Supabase: int[] (PostgREST expects a JSON array)
    'schedule_days': UploadJsonExpectation.list,
    'preferred_weeks': UploadJsonExpectation.list,
  },
};

String _previewForLog(Object? value, {int maxChars = 200}) {
  if (value == null) return '<null>';
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars)}…';
  }

  try {
    final encoded = jsonEncode(value);
    if (encoded.length <= maxChars) return encoded;
    return '${encoded.substring(0, maxChars)}…';
  } catch (_) {
    final stringified = value.toString();
    if (stringified.length <= maxChars) return stringified;
    return '${stringified.substring(0, maxChars)}…';
  }
}

({Object? value, bool changed, bool doubleEncoded}) tryDecodeJsonValue(
  Object? value,
) {
  if (value is! String) {
    return (value: value, changed: false, doubleEncoded: false);
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return (value: value, changed: false, doubleEncoded: false);
  }

  // Fast-path: only attempt JSON decode when it looks like JSON.
  final first = trimmed.codeUnitAt(0);
  final looksLikeJson =
      first == 0x7B /* { */ ||
      first == 0x5B /* [ */ ||
      first == 0x22 /* " */ ||
      trimmed == 'null' ||
      trimmed == 'true' ||
      trimmed == 'false' ||
      RegExp(r'^-?\d').hasMatch(trimmed);
  if (!looksLikeJson) {
    return (value: value, changed: false, doubleEncoded: false);
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is String) {
      // Handle "{...}" / "[...]" (double-encoded) cases.
      try {
        final decodedTwice = jsonDecode(decoded);
        return (value: decodedTwice, changed: true, doubleEncoded: true);
      } catch (_) {
        final changed = decoded != value;
        return (value: decoded, changed: changed, doubleEncoded: false);
      }
    }
    return (value: decoded, changed: true, doubleEncoded: false);
  } catch (_) {
    return (value: value, changed: false, doubleEncoded: false);
  }
}

bool _matchesExpectation(Object? value, UploadJsonExpectation expectation) {
  if (value == null) return true;

  return switch (expectation) {
    UploadJsonExpectation.map => value is Map,
    UploadJsonExpectation.list => value is List,
    UploadJsonExpectation.any =>
      value is Map ||
          value is List ||
          value is num ||
          value is bool ||
          value is String,
  };
}

Map<String, dynamic> normalizeUploadData({
  required String table,
  required String rowId,
  required Object opType,
  required Map<String, dynamic> data,
  void Function(String message)? logError,
}) {
  final columnExpectations = uploadJsonExpectationsByTable[table];
  if (columnExpectations == null || columnExpectations.isEmpty) return data;

  final normalized = Map<String, dynamic>.of(data);
  for (final entry in columnExpectations.entries) {
    final column = entry.key;
    final expectation = entry.value;
    if (!normalized.containsKey(column)) continue;

    final before = normalized[column];
    final result = tryDecodeJsonValue(before);
    final decoded = result.value;
    normalized[column] = decoded;

    final ok = _matchesExpectation(decoded, expectation);
    if (!ok) {
      final message =
          '[powersync] Upload JSON field has wrong type\n'
          '  table=$table\n'
          '  id=$rowId\n'
          '  op=$opType\n'
          '  column=$column\n'
          '  expected=$expectation\n'
          '  doubleEncoded=${result.doubleEncoded}\n'
          '  beforeType=${before.runtimeType}\n'
          '  afterType=${decoded.runtimeType}\n'
          '  before=${_previewForLog(before)}\n'
          '  after=${_previewForLog(decoded)}';

      // Crash in debug to surface bugs early.
      if (kDebugMode) {
        throw StateError(message);
      }

      logError?.call(message);
    }
  }

  return normalized;
}
