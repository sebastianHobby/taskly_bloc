import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

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
///   `/scheduled`, etc.
///   - URL segments use hyphens (`my_day` ? `/my-day`).
///   - The canonical Anytime URL segment is `anytime`, which maps to the
///     legacy system screen key `someday`.
/// - **Entity editors (NAV-01)**: `/<entityType>/new` and `/<entityType>/:id/edit`
///   - Tasks are editor-only: `/task/:id` redirects to `/task/:id/edit`.
/// - **Journal entry editor**: `/journal/entry/new` and `/journal/entry/:id/edit`
///
/// Screen paths use convention: `screenKey` ? `/${screenKey}` with
/// underscores converted to hyphens (e.g., `my_day` ? `/my-day`).
///
/// Entity paths use convention: `/${entityType}/${id}`.
///
/// Note: legacy entity detail routes like `/project/:id` and `/value/:id` are
/// intentionally not supported (no redirects); the canonical entrypoints are the
/// editor routes (`/project/:id/edit`, `/value/:id/edit`).
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

  /// Returns true when [screenKey] is a top-level navigation destination.
  ///
  /// This is used by the authenticated app shell to decide whether a location
  /// should count as an active navigation destination.
  static const Set<String> _navigationScreenKeys = {
    'my_day',
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
      GoRouter.of(context).push('/project/${project.id}/edit');

  /// Navigate to value detail (pushes onto nav stack).
  static void toValue(BuildContext context, Value value) =>
      GoRouter.of(context).push('/value/${value.id}/edit');

  // === ENTITY NAVIGATION (generic) ===

  /// Navigate to entity detail by type and ID.
  /// Use when you only have the ID, not the full domain object.
  static void toEntity(BuildContext context, EntityType type, String id) {
    switch (type) {
      case EntityType.task:
        GoRouter.of(context).push('/task/$id/edit');
      case EntityType.project:
        GoRouter.of(context).push('/project/$id/edit');
      case EntityType.value:
        GoRouter.of(context).push('/value/$id/edit');
    }
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

  // === JOURNAL ENTRY EDITOR ROUTES (Journal Today-first) ===

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
}
