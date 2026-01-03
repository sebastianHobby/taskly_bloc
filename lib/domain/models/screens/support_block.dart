import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_block.freezed.dart';
part 'support_block.g.dart';

/// Support blocks provide auxiliary UI elements for screens (DR-018, DR-019).
/// These are rendered in a designated support section, typically above or beside main content.
@Freezed(unionKey: 'type')
sealed class SupportBlock with _$SupportBlock {
  /// Shows workflow step progress (system-only per DR-019)
  @FreezedUnionValue('workflowProgress')
  const factory SupportBlock.workflowProgress({
    @Default(0) int order,
  }) = WorkflowProgressBlock;

  /// Shows quick action buttons
  @FreezedUnionValue('quickActions')
  const factory SupportBlock.quickActions({
    required List<QuickAction> actions,
    @Default(0) int order,
  }) = QuickActionsBlock;

  /// Shows context/project information summary
  @FreezedUnionValue('contextSummary')
  const factory SupportBlock.contextSummary({
    String? title,
    @Default(true) bool showDescription,
    @Default(true) bool showMetadata,
    @Default(0) int order,
  }) = ContextSummaryBlock;

  /// Shows related entities as links/chips
  @FreezedUnionValue('relatedEntities')
  const factory SupportBlock.relatedEntities({
    required List<String> entityTypes,
    @Default(5) int maxItems,
    @Default(0) int order,
  }) = RelatedEntitiesBlock;

  /// Shows statistics/metrics
  @FreezedUnionValue('stats')
  const factory SupportBlock.stats({
    required List<StatConfig> stats,
    @Default(0) int order,
  }) = StatsBlock;

  /// Shows a summary of detected problems (DR-018)
  @FreezedUnionValue('problemSummary')
  const factory SupportBlock.problemSummary({
    List<String>? problemTypes,
    @Default(true) bool showCount,
    @Default(false) bool showList,
    @Default(5) int maxListItems,
    String? title,
    @Default(0) int order,
  }) = ProblemSummaryBlock;

  /// Shows a custom empty state message
  @FreezedUnionValue('emptyState')
  const factory SupportBlock.emptyState({
    required String message,
    String? icon,
    String? actionLabel,
    String? actionRoute,
    @Default(0) int order,
  }) = EmptyStateBlock;

  /// Shows entity header for detail pages (project/label info)
  @FreezedUnionValue('entityHeader')
  const factory SupportBlock.entityHeader({
    required String entityType,
    required String entityId,
    @Default(true) bool showCheckbox,
    @Default(true) bool showMetadata,
    @Default(0) int order,
  }) = EntityHeaderBlock;

  factory SupportBlock.fromJson(Map<String, dynamic> json) =>
      _$SupportBlockFromJson(json);
}

/// A quick action button configuration
@freezed
abstract class QuickAction with _$QuickAction {
  const factory QuickAction({
    required String label,
    required String actionId,
    String? icon,
    Map<String, dynamic>? params,
  }) = _QuickAction;

  factory QuickAction.fromJson(Map<String, dynamic> json) =>
      _$QuickActionFromJson(json);
}

/// A statistic configuration
@freezed
abstract class StatConfig with _$StatConfig {
  const factory StatConfig({
    required String label,
    required String metricId,
    String? format,
    String? icon,
  }) = _StatConfig;

  factory StatConfig.fromJson(Map<String, dynamic> json) =>
      _$StatConfigFromJson(json);
}

/// Extension methods for SupportBlock
extension SupportBlockExtensions on SupportBlock {
  /// Whether this block type can only be added by the system (DR-019).
  bool get isSystemOnly => switch (this) {
    WorkflowProgressBlock() => true,
    _ => false,
  };

  /// Whether this block type is available in the screen builder UI.
  bool get isUserConfigurable => !isSystemOnly;
}
