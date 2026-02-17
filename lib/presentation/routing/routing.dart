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
/// - **System screens (explicit)**: concrete paths like `/my-day`, `/projects`,
///   `/scheduled`, etc.
///   - URL segments use hyphens (`my_day` ? `/my-day`).
/// - **Entity editors (NAV-01)**: `/<entityType>/new` and `/<entityType>/:id/edit`
///   - Tasks are editor-only: `/task/:id` redirects to `/task/:id/edit`.
/// - **Journal entry editor**: `/journal/entry/new` and `/journal/entry/:id/edit`
///
/// Screen paths use convention: `screenKey` ? `/${screenKey}` with
/// underscores converted to hyphens (e.g., `my_day` ? `/my-day`).
///
/// Entity paths use convention: `/${entityType}/${id}`.
///
/// Note: entity editors (`/project/:id/edit`, `/value/:id/edit`) remain the
/// canonical edit entrypoints; detail routes are separate.
abstract final class Routing {
  // === PATH UTILITIES ===

  /// Get screen route path for building navigation destinations.
  static String screenPath(String screenKey) {
    return '/${screenKey.replaceAll('_', '-')}';
  }

  /// Parse URL segment back to screenKey.
  static String parseScreenKey(String segment) {
    return segment.replaceAll('-', '_');
  }

  /// Returns true when [screenKey] is a top-level navigation destination.
  ///
  /// This is used by the authenticated app shell to decide whether a location
  /// should count as an active navigation destination.
  static const Set<String> _navigationScreenKeys = {
    'my_day',
    'scheduled',
    'projects',
    'journal',
    'values',
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

  static String _settingsSubPath(String subPath) =>
      '${screenPath('settings')}/$subPath';

  static void pushSettingsAppearance(BuildContext context) =>
      GoRouter.of(context).push(_settingsSubPath('appearance'));

  static void pushSettingsWeeklyReview(BuildContext context) =>
      GoRouter.of(context).push(_settingsSubPath('weekly-review'));

  static void pushSettingsLanguageRegion(BuildContext context) =>
      GoRouter.of(context).push(_settingsSubPath('language-region'));

  static void pushSettingsAccount(BuildContext context) =>
      GoRouter.of(context).push(_settingsSubPath('account'));

  static void pushSettingsDeveloper(BuildContext context) =>
      GoRouter.of(context).push(_settingsSubPath('developer'));

  static void pushSettingsMicroLearning(BuildContext context) =>
      GoRouter.of(context).push(_settingsSubPath('micro-learning'));

  static void pushSettingsNotifications(BuildContext context) =>
      GoRouter.of(context).push(_settingsSubPath('notifications'));

  /// Navigate to screen by key with query parameters.
  ///
  /// Use this for deep links with query parameters.
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
      GoRouter.of(context).push('/project/${project.id}/detail');

  /// Navigate to project detail by ID (pushes onto nav stack).
  static void pushProjectDetail(BuildContext context, String projectId) {
    if (projectId.trim().isEmpty) return;
    GoRouter.of(context).push('/project/$projectId/detail');
  }

  /// Navigate to Inbox project detail (pushes onto nav stack).
  static void pushInboxProjectDetail(BuildContext context) => GoRouter.of(
    context,
  ).push(screenPath('inbox'));

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

  /// Push the scoped Projects feed for a value.
  static void pushValueProjects(BuildContext context, String valueId) {
    if (valueId.trim().isEmpty) return;
    GoRouter.of(context).push('/value/$valueId/projects');
  }

  static void toValueNew(BuildContext context) =>
      GoRouter.of(context).push('/value/new');

  static void toValueEdit(BuildContext context, String valueId) =>
      GoRouter.of(context).push('/value/$valueId/edit');

  // === ROUTINE EDITOR ROUTES ===

  static void toRoutineNew(
    BuildContext context, {
    String? defaultProjectId,
    bool openToProjectPicker = false,
  }) {
    final queryParameters = <String, String>{};
    if (defaultProjectId != null && defaultProjectId.trim().isNotEmpty) {
      queryParameters['projectId'] = defaultProjectId;
    }
    if (openToProjectPicker) {
      queryParameters['openProjectPicker'] = 'true';
    }

    final uri = Uri(
      path: '/routine/new',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    GoRouter.of(context).push(uri.toString());
  }

  static void toRoutineEdit(BuildContext context, String routineId) =>
      GoRouter.of(context).push('/routine/$routineId/edit');

  static void toRoutineDetail(
    BuildContext context,
    String routineId, {
    bool openIfThenComposer = false,
  }) {
    final uri = Uri(
      path: '/routine/$routineId',
      queryParameters: openIfThenComposer
          ? const <String, String>{'compose': 'if_then'}
          : null,
    );
    GoRouter.of(context).push(uri.toString());
  }

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

  static void toJournalTrackerWizard(BuildContext context) {
    GoRouter.of(context).push('/journal/trackers/new');
  }

  /// Get onTap callback for entity navigation.
  static VoidCallback onTapEntity(
    BuildContext context,
    EntityType type,
    String id,
  ) =>
      () => toEntity(context, type, id);
}
