import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/core/routing/widgets/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/domain/repositories/problem_acknowledgments_repository.dart';
import 'package:taskly_bloc/domain/repositories/workflow_item_reviews_repository.dart';
import 'package:taskly_bloc/domain/repositories/workflow_sessions_repository.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/presentation/features/auth/auth.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_page.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/navigation_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/features/navigation/view/navigation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/next_actions_settings_page.dart';
import 'package:taskly_bloc/presentation/features/projects/projects.dart';
import 'package:taskly_bloc/presentation/features/screens/view/screen_host_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/tracker_management/tracker_management_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/tracker_management_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/wellbeing_dashboard_screen.dart';
import 'package:taskly_bloc/domain/repositories/wellbeing_repository.dart';

final router = GoRouter(
  initialLocation: '${AppRoutePath.screenBase}/inbox',
  redirect: (context, state) async {
    final authRepository = getIt<AuthRepositoryContract>();
    final authState = await authRepository.watchAuthState().first;
    final isAuthenticated = authState.session != null;

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
        return BlocProvider(
          create: (_) => NavigationBloc(
            screensRepository: getIt<ScreenDefinitionsRepository>(),
            badgeService: NavigationBadgeService(
              queryBuilder: getIt<ScreenQueryBuilder>(),
              taskRepository: getIt<TaskRepositoryContract>(),
              projectRepository: getIt<ProjectRepositoryContract>(),
            ),
            iconResolver: const NavigationIconResolver(),
            routeBuilder: (screenId) => '${AppRoutePath.screenBase}/$screenId',
          )..add(const NavigationStarted()),
          child: ScaffoldWithNestedNavigation(
            activeScreenId: state.pathParameters['screenId'],
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
            screensRepository: getIt<ScreenDefinitionsRepository>(),
            queryBuilder: getIt<ScreenQueryBuilder>(),
            supportBlockComputer: getIt<SupportBlockComputer>(),
            workflowSessionsRepository: getIt<WorkflowSessionsRepository>(),
            workflowItemReviewsRepository:
                getIt<WorkflowItemReviewsRepository>(),
            problemAcknowledgmentsRepository:
                getIt<ProblemAcknowledgmentsRepository>(),
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
            screensRepository: getIt<ScreenDefinitionsRepository>(),
          ),
        ),
        GoRoute(
          name: AppRouteName.appSettings,
          path: AppRoutePath.appSettings,
          builder: (context, state) => const SettingsScreen(),
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
          name: AppRouteName.taskNextActionsSettings,
          path: AppRoutePath.taskNextActionsSettings,
          builder: (context, state) => const NextActionsSettingsPage(),
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
              getIt<WellbeingRepository>(),
            ),
            child: const JournalScreen(),
          ),
        ),
        GoRoute(
          name: AppRouteName.trackerManagement,
          path: AppRoutePath.trackerManagement,
          builder: (context, state) => BlocProvider(
            create: (context) => TrackerManagementBloc(
              getIt<WellbeingRepository>(),
            ),
            child: const TrackerManagementScreen(),
          ),
        ),
      ],
    ),
  ],
);
