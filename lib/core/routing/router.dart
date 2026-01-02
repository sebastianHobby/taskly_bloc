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
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/presentation/features/auth/auth.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_page.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/navigation_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/features/navigation/view/navigation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/allocation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/projects/projects.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/view/screen_host_page.dart';
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

final router = GoRouter(
  initialLocation: '${AppRoutePath.screenBase}/inbox',
  observers: [TalkerRouteObserver(talker)],
  redirect: (context, state) {
    // Use synchronous session check to avoid hanging on async stream
    final authRepository = getIt<AuthRepositoryContract>();
    final isAuthenticated = authRepository.currentSession != null;

    final isAuthRoute =
        state.matchedLocation == '/sign-in' ||
        state.matchedLocation == '/sign-up' ||
        state.matchedLocation == '/forgot-password';

    // If not authenticated and trying to access protected route, redirect to sign in
    if (!isAuthenticated && !isAuthRoute) {
      return '/sign-in';
    }

    // If authenticated and trying to access auth route, redirect to home
    if (isAuthenticated && isAuthRoute) {
      return AppRoutePath.inbox;
    }

    // No redirect needed
    return null;
  },
  routes: [
    // Authentication routes (not protected)
    GoRoute(
      name: 'sign-in',
      path: '/sign-in',
      builder: (context, state) => const SignInView(),
    ),
    GoRoute(
      name: 'sign-up',
      path: '/sign-up',
      builder: (context, state) => const SignUpView(),
    ),
    GoRoute(
      name: 'forgot-password',
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordView(),
    ),
    // Legacy aliases redirect to dynamic screen routes
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

        return BlocProvider(
          create: (_) => NavigationBloc(
            screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
            badgeService: NavigationBadgeService(
              queryBuilder: getIt<ScreenQueryBuilder>(),
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
        GoRoute(
          name: AppRouteName.screen,
          path: AppRoutePath.screen,
          builder: (context, state) => ScreenHostPage(
            screenId: state.pathParameters['screenId']!,
            screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
            queryBuilder: getIt<ScreenQueryBuilder>(),
            supportBlockComputer: getIt<SupportBlockComputer>(),
            taskRepository: getIt<TaskRepositoryContract>(),
            projectRepository: getIt<ProjectRepositoryContract>(),
            labelRepository: getIt<LabelRepositoryContract>(),
            settingsRepository: getIt<SettingsRepositoryContract>(),
          ),
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
          builder: (context, state) => ProjectDetailPage(
            projectId: state.pathParameters['projectId']!,
            projectRepository: getIt<ProjectRepositoryContract>(),
            taskRepository: getIt<TaskRepositoryContract>(),
            labelRepository: getIt<LabelRepositoryContract>(),
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
          builder: (context, state) => LabelDetailPage(
            labelId: state.pathParameters['labelId']!,
            labelRepository: getIt<LabelRepositoryContract>(),
            taskRepository: getIt<TaskRepositoryContract>(),
            projectRepository: getIt<ProjectRepositoryContract>(),
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
