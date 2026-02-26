import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/app_shell/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/presentation/features/micro_learning/view/micro_learning_overlay_host.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/routing/not_found_route_page.dart';
import 'package:taskly_bloc/presentation/routing/route_codec.dart';
import 'package:taskly_bloc/presentation/routing/session_entry_policy.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/features/app/view/initial_sync_gate_screen.dart';
import 'package:taskly_bloc/presentation/features/app/view/splash_screen.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/view/check_email_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/forgot_password_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/auth_callback_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/reset_password_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_in_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_up_view.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_manage_factors_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_tracker_wizard_page.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routine_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/values_page.dart';
import 'package:taskly_bloc/presentation/features/projects/view/projects_page.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show ProjectScheduledScope, ValueScheduledScope;
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_page.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_appearance_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_weekly_review_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_language_region_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_account_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_developer_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_sync_issues_page.dart';
import 'package:taskly_bloc/presentation/features/statistics/view/debug_stats_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_micro_learning_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_notifications_page.dart';
import 'package:taskly_bloc/presentation/debug/taskly_tile_catalog_page.dart';
import 'package:taskly_bloc/presentation/features/onboarding/view/onboarding_flow_page.dart';

Widget buildSettingsStatsRoutePage() {
  return kDebugMode
      ? const DebugStatsPage()
      : const NotFoundRoutePage(message: 'Not found');
}

