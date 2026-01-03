import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/core/routing/widgets/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/navigation_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/features/navigation/view/navigation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/allocation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/view/unified_screen_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/tracker_management/tracker_management_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/tracker_management_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/wellbeing_dashboard_screen.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_list_page.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_run_page.dart';
import 'package:taskly_bloc/presentation/features/screens/view/screen_management_page.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';

/// Router for authenticated app shell.
///
/// Note: Auth routes are handled by the unauthenticated Navigator in app.dart.
/// This router only contains protected routes since it's only mounted when
/// the user is authenticated.
final router = GoRouter(
  initialLocation: '${AppRoutePath.screenBase}/inbox',
  observers: [TalkerRouteObserver(talker)],
  routes: [
    // Legacy aliases redirect to unified screen routes
    GoRoute(
      name: AppRouteName.inbox,
      path: '/inbox',
      redirect: (_, __) => '${AppRoutePath.screenBase}/inbox',
    ),
    GoRoute(
      name: AppRouteName.today,
      path: '/tasks/today',
      redirect: (_, __) => '${AppRoutePath.screenBase}/today',
    ),
    GoRoute(
      name: AppRouteName.upcoming,
      path: '/tasks/upcoming',
      redirect: (_, __) => '${AppRoutePath.screenBase}/upcoming',
    ),
    GoRoute(
      name: AppRouteName.projects,
      path: '/projects',
      redirect: (_, __) => '${AppRoutePath.screenBase}/projects',
    ),
    GoRoute(
      name: AppRouteName.labels,
      path: '/labels',
      redirect: (_, __) => '${AppRoutePath.screenBase}/labels',
    ),
    GoRoute(
      name: AppRouteName.values,
      path: '/values',
      redirect: (_, __) => '${AppRoutePath.screenBase}/values',
    ),
    GoRoute(
      name: AppRouteName.taskNextActions,
      path: '/tasks/next-actions',
      redirect: (_, __) => '${AppRoutePath.screenBase}/next_actions',
    ),
    ShellRoute(
      builder: (context, state, child) {
        // Determine activeScreenId from path parameters or route path
        String? activeScreenId = state.pathParameters['screenId'];

        // For fixed routes without screenId parameter, derive from path
        if (activeScreenId == null) {
          final path = state.matchedLocation;
          if (path == AppRoutePath.wellbeing) {
            activeScreenId = 'wellbeing';
          } else if (path == AppRoutePath.journal) {
            activeScreenId = 'journal';
          } else if (path == AppRoutePath.trackerManagement) {
            activeScreenId = 'trackers';
          } else if (path == AppRoutePath.taskNextActionsSettings) {
            activeScreenId = 'allocation_settings';
          } else if (path == AppRoutePath.navigationSettings) {
            activeScreenId = 'navigation_settings';
          } else if (path == AppRoutePath.appSettings) {
            activeScreenId = 'settings';
          }
        }

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
            routeBuilder: (screenId) => '${AppRoutePath.screenBase}/$screenId',
          )..add(const NavigationStarted()),
          child: ScaffoldWithNestedNavigation(
            activeScreenId: activeScreenId,
            child: child,
          ),
        );
      },
      routes: [
        // Unified screen route - renders any screen via unified path
        GoRoute(
          name: AppRouteName.screen,
          path: AppRoutePath.screen,
          builder: (context, state) {
            final screenId = state.pathParameters['screenId']!;
            // Check if it's a system screen
            final systemScreen = SystemScreenDefinitions.getById(screenId);
            if (systemScreen != null) {
              return UnifiedScreenPage(
                key: ValueKey('screen_$screenId'),
                definition: systemScreen,
              );
            }
            // Otherwise load from repository
            return UnifiedScreenPageById(
              key: ValueKey('screen_$screenId'),
              screenId: screenId,
            );
          },
        ),
        GoRoute(
          name: AppRouteName.navigationSettings,
          path: AppRoutePath.navigationSettings,
          builder: (context, state) => NavigationSettingsPage(
            screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
          ),
        ),
        GoRoute(
          name: AppRouteName.appSettings,
          path: AppRoutePath.appSettings,
          builder: (context, state) => SettingsScreen(
            settingsRepository: getIt<SettingsRepositoryContract>(),
          ),
        ),
        GoRoute(
          name: AppRouteName.projectDetail,
          path: AppRoutePath.projectDetail,
          builder: (context, state) => ProjectDetailUnifiedPage(
            projectId: state.pathParameters['projectId']!,
          ),
        ),
        GoRoute(
          name: AppRouteName.taskDetail,
          path: AppRoutePath.taskDetail,
          builder: (context, state) => BlocProvider(
            create: (_) => TaskDetailBloc(
              taskId: state.pathParameters['taskId'],
              taskRepository: getIt<TaskRepositoryContract>(),
              projectRepository: getIt<ProjectRepositoryContract>(),
              labelRepository: getIt<LabelRepositoryContract>(),
            ),
            child: const TaskDetailSheet(),
          ),
        ),
        GoRoute(
          name: AppRouteName.taskNextActionsSettings,
          path: AppRoutePath.taskNextActionsSettings,
          builder: (context, state) => AllocationSettingsPage(
            settingsRepository: getIt<SettingsRepositoryContract>(),
            labelRepository: getIt<LabelRepositoryContract>(),
          ),
        ),
        GoRoute(
          name: AppRouteName.labelDetail,
          path: '${AppRoutePath.labels}/:labelId',
          builder: (context, state) => LabelDetailUnifiedPage(
            labelId: state.pathParameters['labelId']!,
          ),
        ),
        // Values are labels with type=value, reuse LabelDetailUnifiedPage
        GoRoute(
          path: '${AppRoutePath.values}/:valueId',
          builder: (context, state) => LabelDetailUnifiedPage(
            labelId: state.pathParameters['valueId']!,
          ),
        ),
        GoRoute(
          name: AppRouteName.wellbeing,
          path: AppRoutePath.wellbeing,
          builder: (context, state) => BlocProvider(
            create: (context) => WellbeingDashboardBloc(
              getIt<AnalyticsService>(),
            ),
            child: const WellbeingDashboardScreen(),
          ),
        ),
        GoRoute(
          name: AppRouteName.journal,
          path: AppRoutePath.journal,
          builder: (context, state) => BlocProvider(
            create: (context) => JournalEntryBloc(
              getIt<WellbeingRepositoryContract>(),
            ),
            child: const JournalScreen(),
          ),
        ),
        GoRoute(
          name: AppRouteName.trackerManagement,
          path: AppRoutePath.trackerManagement,
          builder: (context, state) => BlocProvider(
            create: (context) => TrackerManagementBloc(
              getIt<WellbeingRepositoryContract>(),
            ),
            child: const TrackerManagementScreen(),
          ),
        ),
        GoRoute(
          name: AppRouteName.workflows,
          path: AppRoutePath.workflows,
          builder: (context, state) {
            final authRepo = getIt<AuthRepositoryContract>();
            return WorkflowListPage(
              userId: authRepo.currentSession?.user.id ?? '',
            );
          },
        ),
        GoRoute(
          name: AppRouteName.workflowRun,
          path: AppRoutePath.workflowRun,
          builder: (context, state) {
            final definition = state.extra! as WorkflowDefinition;
            return WorkflowRunPage(definition: definition);
          },
        ),
        GoRoute(
          name: AppRouteName.screenManagement,
          path: AppRoutePath.screenManagement,
          builder: (context, state) {
            final authRepo = getIt<AuthRepositoryContract>();
            return ScreenManagementPage(
              userId: authRepo.currentSession?.user.id ?? '',
            );
          },
        ),
      ],
    ),
  ],
);
