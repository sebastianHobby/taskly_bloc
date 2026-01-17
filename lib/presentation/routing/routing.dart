import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_spec_page.dart';

/// Single source of truth for navigation conventions and screen building.
///
/// All URL path building, navigation, and screen construction is centralized here.
/// Consumers should never construct paths manually.
///
/// ## Route Patterns
///
/// The app uses convention-based routing with a small set of patterns:
///
/// - **System screens (explicit)**: concrete paths like `/my-day`, `/anytime`,
///   `/scheduled`, etc. → handled by [buildScreen]
///   - URL segments use hyphens (`my_day` ? `/my-day`).
///   - The canonical Anytime URL segment is `anytime`, which maps to the
///     legacy system screen key `someday`.
/// - **Entity detail (read/composite)**: `/<entityType>/:id`
///   - Currently supported for `project` and `value`.
/// - **Entity editors (NAV-01)**: `/<entityType>/new` and `/<entityType>/:id/edit`
///   - Tasks are editor-only: `/task/:id` redirects to `/task/:id/edit`.
/// - **Journal entry editor**: `/journal/entry/new` and `/journal/entry/:id/edit`
///
/// Screen paths use convention: `screenKey` ? `/${screenKey}` with
/// underscores converted to hyphens (e.g., `my_day` ? `/my-day`).
///
/// Entity paths use convention: `/${entityType}/${id}`
/// (e.g., `/project/xyz-456`, `/value/xyz-456`).
///
/// ## Initialization
///
/// Call [registerEntityBuilders] at app startup (in bootstrap.dart)
/// to inject bloc factories and dependencies.
abstract final class Routing {
  // === PATH UTILITIES ===

  /// Get screen route path for building navigation destinations.
  static String screenPath(String screenKey) {
    // Canonical path alias: 'someday' has been renamed to the Anytime concept
    // while keeping the underlying screenKey stable.
    if (screenKey == 'someday') return '/anytime';
    return '/${screenKey.replaceAll('_', '-')}';
  }

  /// Parse URL segment back to screenKey.
  static String parseScreenKey(String segment) {
    // Alias: '/anytime' maps to the legacy 'someday' system screen key.
    if (segment == 'anytime') return 'someday';
    return segment.replaceAll('-', '_');
  }

  /// Returns true when [screenKey] maps to a known typed system screen.
  ///
  /// This is used by the authenticated app shell to decide whether a location
  /// should count as an active navigation destination.
  static const Set<String> _navigationScreenKeys = {
    'my_day',
    'inbox',
    'scheduled',
    'someday',
    'journal',
    'values',
    'review_inbox',
    'settings',
  };

  static bool isSystemScreenKey(String screenKey) =>
      _navigationScreenKeys.contains(screenKey.replaceAll('-', '_'));

  /// Entity route prefixes supported by the router.
  static const entityTypes = {'task', 'project', 'value'};

  /// Check if a path segment is an entity type (not a screen).
  static bool isEntityType(String segment) => entityTypes.contains(segment);

  // === SCREEN NAVIGATION ===

  /// Navigate to screen by key (when definition is unavailable).
  static void toScreenKey(BuildContext context, String screenKey) =>
      GoRouter.of(context).go(screenPath(screenKey));

  /// Push a screen onto the navigation stack.
  ///
  /// Use this for secondary screens that should return back to the current
  /// screen (e.g. Journal History, Manage Trackers).
  static void pushScreenKey(BuildContext context, String screenKey) =>
      GoRouter.of(context).push(screenPath(screenKey));

