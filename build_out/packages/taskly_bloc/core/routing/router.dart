import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/services/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/auth/auth.dart';
import 'package:taskly_bloc/presentation/features/labels/labels.dart';
import 'package:taskly_bloc/presentation/features/next_action/next_action.dart';
import 'package:taskly_bloc/presentation/features/projects/projects.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/next_actions_settings_page.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/services/review_action_service.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/blocs/review_detail/review_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/blocs/reviews_list/reviews_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/screens/reviews_list_screen.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/screens/review_detail_screen.dart';
import 'package:taskly_bloc/presentation/features/tasks/tasks.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/repositories/wellbeing_repository.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/presentation/blocs/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/presentation/blocs/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/presentation/screens/wellbeing_dashboard_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/presentation/screens/journal_screen.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/core/routing/widgets/scaffold_with_nested_navigation.dart';

final router = GoRouter(
  initialLocation: AppRoutePath.inbox,
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
    // Protected routes
    StatefulShellRoute.indexedStack(
      // A builder that adds a navigation bar or rail depending on screen size
      // to all the branches below
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(
          navigationShell: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.inbox,
              path: AppRoutePath.inbox,
              builder: (context, state) => InboxPage(
                taskRepository: getIt<TaskRepositoryContract>(),
                projectRepository: getIt<ProjectRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
                settingsRepository: getIt<SettingsRepositoryContract>(),
                pageKey: PageKey.tasksInbox,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.today,
              path: AppRoutePath.today,
              builder: (context, state) => TodayPage(
                taskRepository: getIt<TaskRepositoryContract>(),
                projectRepository: getIt<ProjectRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
                settingsRepository: getIt<SettingsRepositoryContract>(),
                pageKey: PageKey.tasksToday,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.upcoming,
              path: AppRoutePath.upcoming,
              builder: (context, state) => UpcomingPage(
                taskRepository: getIt<TaskRepositoryContract>(),
                projectRepository: getIt<ProjectRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
                settingsRepository: getIt<SettingsRepositoryContract>(),
                pageKey: PageKey.tasksUpcoming,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.projects,
              path: AppRoutePath.projects,
              builder: (context, state) => ProjectOverviewPage(
                projectRepository: getIt<ProjectRepositoryContract>(),
                taskRepository: getIt<TaskRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
                settingsRepository: getIt<SettingsRepositoryContract>(),
                pageKey: PageKey.projectOverview,
              ),
              routes: [
                GoRoute(
                  name: AppRouteName.projectDetail,
                  path: ':projectId',
                  builder: (context, state) => ProjectDetailPage(
                    projectId: state.pathParameters['projectId']!,
                    projectRepository: getIt<ProjectRepositoryContract>(),
                    taskRepository: getIt<TaskRepositoryContract>(),
                    labelRepository: getIt<LabelRepositoryContract>(),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.taskNextActions,
              path: AppRoutePath.taskNextActions,
              builder: (context, state) => TaskNextActionsPage(
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
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.labels,
              path: AppRoutePath.labels,
              builder: (context, state) => LabelOverviewPage(
                labelRepository: getIt<LabelRepositoryContract>(),
                settingsRepository: getIt<SettingsRepositoryContract>(),
                pageKey: PageKey.labelOverview,
              ),
              routes: [
                GoRoute(
                  name: AppRouteName.labelDetail,
                  path: ':labelId',
                  builder: (context, state) => LabelDetailPage(
                    labelId: state.pathParameters['labelId']!,
                    labelRepository: getIt<LabelRepositoryContract>(),
                    taskRepository: getIt<TaskRepositoryContract>(),
                    projectRepository: getIt<ProjectRepositoryContract>(),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.values,
              path: AppRoutePath.values,
              builder: (context, state) => ValueOverviewPage(
                labelRepository: getIt<LabelRepositoryContract>(),
                settingsRepository: getIt<SettingsRepositoryContract>(),
                pageKey: PageKey.labelValueOverview,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.reviews,
              path: AppRoutePath.reviews,
              builder: (context, state) => BlocProvider(
                create: (context) => ReviewsListBloc(
                  getIt<ReviewsRepository>(),
                ),
                child: const ReviewsListScreen(),
              ),
              routes: [
                GoRoute(
                  name: AppRouteName.reviewDetail,
                  path: ':reviewId',
                  builder: (context, state) => BlocProvider(
                    create: (context) => ReviewDetailBloc(
                      getIt<ReviewsRepository>(),
                      getIt<ReviewActionService>(),
                      getIt<TaskRepositoryContract>(),
                    ),
                    child: ReviewDetailScreen(
                      reviewId: state.pathParameters['reviewId']!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
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
          ],
        ),
      ],
    ),
  ],
);
