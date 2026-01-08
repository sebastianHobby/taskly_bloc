import 'package:taskly_bloc/domain/models/attention/attention_item.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';

/// Shared attention context for a screen
///
/// Provides cross-section awareness of which entities have active attention.
/// Computed once by ScreenDataInterpreter and shared across all sections.
class AttentionContext {
  const AttentionContext({
    required this.entityAttentionMap,
    required this.allItems,
    required this.problemItems,
    required this.reviewItems,
    required this.allocationItems,
  });

  /// Empty context (no attention items)
  factory AttentionContext.empty() {
    return const AttentionContext(
      entityAttentionMap: {},
      allItems: [],
      problemItems: [],
      reviewItems: [],
      allocationItems: [],
    );
  }

  /// Create from a list of attention items
  factory AttentionContext.fromItems(List<AttentionItem> items) {
    final entityMap = <String, List<AttentionItem>>{};
    final problems = <AttentionItem>[];
    final reviews = <AttentionItem>[];
    final allocations = <AttentionItem>[];

    for (final item in items) {
      // Group by entity
      entityMap.putIfAbsent(item.entityId, () => []).add(item);

      // Categorize by type
      switch (item.ruleType) {
        case AttentionRuleType.problem:
          problems.add(item);
        case AttentionRuleType.review:
          reviews.add(item);
        case AttentionRuleType.allocationWarning:
          allocations.add(item);
        case AttentionRuleType.workflowStep:
          // Workflow steps are handled separately
          break;
      }
    }

    return AttentionContext(
      entityAttentionMap: entityMap,
      allItems: items,
      problemItems: problems,
      reviewItems: reviews,
      allocationItems: allocations,
    );
  }

  /// Map of entity ID → active attention items for that entity
  final Map<String, List<AttentionItem>> entityAttentionMap;

  /// All attention items (unfiltered)
  final List<AttentionItem> allItems;

  /// Problem items only (for issuesSummary block)
  final List<AttentionItem> problemItems;

  /// Review items only (for checkInSummary block)
  final List<AttentionItem> reviewItems;

  /// Allocation warning items only (for allocationAlerts block)
  final List<AttentionItem> allocationItems;

  /// Check if entity has any active attention
  bool hasAttention(String entityId) {
    return entityAttentionMap.containsKey(entityId) &&
        entityAttentionMap[entityId]!.isNotEmpty;
  }

  /// Get highest severity for an entity
  AttentionSeverity? getHighestSeverity(String entityId) {
    final items = entityAttentionMap[entityId];
    if (items == null || items.isEmpty) return null;

    // critical > warning > info
    if (items.any((i) => i.severity == AttentionSeverity.critical)) {
      return AttentionSeverity.critical;
    }
    if (items.any((i) => i.severity == AttentionSeverity.warning)) {
      return AttentionSeverity.warning;
    }
    return AttentionSeverity.info;
  }

  /// Get attention count for entity
  int getCount(String entityId) {
    return entityAttentionMap[entityId]?.length ?? 0;
  }

  /// Get items for entity
  List<AttentionItem> getItems(String entityId) {
    return entityAttentionMap[entityId] ?? [];
  }

  /// Total counts by category
  int get totalProblems => problemItems.length;
  int get totalReviews => reviewItems.length;
  int get totalAllocations => allocationItems.length;
  int get totalItems => allItems.length;
}