  /// Navigate to screen by key with query parameters.
  ///
  /// Use this for deep links like `review_inbox?bucket=critical`.
  static void toScreenKeyWithQuery(
    BuildContext context,
    String screenKey, {
    required Map<String, String> queryParameters,
  }) {
    final uri = Uri(
      path: screenPath(screenKey),
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    GoRouter.of(context).go(uri.toString());
  }

  /// Push a screen by key with query parameters.
  static void pushScreenKeyWithQuery(
    BuildContext context,
    String screenKey, {
    required Map<String, String> queryParameters,
  }) {
    final uri = Uri(
      path: screenPath(screenKey),
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    GoRouter.of(context).push(uri.toString());
  }

  // === ENTITY NAVIGATION (typed) ===

  /// Navigate to task detail (pushes onto nav stack).
  static void toTask(BuildContext context, Task task) =>
      GoRouter.of(context).push('/task/${task.id}/edit');

  /// Navigate to project detail (pushes onto nav stack).
  static void toProject(BuildContext context, Project project) =>
      GoRouter.of(context).push('/project/${project.id}');

  /// Navigate to value detail (pushes onto nav stack).
  static void toValue(BuildContext context, Value value) =>
      GoRouter.of(context).push('/value/${value.id}');

  // === ENTITY NAVIGATION (generic) ===

  /// Navigate to entity detail by type and ID.
  /// Use when you only have the ID, not the full domain object.
  static void toEntity(BuildContext context, EntityType type, String id) {
    if (type == EntityType.task) {
      GoRouter.of(context).push('/task/$id/edit');
      return;
    }
    GoRouter.of(context).push('/${type.urlSegment}/$id');
  }

  // === NAV-01 CREATE/EDIT ROUTES (core entities) ===

  static void toTaskNew(
    BuildContext context, {
    String? defaultProjectId,
    String? defaultValueId,
  }) {
    final queryParameters = <String, String>{};
    if (defaultProjectId != null && defaultProjectId.isNotEmpty) {
      queryParameters['projectId'] = defaultProjectId;
    }
    if (defaultValueId != null && defaultValueId.isNotEmpty) {
      queryParameters['valueId'] = defaultValueId;
    }

    final uri = Uri(
      path: '/task/new',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    GoRouter.of(context).push(uri.toString());
  }

  static void toTaskEdit(BuildContext context, String taskId) =>
      GoRouter.of(context).push('/task/$taskId/edit');

  static void toProjectNew(BuildContext context) =>
      GoRouter.of(context).push('/project/new');

  static void toProjectEdit(BuildContext context, String projectId) =>
      GoRouter.of(context).push('/project/$projectId/edit');

  /// Navigate to the global Inbox feed.
  static void toInbox(BuildContext context) =>
      GoRouter.of(context).go('/inbox');

  // === SCOPED FEED ROUTES (MVP) ===

  /// Push the scoped Anytime feed for a project.
  static void pushProjectAnytime(BuildContext context, String projectId) {
    if (projectId.trim().isEmpty) return;
    GoRouter.of(context).push('/project/$projectId/anytime');
  }

  /// Push the scoped Anytime feed for a value.
  static void pushValueAnytime(BuildContext context, String valueId) {
    if (valueId.trim().isEmpty) return;
    GoRouter.of(context).push('/value/$valueId/anytime');
  }

  static void toValueNew(BuildContext context) =>
      GoRouter.of(context).push('/value/new');

  static void toValueEdit(BuildContext context, String valueId) =>
      GoRouter.of(context).push('/value/$valueId/edit');

  // === JOURNAL ENTRY EDITOR ROUTES (Journal Today-first / USM) ===

  static void toJournalEntryNew(
    BuildContext context, {
    Set<String> preselectedTrackerIds = const <String>{},
  }) {
    final trackerIds = preselectedTrackerIds
        .where((id) => id.trim().isNotEmpty)
        .toList();

    final uri = Uri(
      path: '/journal/entry/new',
      queryParameters: trackerIds.isEmpty
          ? null
          : <String, String>{
              'trackerIds': trackerIds.join(','),
            },
    );

    GoRouter.of(context).push(uri.toString());
  }

  static void toJournalEntryEdit(BuildContext context, String entryId) {
    if (entryId.trim().isEmpty) return;
    GoRouter.of(context).push('/journal/entry/$entryId/edit');
  }

  /// Get onTap callback for entity navigation.
  static VoidCallback onTapEntity(
    BuildContext context,
    EntityType type,
    String id,
  ) =>
      () => toEntity(context, type, id);

  /// Build a screen widget by screenKey.
  ///
  /// Uses the typed ScreenSpec rendering path for system screens.
  ///
  /// This is the single entry point for all screen construction.
  static Widget buildScreen(String screenKey) {
    final systemSpec = SystemScreenSpecs.getByKey(screenKey);
    if (systemSpec != null) {
      return UnifiedScreenPageFromSpec(
        key: ValueKey('screen_$screenKey'),
        spec: systemSpec,
      );
    }

    return Center(
      key: ValueKey('screen_not_found_$screenKey'),
      child: Text('Screen not found: $screenKey'),
    );
  }

  // === ENTITY BUILDERS ===

  static Widget Function(String id)? _taskDetailBuilder;
  static Widget Function(String id)? _projectDetailBuilder;
  static Widget Function(String id)? _valueDetailBuilder;

  /// Register entity detail builders at app startup.
  ///
  /// Called once from bootstrap.dart after DI is initialized.
  static void registerEntityBuilders({
    required Widget Function(String id) taskBuilder,
    required Widget Function(String id) projectBuilder,
    required Widget Function(String id) valueBuilder,
  }) {
    _taskDetailBuilder = taskBuilder;
    _projectDetailBuilder = projectBuilder;
    _valueDetailBuilder = valueBuilder;
  }

  /// Build an entity detail widget by type and ID.
  ///
  /// This is the single entry point for all entity detail construction.
  static Widget buildEntityDetail(String entityType, String id) {
    return switch (entityType) {
      'task' => _taskDetailBuilder?.call(id) ?? _notRegisteredError('task'),
      'project' =>
        _projectDetailBuilder?.call(id) ?? _notRegisteredError('project'),
      'value' => _valueDetailBuilder?.call(id) ?? _notRegisteredError('value'),
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
    _taskDetailBuilder = null;
    _projectDetailBuilder = null;
    _valueDetailBuilder = null;
  }
}
