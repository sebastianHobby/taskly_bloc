import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/domain/models/screens/completion_criteria.dart';

part 'screen_definition.freezed.dart';
part 'screen_definition.g.dart';

/// Sealed class for screen definitions - both collection and workflow screens
@freezed
abstract class ScreenDefinition with _$ScreenDefinition {
  /// Static collection view (Today, Inbox, Upcoming, Next Actions)
  const factory ScreenDefinition.collection({
    required String id,
    required String userId,
    required String screenId, // Unique like 'today', 'inbox'
    required String name,
    required EntitySelector selector,
    required DisplayConfig display,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? iconName,
    @Default(false) bool isSystem,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
  }) = CollectionScreen;

  /// Per-item workflow with progress tracking
  const factory ScreenDefinition.workflow({
    required String id,
    required String userId,
    required String screenId,
    required String name,
    required EntitySelector selector,
    required DisplayConfig display,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? iconName,
    @Default(false) bool isSystem,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
    TriggerConfig? trigger,
    CompletionCriteria? completionCriteria,
  }) = WorkflowScreen;

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) =>
      _$ScreenDefinitionFromJson(json);
}
