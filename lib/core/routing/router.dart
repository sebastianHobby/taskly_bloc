import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/core/routing/widgets/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/navigation_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/features/screens/view/unified_screen_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/tracker_management/tracker_management_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/tracker_management_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/wellbeing_dashboard_screen.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_list_page.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_run_page.dart';
import 'package:taskly_bloc/presentation/features/screens/view/screen_management_page.dart';
import 'package:taskly_bloc/presentation/features/navigation/view/navigation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/allocation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';

/// Router for authenticated app shell.
///
/// Note: Auth routes are handled by the unauthenticated Navigator in app.dart.
/// This router only contains protected routes since it's only mounted when
/// the user is authenticated.
final router = GoRouter(
  initialLocation: '/inbox',
  observers: [TalkerRouteObserver(talker)],
  routes: [
    // Legacy aliases redirect to unified screen routes
    GoRoute(
      path: '/tasks/today',
      redirect: (_, __) => '/today',
    ),
    GoRoute(
      path: '/tasks/upcoming',
      redirect: (_, __) => '/upcoming',
    ),
    GoRoute(
      path: '/tasks/next-actions',
      redirect: (_, __) => '/next-actions',
    ),
    // Legacy /s/ prefix redirects
    GoRoute(
      path: '/s/:screenId',
      redirect: (_, state) {
        final screenId = state.pathParameters['screenId']!;
        return Routing.screenPath(screenId);
      },
    ),
    ShellRoute(
      builder: (context, state, child) {
        // Derive activeScreenId from URL segment
        final segment = state.pathParameters['segment'];
        final activeScreenId = segment != null
            ? Routing.parseScreenKey(segment)
            : null;

        // Use a constant key to prevent NavigationBloc from being recreated
        // on every ShellRoute builder call. Without a key, each navigation
        // would dispose the old BlocProvider and create a new one, closing
        // all child blocs (ScreenDefinitionBloc, TaskOverviewBloc, etc.)
        return BlocProvider(
          key: const ValueKey('navigation_bloc_provider'),
          create: (_) => NavigationBloc(
            screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
            badgeService: NavigationBadgeService(
              taskRepository: getIt<TaskRepositoryContract>(),
              projectRepository: getIt<ProjectRepositoryContract>(),
            ),
            iconResolver: const NavigationIconResolver(),
          )..add(const NavigationStarted()),
          child: ScaffoldWithNestedNavigation(
            activeScreenId: activeScreenId,
            child: child,
          ),
        );
      },
      routes: [
        // === ENTITY DETAIL ROUTES ===
        GoRoute(
          path: '/task/:id',
          builder: (context, state) => BlocProvider(
            create: (_) => TaskDetailBloc(
              taskId: state.pathParameters['id'],
              taskRepository: getIt<TaskRepositoryContract>(),
              projectRepository: getIt<ProjectRepositoryContract>(),
              labelRepository: getIt<LabelRepositoryContract>(),
            ),
            child: const TaskDetailSheet(),
          ),
        ),
        GoRoute(
          path: '/project/:id',
          builder: (context, state) => ProjectDetailUnifiedPage(
            projectId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/label/:id',
          builder: (context, state) => LabelDetailUnifiedPage(
            labelId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/value/:id',
          builder: (context, state) => LabelDetailUnifiedPage(
            labelId: state.pathParameters['id']!,
          ),
        ),

        // === SPECIAL ROUTES (with custom Bloc providers) ===
        GoRoute(
          path: '/wellbeing',
          builder: (context, state) => BlocProvider(
            create: (_) => WellbeingDashboardBloc(getIt<AnalyticsService>()),
            child: const WellbeingDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/journal',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                JournalEntryBloc(getIt<WellbeingRepositoryContract>()),
            child: const JournalScreen(),
          ),
        ),
        GoRoute(
          path: '/trackers',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                TrackerManagementBloc(getIt<WellbeingRepositoryContract>()),
            child: const TrackerManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/workflow-run',
          builder: (context, state) {
            final definition = state.extra! as WorkflowDefinition;
            return WorkflowRunPage(definition: definition);
          },
        ),

        // === SETTINGS SUB-ROUTES ===
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsScreen(
            settingsRepository: getIt<SettingsRepositoryContract>(),
          ),
        ),
        GoRoute(
          path: '/allocation-settings',
          builder: (context, state) => AllocationSettingsPage(
            settingsRepository: getIt<SettingsRepositoryContract>(),
            labelRepository: getIt<LabelRepositoryContract>(),
          ),
        ),
        GoRoute(
          path: '/navigation-settings',
          builder: (context, state) => NavigationSettingsPage(
            screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
          ),
        ),
        GoRoute(
          path: '/screen-management',
          builder: (context, state) => ScreenManagementPage(
            userId: getIt<AuthRepositoryContract>().currentUser!.id,
          ),
        ),
        GoRoute(
          path: '/workflows',
          builder: (context, state) => WorkflowListPage(
            userId: getIt<AuthRepositoryContract>().currentUser!.id,
          ),
        ),

        // === UNIFIED SCREEN ROUTE (catch-all) ===
        // ALL other screens: inbox, today, projects, settings, workflows, etc.
        GoRoute(
          path: '/:segment',
          builder: (context, state) {
            final screenKey = Routing.parseScreenKey(
              state.pathParameters['segment']!,
            );

            // Check system screens first
            final systemScreen = SystemScreenDefinitions.getById(screenKey);
            if (systemScreen != null) {
              return UnifiedScreenPage(
                key: ValueKey('screen_$screenKey'),
                definition: systemScreen,
              );
            }

            // Load user-defined screen from repository
            return UnifiedScreenPageById(
              key: ValueKey('screen_$screenKey'),
              screenId: screenKey,
            );
          },
        ),
      ],
    ),
  ],
);
