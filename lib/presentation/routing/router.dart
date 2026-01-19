import 'package:go_router/go_router.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/app_shell/scaffold_with_nested_navigation.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/routing/not_found_route_page.dart';
import 'package:taskly_bloc/presentation/routing/route_codec.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_history_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/values_page.dart';
import 'package:taskly_bloc/presentation/features/inbox/view/inbox_page.dart';
import 'package:taskly_bloc/presentation/features/anytime/view/anytime_page.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show ProjectScheduledScope, ValueScheduledScope;
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_page.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_page.dart';
import 'package:taskly_bloc/presentation/features/attention/view/attention_inbox_page.dart';
import 'package:taskly_bloc/presentation/features/attention/view/attention_rules_settings_page.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/view/focus_setup_wizard_route_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/trackers/view/trackers_page.dart';

/// Router for authenticated app shell.
///
/// Uses convention-based routing with a small set of patterns:
/// - **System screens (explicit)**: concrete paths like `/my-day`, `/anytime`,
///   `/scheduled`, etc.
/// - **Entity editors (NAV-01)**: `/<entityType>/new` and `/<entityType>/:id/edit`
/// - **Journal entry editor**: `/journal/entry/new` and `/journal/entry/:id/edit`
///
/// Note: legacy entity detail routes like `/project/:id` and `/value/:id` are
/// intentionally not supported (no redirects); the canonical entrypoints are the
/// editor routes.
final router = GoRouter(
  initialLocation: Routing.screenPath('my_day'),
  observers: [
    TalkerRouteObserver(talkerRaw),
    appRouteObserver,
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

        // Scoped Anytime routes should still highlight the Anytime destination.
        final scopedAnytimeActiveScreenId =
            (segments.length == 3 &&
                (segments.first == 'project' || segments.first == 'value') &&
                segments.last == 'anytime')
            ? Routing.parseScreenKey('anytime')
            : null;

        // Scoped Scheduled routes should still highlight the Scheduled destination.
        final scopedScheduledActiveScreenId =
            (segments.length == 3 &&
                (segments.first == 'project' || segments.first == 'value') &&
                segments.last == 'scheduled')
            ? Routing.parseScreenKey('scheduled')
            : null;

        return ScaffoldWithNestedNavigation(
          activeScreenId:
              scopedScheduledActiveScreenId ??
              scopedAnytimeActiveScreenId ??
              activeScreenId,
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
            return const MyDayPage();
          },
        ),
        GoRoute(
          path: Routing.screenPath('someday'),
          builder: (_, __) => const AnytimePage(),
        ),

        // Scoped Anytime feeds.
        GoRoute(
          path: '/project/:id/anytime',
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'project',
            operation: 'route_param_decode_project_anytime_scope',
          ),
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return AnytimePage(
              scope: AnytimeScope.project(projectId: id),
            );
          },
        ),
        GoRoute(
          path: '/value/:id/anytime',
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'value',
            operation: 'route_param_decode_value_anytime_scope',
          ),
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return AnytimePage(
              scope: AnytimeScope.value(valueId: id),
            );
          },
        ),
        GoRoute(
          path: Routing.screenPath('scheduled'),
          builder: (_, __) => const ScheduledPage(),
        ),

        // Scoped Scheduled feeds.
        GoRoute(
          path: '/project/:id/scheduled',
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'project',
            operation: 'route_param_decode_project_scheduled_scope',
          ),
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return ScheduledPage(
              scope: ProjectScheduledScope(projectId: id),
            );
          },
        ),
        GoRoute(
          path: '/value/:id/scheduled',
          redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
            state,
            paramName: 'id',
            entityType: 'value',
            operation: 'route_param_decode_value_scheduled_scope',
          ),
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return ScheduledPage(
              scope: ValueScheduledScope(valueId: id),
            );
          },
        ),

        // Inbox is a new global MVP route. Implementation will move to a real
        // feed screen as part of Package D follow-ups.
        GoRoute(
          path: Routing.screenPath('inbox'),
          builder: (_, __) => const InboxPage(),
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
          builder: (_, state) => TaskEditorRoutePage(
            taskId: state.pathParameters['id'],
          ),
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

        // === OTHER SYSTEM SCREENS (explicit; no catch-all) ===
        GoRoute(
          path: Routing.screenPath('journal'),
          builder: (_, __) => const JournalHubPage(),
        ),
        GoRoute(
          path: Routing.screenPath('values'),
          builder: (_, __) => const ValuesPage(),
        ),
        GoRoute(
          path: Routing.screenPath('review_inbox'),
          builder: (_, __) => const AttentionInboxPage(),
        ),
        GoRoute(
          path: Routing.screenPath('settings'),
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: Routing.screenPath('journal_history'),
          builder: (_, __) => const JournalHistoryPage(),
        ),
        GoRoute(
          path: Routing.screenPath('journal_manage_trackers'),
          builder: (_, __) => const JournalTrackersPage(),
        ),
        GoRoute(
          path: Routing.screenPath('trackers'),
          builder: (_, __) => const TrackersPage(),
        ),
        GoRoute(
          path: Routing.screenPath('focus_setup'),
          builder: (_, state) => FocusSetupWizardRoutePage(
            initialStep: FocusSetupWizardRoutePage.parseInitialStep(state.uri),
          ),
        ),
        GoRoute(
          path: Routing.screenPath('attention_rules'),
          builder: (_, __) => const AttentionRulesSettingsPage(),
        ),
      ],
    ),
  ],
);
