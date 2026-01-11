import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';

/// A single, filterable request for attention items.
///
/// This is the main entrypoint for screens/sections.
class AttentionQuery {
  const AttentionQuery({
    this.entityTypes,
    this.minSeverity,
    this.domains,
    this.categories,
  });

  /// Limit to these entity types.
  final Set<AttentionEntityType>? entityTypes;

  /// Only include items with severity >= minSeverity.
  final AttentionSeverity? minSeverity;

  /// Stable grouping axis from the rule (e.g. "issues", "review", "allocation").
  final Set<String>? domains;

  /// Stable grouping axis from the rule (sub-category).
  final Set<String>? categories;

  bool matchesRule(AttentionRule rule) {
    if (domains != null && !domains!.contains(rule.domain)) return false;
    if (categories != null && !categories!.contains(rule.category)) {
      return false;
    }
    return true;
  }
}
