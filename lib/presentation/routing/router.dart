import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/app_shell/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/core/performance/performance_route_observer.dart';
import 'package:taskly_bloc/presentation/routing/not_found_route_page.dart';
import 'package:taskly_bloc/presentation/routing/route_codec.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/inbox/view/inbox_page.dart';
import 'package:taskly_bloc/presentation/features/anytime/view/anytime_page.dart';
import 'package:taskly_bloc/core/env/env.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_mvp_page.dart';

/// Router for authenticated app shell.
///
/// Uses convention-based routing with a small set of patterns:
/// - **System screens (explicit)**: concrete paths like `/my-day`, `/anytime`,
///   `/scheduled`, etc.
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
    TalkerRouteObserver(talkerRaw),
    appRouteObserver,
    PerformanceRouteObserver(),
  ],
  errorBuilder: (_, state) => NotFoundRoutePage(
    message: 'Page not found',
    details: state.error?.toString(),
  ),
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // Derive activeScreenId from the URL path for 1-segment screen routes.
        // For non-screen routes (editors/details), keep it null to preserve
        // previous behavior (no nav highlight).
        final segments = state.uri.pathSegments;
        final candidate = segments.length == 1
            ? Routing.parseScreenKey(segments.single)
            : null;
        final activeScreenId =
            (candidate != null && Routing.isSystemScreenKey(candidate))
            ? candidate
            : null;

        return ScaffoldWithNestedNavigation(
          activeScreenId: activeScreenId,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/not-found',
          builder: (_, state) => NotFoundRoutePage(
            message: state.uri.queryParameters['message'],
            details: state.uri.queryParameters['details'],
          ),
        ),

        // === MVP SHELL ROUTES (Package D strangler entrypoints) ===
        GoRoute(
          path: Routing.screenPath('my_day'),
          builder: (_, __) {
            if (Env.enableMvpMyDay) return const MyDayMvpPage();
            return Routing.buildScreen('my_day');
          },
        ),
        GoRoute(
          path: Routing.screenPath('someday'),
          builder: (_, __) => const AnytimePage(),
        ),
        GoRoute(
          path: Routing.screenPath('scheduled'),
          builder: (_, __) => Routing.buildScreen('scheduled'),
        ),

        // Inbox is a new global MVP route. Implementation will move to a real
        // feed screen as part of Package D follow-ups.
        GoRoute(
          path: Routing.screenPath('inbox'),
          builder: (_, __) => const InboxPage(),
        ),

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
            final invalid = RouteCodec.redirectIfInvalidUuidParam(
              state,
              paramName: 'id',
              entityType: 'project',
              operation: 'route_redirect_legacy_project_plural',
            );
            if (invalid != null) return invalid;

            final id = state.pathParameters['id']!;
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
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'journal_entry',
            operation: 'route_param_decode_journal_entry_edit',
          ),
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
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'task',
            operation: 'route_param_decode_task_edit',
          ),
          builder: (_, state) => Routing.buildEntityDetail(
            'task',
            state.pathParameters['id']!,
          ),
        ),
        // Redirect legacy/non-canonical task detail route to canonical edit.
        GoRoute(
          path: '/task/:id',
          redirect: (_, state) {
            final invalid = RouteCodec.redirectIfInvalidUuidParam(
              state,
              paramName: 'id',
              entityType: 'task',
              operation: 'route_redirect_task_to_edit',
            );
            if (invalid != null) return invalid;

            final id = state.pathParameters['id']!;
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
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'project',
            operation: 'route_param_decode_project_edit',
          ),
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
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'value',
            operation: 'route_param_decode_value_edit',
          ),
          builder: (_, state) => ValueEditorRoutePage(
            valueId: state.pathParameters['id'],
          ),
        ),

        // === ENTITY DETAIL ROUTES (RD surfaces) ===
        // Parameterized routes for read/composite entity pages.
        GoRoute(
          path: '/project/:id',
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'project',
            operation: 'route_param_decode_project_detail',
          ),
          builder: (_, state) => Routing.buildEntityDetail(
            'project',
            state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/value/:id',
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'value',
            operation: 'route_param_decode_value_detail',
          ),
          builder: (_, state) => Routing.buildEntityDetail(
            'value',
            state.pathParameters['id']!,
          ),
        ),

        // === OTHER SYSTEM SCREENS (explicit; no catch-all) ===
        GoRoute(
          path: Routing.screenPath('journal'),
          builder: (_, __) => Routing.buildScreen('journal'),
        ),
        GoRoute(
          path: Routing.screenPath('values'),
          builder: (_, __) => Routing.buildScreen('values'),
        ),
        GoRoute(
          path: Routing.screenPath('statistics'),
          builder: (_, __) => Routing.buildScreen('statistics'),
        ),
        GoRoute(
          path: Routing.screenPath('review_inbox'),
          builder: (_, __) => Routing.buildScreen('review_inbox'),
        ),
        GoRoute(
          path: Routing.screenPath('settings'),
          builder: (_, __) => Routing.buildScreen('settings'),
        ),
        GoRoute(
          path: Routing.screenPath('journal_history'),
          builder: (_, __) => Routing.buildScreen('journal_history'),
        ),
        GoRoute(
          path: Routing.screenPath('journal_manage_trackers'),
          builder: (_, __) => Routing.buildScreen('journal_manage_trackers'),
        ),
        GoRoute(
          path: Routing.screenPath('trackers'),
          builder: (_, __) => Routing.buildScreen('trackers'),
        ),
        GoRoute(
          path: Routing.screenPath('allocation_settings'),
          builder: (_, __) => Routing.buildScreen('allocation_settings'),
        ),
        GoRoute(
          path: Routing.screenPath('focus_setup'),
          builder: (_, __) => Routing.buildScreen('focus_setup'),
        ),
        GoRoute(
          path: Routing.screenPath('attention_rules'),
          builder: (_, __) => Routing.buildScreen('attention_rules'),
        ),
      ],
    ),
  ],
);
