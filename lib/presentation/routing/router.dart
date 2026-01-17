import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/app_shell/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/core/performance/performance_route_observer.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_editor_route_page.dart';

/// Router for authenticated app shell.
///
/// Uses convention-based routing with a small set of patterns:
/// - **Unified screens**: `/:segment` → handled by [Routing.buildScreen]
///   - Screen segments use hyphens (`my_day` → `/my-day`).
///   - The canonical Anytime URL segment is `anytime` (mapped to screenKey
///     `someday` by [Routing.parseScreenKey]).
/// - **Entity detail (read/composite)**: `/<entityType>/:id` → handled by
///   [Routing.buildEntityDetail]
/// - **Entity editors (NAV-01)**: `/<entityType>/new` and `/<entityType>/:id/edit`
/// - **Journal entry editor**: `/journal/entry/new` and `/journal/entry/:id/edit`
///
/// All screen/entity builders are registered in [Routing] at bootstrap.
/// Note: a small number of legacy aliases/redirects still exist for backwards
/// compatibility.
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
        // They open the modal editor and then return (pop).

        // Journal entry editor (create + edit)
        GoRoute(
          path: '/journal/entry/new',
          builder: (_, state) {
            final csv = state.uri.queryParameters['trackerIds'] ?? '';
            final ids = csv
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toSet();

            return JournalEntryEditorRoutePage(
              entryId: null,
              preselectedTrackerIds: ids,
            );
          },
        ),
        GoRoute(
          path: '/journal/entry/:id/edit',
          builder: (_, state) => JournalEntryEditorRoutePage(
            entryId: state.pathParameters['id'],
            preselectedTrackerIds: const <String>{},
          ),
        ),

        // Task (editor-only; no read-only task detail surface)
        GoRoute(
          path: '/task/new',
          builder: (_, state) => TaskEditorRoutePage(
            taskId: null,
            defaultProjectId: state.uri.queryParameters['projectId'],
            defaultValueIds: switch (state.uri.queryParameters['valueId']) {
              final v? when v.trim().isNotEmpty => [v],
              _ => null,
            },
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

        // Project (editor routes)
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

        // Value (editor routes)
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

        // === ENTITY DETAIL ROUTES (RD surfaces) ===
        // Parameterized routes for read/composite entity pages.
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
        // All system screens: my_day, settings, journal, etc.
        // Note: Routing.parseScreenKey handles aliases (e.g. 'anytime' -> 'someday').
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