/// Router for the app, including auth/sync gating and the authenticated shell.
///
/// Uses convention-based routing with a small set of patterns:
/// - **System screens (explicit)**: concrete paths like `/my-day`, `/projects`,
///   `/scheduled`, etc.
/// - **Entity editors (NAV-01)**: `/<entityType>/new` and `/<entityType>/:id/edit`
/// - **Journal entry editor**: `/journal/entry/new` and `/journal/entry/:id/edit`
///
/// Note: entity editor routes remain the canonical edit entrypoints.
GoRouter createRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  Listenable? refreshListenable,
  AppAuthState Function(BuildContext context)? authStateSelector,
  GlobalSettingsState Function(BuildContext context)? settingsStateSelector,
  InitialSyncGateState Function(BuildContext context)? syncStateSelector,
}) {
  final authSelector =
      authStateSelector ??
      (BuildContext context) => context.read<AuthBloc>().state;
  final settingsSelector =
      settingsStateSelector ??
      (BuildContext context) => context.read<GlobalSettingsBloc>().state;
  final syncSelector =
      syncStateSelector ??
      (BuildContext context) => context.read<InitialSyncGateBloc>().state;

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: splashPath,
    observers: [
      TalkerRouteObserver(talkerRaw),
      appRouteObserver,
    ],
    errorBuilder: (_, state) => NotFoundRoutePage(
      details: state.error?.toString(),
    ),
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final path = state.uri.path;
      final authState = authSelector(context);
      final settingsState = settingsSelector(context);
      final syncState = syncSelector(context);

      return sessionEntryRedirectTarget(
        path: path,
        authState: authState,
        settingsState: settingsState,
        syncState: syncState,
        allowOnboardingDebug: state.uri.queryParameters['debug'] == '1',
        appHomePath: Routing.screenPath('my_day'),
      );
    },
    routes: [
      GoRoute(
        path: splashPath,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: signInPath,
        builder: (_, __) => const SignInView(),
      ),
      GoRoute(
        path: signUpPath,
        builder: (_, __) => const SignUpView(),
      ),
      GoRoute(
        path: checkEmailPath,
        builder: (_, __) => const CheckEmailView(),
      ),
      GoRoute(
        path: forgotPasswordPath,
        builder: (_, __) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: authCallbackPath,
        builder: (_, __) => const AuthCallbackView(),
      ),
      GoRoute(
        path: resetPasswordPath,
        builder: (_, __) => const ResetPasswordView(),
      ),
      GoRoute(
        path: initialSyncPath,
        builder: (_, __) => const InitialSyncGateScreen(),
      ),
      GoRoute(
        path: onboardingPath,
        builder: (_, __) => const OnboardingFlowPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          // Derive activeScreenId from the URL path for 1-segment screen routes.
          // For non-screen routes (editors/details), keep it null to preserve
          // previous behavior (no nav highlight).
          final segments = state.uri.pathSegments;
          final candidate = segments.isNotEmpty
              ? Routing.parseScreenKey(segments.first)
              : null;
          final normalizedCandidate = candidate == 'inbox'
              ? 'projects'
              : candidate;
          final activeScreenId =
              (normalizedCandidate != null &&
                  Routing.isSystemScreenKey(normalizedCandidate))
              ? normalizedCandidate
              : null;

          // Scoped Projects routes should still highlight the Projects destination.
          final scopedProjectsActiveScreenId =
              (segments.length == 3 &&
                  (segments.first == 'project' || segments.first == 'value') &&
                  segments.last == 'projects')
              ? Routing.parseScreenKey('projects')
              : null;

          // Scoped Scheduled routes should still highlight the Scheduled destination.
          final scopedScheduledActiveScreenId =
              (segments.length == 3 &&
                  (segments.first == 'project' || segments.first == 'value') &&
                  segments.last == 'scheduled')
              ? Routing.parseScreenKey('scheduled')
              : null;

          return MicroLearningOverlayHost(
            currentPath: state.uri.path,
            child: ScaffoldWithNestedNavigation(
              activeScreenId:
                  scopedScheduledActiveScreenId ??
                  scopedProjectsActiveScreenId ??
                  activeScreenId,
              child: child,
            ),
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
            path: Routing.screenPath('projects'),
            builder: (_, __) => const ProjectsPage(),
          ),
          GoRoute(
            path: Routing.screenPath('inbox'),
            builder: (_, __) => ProjectDetailPage(
              projectId: ProjectGroupingRef.inbox().stableKey,
            ),
          ),

          // Scoped Projects feeds.
          GoRoute(
            path: '/value/:id/projects',
            redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
              state,
              paramName: 'id',
              entityType: 'value',
              operation: 'route_param_decode_value_projects_scope',
            ),
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return ProjectsPage(
                scope: ProjectsScope.value(valueId: id),
              );
            },
          ),
          GoRoute(
            path: '/project/inbox/detail',
            redirect: (_, __) => Routing.screenPath('inbox'),
            builder: (_, __) => ProjectDetailPage(
              projectId: ProjectGroupingRef.inbox().stableKey,
            ),
          ),
          GoRoute(
            path: '/project/:id/detail',
            redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
              state,
              paramName: 'id',
              entityType: 'project',
              operation: 'route_param_decode_project_detail',
            ),
            builder: (_, state) => ProjectDetailPage(
              projectId: state.pathParameters['id']!,
            ),
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
              final dayRaw = state.uri.queryParameters['day'];
              final selectedDay = dayRaw == null
                  ? null
                  : DateTime.tryParse(dayRaw);

              return JournalEntryEditorRoutePage(
                entryId: null,
                preselectedTrackerIds: ids,
                selectedDayLocal: selectedDay,
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
              selectedDayLocal: null,
            ),
          ),

          // Task (editor-only; no read-only task detail surface)
          GoRoute(
            path: '/task/new',
            builder: (_, state) => TaskEditorRoutePage(
              taskId: null,
              defaultProjectId: state.uri.queryParameters['projectId'],
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

          // Routine (editor routes)
          GoRoute(
            path: '/routine/new',
            builder: (_, state) {
              final projectId = state.uri.queryParameters['projectId'];
              final openPicker =
                  (state.uri.queryParameters['openProjectPicker'] ?? '')
                      .toLowerCase() ==
                  'true';
              final shouldOpenPicker =
                  openPicker || projectId == null || projectId.trim().isEmpty;
              return RoutineEditorRoutePage(
                routineId: null,
                defaultProjectId: projectId,
                openToProjectPicker: shouldOpenPicker,
              );
            },
          ),
          GoRoute(
            path: '/routine/:id/edit',
            redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
              state,
              paramName: 'id',
              entityType: 'routine',
              operation: 'route_param_decode_routine_edit',
            ),
            builder: (_, state) => RoutineEditorRoutePage(
              routineId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/routine/:id',
            redirect: (_, state) => RouteCodec.redirectIfInvalidUuidParam(
              state,
              paramName: 'id',
              entityType: 'routine',
              operation: 'route_param_decode_routine_detail',
            ),
            builder: (_, state) => RoutineEditorRoutePage(
              routineId: state.pathParameters['id'],
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
            path: Routing.screenPath('settings'),
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/appearance',
            builder: (_, __) => const SettingsAppearancePage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/weekly-review',
            builder: (_, __) => const SettingsWeeklyReviewPage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/language-region',
            builder: (_, __) => const SettingsLanguageRegionPage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/account',
            builder: (_, __) => const SettingsAccountPage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/developer',
            builder: (_, __) => const SettingsDeveloperPage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/developer/sync-issues',
            builder: (_, __) => const SettingsSyncIssuesPage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/developer/stats',
            builder: (_, __) => buildSettingsStatsRoutePage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/micro-learning',
            builder: (_, __) => const SettingsMicroLearningPage(),
          ),
          GoRoute(
            path: '${Routing.screenPath('settings')}/notifications',
            builder: (_, __) => const SettingsNotificationsPage(),
          ),
          GoRoute(
            path: Routing.screenPath('journal_manage_factors'),
            builder: (_, __) => const JournalManageFactorsPage(),
          ),
          GoRoute(
            path: '/journal/trackers/new',
            builder: (_, __) => const JournalTrackerWizardPage(
              mode: JournalTrackerWizardMode.tracker,
            ),
          ),
          GoRoute(
            path: '/journal/daily-checkins/new',
            builder: (_, __) => const JournalTrackerWizardPage(
              mode: JournalTrackerWizardMode.dailyCheckin,
            ),
          ),
          GoRoute(
            path: '/debug/tiles',
            builder: (_, __) => const TasklyTileCatalogPage(),
          ),
        ],
      ),
    ],
  );
}
