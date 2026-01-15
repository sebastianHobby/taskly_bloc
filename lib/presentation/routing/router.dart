import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/app_shell/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/core/performance/performance_route_observer.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_editor_route_page.dart';

/// Router for authenticated app shell.
///
/// Uses convention-based routing with only two patterns:
/// - **Screens**: `/:segment` → handled by [Routing.buildScreen]
/// - **Entities**: `/:entityType/:id` → handled by [Routing.buildEntityDetail]
///
/// All screen/entity builders are registered in [Routing] at bootstrap.
/// No legacy redirects - all paths are canonical.
final router = GoRouter(
  initialLocation: Routing.screenPath('my_day'),
  observers: [
    TalkerRouteObserver(talker.raw),
    appRouteObserver,
    PerformanceRouteObserver(),
  ],
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // Derive activeScreenId from URL segment
        final segment = state.pathParameters['segment'];
        final activeScreenId = segment != null
            ? Routing.parseScreenKey(segment)
            : null;

        return ScaffoldWithNestedNavigation(
          activeScreenId: activeScreenId,
          child: child,
        );
      },
      routes: [
        // === LEGACY ROUTE ALIASES / REDIRECTS ===
        // Projects list destination has been removed.
        GoRoute(
          path: '/projects',
          redirect: (_, __) => Routing.screenPath('someday'),
          builder: (_, __) => const SizedBox.shrink(),
        ),
        // Legacy plural project detail route.
        GoRoute(
          path: '/projects/:id',
          redirect: (_, state) {
            final id = state.pathParameters['id'];
            if (id == null || id.isEmpty) return null;
            return '/project/$id';
          },
          builder: (_, __) => const SizedBox.shrink(),
        ),
        // Legacy Someday route redirects to canonical Anytime path.
        GoRoute(
          path: '/someday',
          redirect: (_, __) => Routing.screenPath('someday'),
          builder: (_, __) => const SizedBox.shrink(),
        ),

        // === ENTITY EDITOR ROUTES (NAV-01) ===
        // Create + edit are route-backed editor entry points.
        // They open the modal editor and then return (pop or my-day fallback).

        // Task (editor-only)
        GoRoute(
          path: '/task/new',
          builder: (_, state) => TaskEditorRoutePage(
            taskId: null,
            defaultProjectId: state.uri.queryParameters['projectId'],
          ),
        ),
        GoRoute(
          path: '/task/:id/edit',
          builder: (_, state) => Routing.buildEntityDetail(
            'task',
            state.pathParameters['id']!,
          ),
        ),
        // Redirect legacy/non-canonical task detail route to canonical edit.
        GoRoute(
          path: '/task/:id',
          redirect: (_, state) {
            final id = state.pathParameters['id'];
            if (id == null || id.isEmpty) return null;
            return '/task/$id/edit';
          },
          builder: (_, state) => const SizedBox.shrink(),
        ),

        // Project (detail + edit)
        GoRoute(
          path: '/project/new',
          builder: (_, __) => const ProjectEditorRoutePage(projectId: null),
        ),
        GoRoute(
          path: '/project/:id/edit',
          builder: (_, state) => ProjectEditorRoutePage(
            projectId: state.pathParameters['id'],
          ),
        ),

        // Value (detail + edit)
        GoRoute(
          path: '/value/new',
          builder: (_, __) => const ValueEditorRoutePage(valueId: null),
        ),
        GoRoute(
          path: '/value/:id/edit',
          builder: (_, state) => ValueEditorRoutePage(
            valueId: state.pathParameters['id'],
          ),
        ),

        // === ENTITY DETAIL ROUTES ===
        // These are parameterized routes that need IDs
        GoRoute(
          path: '/project/:id',
          builder: (_, state) => Routing.buildEntityDetail(
            'project',
            state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/value/:id',
          builder: (_, state) => Routing.buildEntityDetail(
            'value',
            state.pathParameters['id']!,
          ),
        ),

        // === UNIFIED SCREEN ROUTE (convention-based catch-all) ===
        // ALL screens: my_day, settings, journal, etc.
        // Builders are registered in Routing at bootstrap.
        GoRoute(
          path: '/:segment',
          builder: (_, state) {
            final screenKey = Routing.parseScreenKey(
              state.pathParameters['segment']!,
            );
            return Routing.buildScreen(screenKey);
          },
        ),
      ],
    ),
  ],
);
