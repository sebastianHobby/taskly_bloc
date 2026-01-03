import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';

part 'screen_definition.freezed.dart';
part 'screen_definition.g.dart';

/// Type of screen
enum ScreenType {
  @JsonValue('list')
  list,
  @JsonValue('dashboard')
  dashboard,
  @JsonValue('focus')
  focus,
  @JsonValue('workflow')
  workflow,
}

/// A screen definition describing layout, sections, and support blocks.
@freezed
abstract class ScreenDefinition with _$ScreenDefinition {
  const factory ScreenDefinition({
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

    /// Whether the screen is active/visible
    @Default(true) bool isActive,

    /// Display order in navigation
    @Default(0) int sortOrder,

    /// Screen category
    @Default(ScreenCategory.workspace) ScreenCategory category,

    /// Screen-level trigger (workflows only)
    TriggerConfig? triggerConfig,
  }) = _ScreenDefinition;

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) =>
      _$ScreenDefinitionFromJson(json);
}
