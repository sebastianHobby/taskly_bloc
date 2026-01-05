import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/presentation/features/screens/view/unified_screen_page.dart';

/// Single source of truth for navigation conventions and screen building.
///
/// All URL path building, navigation, and screen construction is centralized here.
/// Consumers should never construct paths manually or define routes elsewhere.
///
/// ## Route Patterns
///
/// Only two route patterns exist:
/// - **Screens**: `/:screenKey` → convention-based, handled by [buildScreen]
/// - **Entities**: `/:entityType/:id` → parameterized, handled by [buildEntityDetail]
///
/// Screen paths use convention: `screenKey` → `/${screenKey}` with
/// underscores converted to hyphens (e.g., `orphan_tasks` → `/orphan-tasks`).
///
/// Entity paths use convention: `/${entityType}/${id}`
/// (e.g., `/task/abc-123`, `/project/xyz-456`).
///
/// ## Initialization
///
/// Call [registerScreenBuilders] and [registerEntityBuilders] at app startup
/// (in bootstrap.dart) to inject bloc factories and dependencies.
abstract final class Routing {
  // === PATH UTILITIES ===

  /// Get screen route path for building navigation destinations.
  static String screenPath(String screenKey) =>
      '/${screenKey.replaceAll('_', '-')}';

  /// Parse URL segment back to screenKey.
  static String parseScreenKey(String segment) => segment.replaceAll('-', '_');

  /// Entity types that have detail pages.
  static const entityTypes = {'task', 'project', 'value'};

  /// Check if a path segment is an entity type (not a screen).
  static bool isEntityType(String segment) => entityTypes.contains(segment);

  // === SCREEN NAVIGATION ===

  /// Navigate to screen (replaces current view in nav stack).
  static void toScreen(BuildContext context, ScreenDefinition screen) =>
      GoRouter.of(context).go(screenPath(screen.screenKey));

  /// Navigate to screen by key (when definition is unavailable).
  static void toScreenKey(BuildContext context, String screenKey) =>
      GoRouter.of(context).go(screenPath(screenKey));

  // === ENTITY NAVIGATION (typed) ===

  /// Navigate to task detail (pushes onto nav stack).
  static void toTask(BuildContext context, Task task) =>
      GoRouter.of(context).push('/task/${task.id}');

  /// Navigate to project detail (pushes onto nav stack).
  static void toProject(BuildContext context, Project project) =>
      GoRouter.of(context).push('/project/${project.id}');

  /// Navigate to value detail (pushes onto nav stack).
  static void toValue(BuildContext context, Value value) =>
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

  // === SCREEN BUILDERS ===

  /// Custom screen builders for screens that need specific blocs or DI.
  /// Key: screenKey, Value: builder function.
  /// Screens NOT in this map use [UnifiedScreenPage].
  static final Map<String, Widget Function()> _screenBuilders = {};

  /// Register custom screen builders at app startup.
  ///
  /// Called once from bootstrap.dart after DI is initialized.
  /// Only screens that need custom blocs or DI should be registered here.
  /// All other screens automatically use [UnifiedScreenPage].
  static void registerScreenBuilders(
    Map<String, Widget Function()> builders,
  ) {
    _screenBuilders
      ..clear()
      ..addAll(builders);
  }

  /// Build a screen widget by screenKey.
  ///
  /// Uses custom builder if registered, otherwise [UnifiedScreenPage].
  /// This is the single entry point for all screen construction.
  static Widget buildScreen(String screenKey) {
    // Check for custom builder first (screens with blocs/DI)
    final builder = _screenBuilders[screenKey];
    if (builder != null) {
      return builder();
    }

    // Default: data-driven unified screen
    final systemScreen = SystemScreenDefinitions.getByKey(screenKey);
    if (systemScreen != null) {
      return UnifiedScreenPage(
        key: ValueKey('screen_$screenKey'),
        definition: systemScreen,
      );
    }

    // User-defined screen from repository
    return UnifiedScreenPageById(
      key: ValueKey('screen_$screenKey'),
      screenId: screenKey,
    );
  }

  // === ENTITY BUILDERS ===

  static Widget Function(String id)? _taskDetailBuilder;
  static Widget Function(String id)? _projectDetailBuilder;
  static Widget Function(String id)? _labelDetailBuilder;

  /// Register entity detail builders at app startup.
  ///
  /// Called once from bootstrap.dart after DI is initialized.
  static void registerEntityBuilders({
    required Widget Function(String id) taskBuilder,
    required Widget Function(String id) projectBuilder,
    required Widget Function(String id) labelBuilder,
  }) {
    _taskDetailBuilder = taskBuilder;
    _projectDetailBuilder = projectBuilder;
    _labelDetailBuilder = labelBuilder;
  }

  /// Build an entity detail widget by type and ID.
  ///
  /// This is the single entry point for all entity detail construction.
  static Widget buildEntityDetail(String entityType, String id) {
    return switch (entityType) {
      'task' => _taskDetailBuilder?.call(id) ?? _notRegisteredError('task'),
      'project' =>
        _projectDetailBuilder?.call(id) ?? _notRegisteredError('project'),
      'label' ||
      'value' => _labelDetailBuilder?.call(id) ?? _notRegisteredError('label'),
      _ => Center(child: Text('Unknown entity type: $entityType')),
    };
  }

  static Widget _notRegisteredError(String type) {
    return Center(
      child: Text(
        'Entity builder not registered for $type. '
        'Call Routing.registerEntityBuilders() in bootstrap.',
      ),
    );
  }

  /// Reset all registered builders. Used for testing.
  @visibleForTesting
  static void reset() {
    _screenBuilders.clear();
    _taskDetailBuilder = null;
    _projectDetailBuilder = null;
    _labelDetailBuilder = null;
  }
}
