import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Single source of truth for navigation conventions.
///
/// All URL path building and navigation is centralized here.
/// Consumers should never construct paths manually.
///
/// Screen paths use convention: `screenKey` → `/${screenKey}` with
/// underscores converted to hyphens (e.g., `orphan_tasks` → `/orphan-tasks`).
///
/// Entity paths use convention: `/${entityType}/${id}`
/// (e.g., `/task/abc-123`, `/project/xyz-456`).
abstract final class Routing {
  // === SCREEN NAVIGATION ===

  /// Navigate to screen (replaces current view in nav stack).
  static void toScreen(BuildContext context, ScreenDefinition screen) =>
      GoRouter.of(context).go(screenPath(screen.screenKey));

  /// Navigate to screen by key (when definition is unavailable).
  static void toScreenKey(BuildContext context, String screenKey) =>
      GoRouter.of(context).go(screenPath(screenKey));

  /// Get screen route path for building navigation destinations.
  static String screenPath(String screenKey) =>
      '/${screenKey.replaceAll('_', '-')}';

  /// Parse URL segment back to screenKey.
  static String parseScreenKey(String segment) => segment.replaceAll('-', '_');

  // === ENTITY NAVIGATION (typed) ===

  /// Navigate to task detail (pushes onto nav stack).
  static void toTask(BuildContext context, Task task) =>
      GoRouter.of(context).push('/task/${task.id}');

  /// Navigate to project detail (pushes onto nav stack).
  static void toProject(BuildContext context, Project project) =>
      GoRouter.of(context).push('/project/${project.id}');

  /// Navigate to label detail (pushes onto nav stack).
  static void toLabel(BuildContext context, Label label) =>
      GoRouter.of(context).push('/label/${label.id}');

  /// Navigate to value detail (pushes onto nav stack).
  static void toValue(BuildContext context, Label value) =>
      GoRouter.of(context).push('/value/${value.id}');

  // === ENTITY NAVIGATION (generic) ===

  /// Navigate to entity detail by type and ID.
  /// Use when you only have the ID, not the full domain object.
  static void toEntity(BuildContext context, EntityType type, String id) =>
      GoRouter.of(context).push('/${type.urlSegment}/$id');

  /// Get onTap callback for entity navigation.
  static VoidCallback onTapEntity(
    BuildContext context,
    EntityType type,
    String id,
  ) =>
      () => toEntity(context, type, id);
}
