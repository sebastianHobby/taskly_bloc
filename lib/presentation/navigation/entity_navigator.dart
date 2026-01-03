import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';

/// Centralized navigation for entities (DR-007, DR-010).
/// Provides consistent navigation behavior across all entity widgets.
class EntityNavigator {
  /// Navigate to task detail/edit screen
  static void toTask(BuildContext context, String taskId) {
    context.push('/tasks/$taskId');
  }

  /// Navigate to task with entity object
  static void toTaskEntity(BuildContext context, Task task) {
    toTask(context, task.id);
  }

  /// Navigate to project detail screen
  static void toProject(BuildContext context, String projectId) {
    context.push('/projects/$projectId');
  }

  /// Navigate to project with entity object
  static void toProjectEntity(BuildContext context, Project project) {
    toProject(context, project.id);
  }

  /// Navigate to label detail screen
  static void toLabel(BuildContext context, String labelId) {
    context.push('${AppRoutePath.labels}/$labelId');
  }

  /// Navigate to label with entity object
  static void toLabelEntity(BuildContext context, Label label) {
    toLabel(context, label.id);
  }

  /// Navigate to value (label with type=value) detail screen
  static void toValue(BuildContext context, String valueId) {
    context.push('${AppRoutePath.values}/$valueId');
  }

  /// Navigate to any entity by type and ID
  static void toEntity(
    BuildContext context, {
    required String entityId,
    required String entityType,
  }) {
    switch (entityType) {
      case 'task':
        toTask(context, entityId);
      case 'project':
        toProject(context, entityId);
      case 'label':
        toLabel(context, entityId);
      case 'value':
        toValue(context, entityId);
      default:
        debugPrint('Unknown entity type: $entityType');
    }
  }

  /// Navigate to a screen by screen ID
  static void toScreen(BuildContext context, String screenId) {
    context.push('${AppRoutePath.screenBase}/$screenId');
  }

  /// Get the default onTap handler for an entity
  static VoidCallback? getDefaultOnTap(
    BuildContext context, {
    required String entityId,
    required String entityType,
  }) {
    return () => toEntity(
      context,
      entityId: entityId,
      entityType: entityType,
    );
  }
}
