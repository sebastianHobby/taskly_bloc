import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/fab_operation.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';

part 'screen_definition.freezed.dart';

/// Type of data-driven screen rendering
enum ScreenType {
  /// Entity list with DataSection/AgendaSection
  @JsonValue('list')
  list,

  /// Allocation-focused (uses AllocationSection)
  @JsonValue('focus')
  focus,

  /// Multi-step workflow execution
  @JsonValue('workflow')
  workflow,
}

/// A screen definition describing a navigable screen in the app.
///
/// Sealed hierarchy with two variants:
/// - [DataDrivenScreenDefinition]: Screens with sections, rendered by UnifiedScreenPage
/// - [NavigationOnlyScreenDefinition]: Navigation metadata only, custom widget rendering
///
/// Type is inferred from data shape during deserialization:
/// - Empty/missing sections → NavigationOnlyScreenDefinition
/// - Non-empty sections → DataDrivenScreenDefinition
@Freezed(unionKey: 'runtimeType')
sealed class ScreenDefinition with _$ScreenDefinition {
  const ScreenDefinition._();

  /// Data-driven screen with sections for unified rendering.
  ///
  /// Used for: Inbox, Today, Upcoming, Projects, Labels, Values, Next Actions
  const factory ScreenDefinition.dataDriven({
    required String id,
    required String screenKey,
    required String name,
    required ScreenType screenType,

    /// Audit fields
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Sections that make up the screen (DR-017)
    @Default([]) List<Section> sections,

    /// Support blocks (problem indicators, navigation, etc.)
    @Default([]) List<SupportBlock> supportBlocks,

    /// Icon for display in navigation
    String? iconName,

    /// Whether this is a system-provided screen
    @Default(false) bool isSystem,

    /// Screen category
    @Default(ScreenCategory.workspace) ScreenCategory category,

    /// Screen-level trigger (workflows only)
    TriggerConfig? triggerConfig,

    /// FAB operations available on this screen.
    @Default([]) List<FabOperation> fabOperations,
  }) = DataDrivenScreenDefinition;

  /// Navigation-only screen for custom widget rendering.
  ///
  /// Used for: Settings, Wellbeing Dashboard, Journal, Trackers
  /// These screens appear in navigation but have custom widget implementations.
  const factory ScreenDefinition.navigationOnly({
    required String id,
    required String screenKey,
    required String name,

    /// Audit fields
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Icon for display in navigation
    String? iconName,

    /// Whether this is a system-provided screen
    @Default(false) bool isSystem,

    /// Screen category
    @Default(ScreenCategory.workspace) ScreenCategory category,
  }) = NavigationOnlyScreenDefinition;

  /// Custom deserialization: infer type from sections presence.
  ///
  /// - Empty or missing sections → NavigationOnlyScreenDefinition
  /// - Non-empty sections → DataDrivenScreenDefinition
  factory ScreenDefinition.fromJson(Map<String, dynamic> json) {
    final sections = json['sections'];
    final hasContent =
        sections != null && sections is List && sections.isNotEmpty;

    if (hasContent) {
      return DataDrivenScreenDefinition(
        id: json['id'] as String,
        screenKey: json['screenKey'] as String? ?? json['screen_key'] as String,
        name: json['name'] as String,
        screenType: _parseScreenType(json['screenType'] ?? json['screen_type']),
        createdAt: DateTime.parse(
          json['createdAt'] as String? ?? json['created_at'] as String,
        ),
        updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? json['updated_at'] as String,
        ),
        sections: sections
            .map((e) => Section.fromJson(e as Map<String, dynamic>))
            .toList(),
        supportBlocks:
            (json['supportBlocks'] as List? ??
                    json['support_blocks'] as List? ??
                    [])
                .map((e) => SupportBlock.fromJson(e as Map<String, dynamic>))
                .toList(),
        iconName: json['iconName'] as String? ?? json['icon_name'] as String?,
        isSystem:
            json['isSystem'] as bool? ?? json['is_system'] as bool? ?? false,
        category: _parseCategory(json['category']),
        triggerConfig: json['triggerConfig'] != null
            ? TriggerConfig.fromJson(
                json['triggerConfig'] as Map<String, dynamic>,
              )
            : json['trigger_config'] != null
            ? TriggerConfig.fromJson(
                json['trigger_config'] as Map<String, dynamic>,
              )
            : null,
        fabOperations:
            (json['fabOperations'] as List? ??
                    json['fab_operations'] as List? ??
                    [])
                .map(
                  (e) => FabOperation.values.firstWhere(
                    (op) => op.name == e || op.toString() == e,
                    orElse: () => FabOperation.createTask,
                  ),
                )
                .toList(),
      );
    }

    return NavigationOnlyScreenDefinition(
      id: json['id'] as String,
      screenKey: json['screenKey'] as String? ?? json['screen_key'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String,
      ),
      iconName: json['iconName'] as String? ?? json['icon_name'] as String?,
      isSystem:
          json['isSystem'] as bool? ?? json['is_system'] as bool? ?? false,
      category: _parseCategory(json['category']),
    );
  }

  static ScreenType _parseScreenType(dynamic value) {
    if (value == null) return ScreenType.list;
    if (value is ScreenType) return value;
    final str = value.toString().toLowerCase();
    return switch (str) {
      'focus' => ScreenType.focus,
      'workflow' => ScreenType.workflow,
      _ => ScreenType.list,
    };
  }

  static ScreenCategory _parseCategory(dynamic value) {
    if (value == null) return ScreenCategory.workspace;
    if (value is ScreenCategory) return value;
    final str = value.toString().toLowerCase();
    return switch (str) {
      'wellbeing' => ScreenCategory.wellbeing,
      'settings' => ScreenCategory.settings,
      _ => ScreenCategory.workspace,
    };
  }

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => switch (this) {
    final DataDrivenScreenDefinition d => {
      'id': d.id,
      'screenKey': d.screenKey,
      'name': d.name,
      'screenType': d.screenType.name,
      'createdAt': d.createdAt.toIso8601String(),
      'updatedAt': d.updatedAt.toIso8601String(),
      'sections': d.sections.map((s) => s.toJson()).toList(),
      'supportBlocks': d.supportBlocks.map((s) => s.toJson()).toList(),
      'iconName': d.iconName,
      'isSystem': d.isSystem,
      'category': d.category.name,
      'triggerConfig': d.triggerConfig?.toJson(),
      'fabOperations': d.fabOperations.map((f) => f.name).toList(),
    },
    final NavigationOnlyScreenDefinition n => {
      'id': n.id,
      'screenKey': n.screenKey,
      'name': n.name,
      'createdAt': n.createdAt.toIso8601String(),
      'updatedAt': n.updatedAt.toIso8601String(),
      'iconName': n.iconName,
      'isSystem': n.isSystem,
      'category': n.category.name,
      'sections': <dynamic>[],
    },
  };
}
