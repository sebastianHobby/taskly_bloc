import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';

/// A single, filterable request for attention items.
///
/// This is the main entrypoint for screens/sections.
class AttentionQuery {
  const AttentionQuery({
    this.entityTypes,
    this.minSeverity,
    this.buckets,
  });

  /// Limit to these entity types.
  final Set<AttentionEntityType>? entityTypes;

  /// Only include items with severity >= minSeverity.
  final AttentionSeverity? minSeverity;

  /// Limit to these buckets (Action/Review).
  final Set<AttentionBucket>? buckets;

  bool matchesRule(AttentionRule rule) {
    if (buckets != null && !buckets!.contains(rule.bucket)) return false;
    return true;
  }
}
