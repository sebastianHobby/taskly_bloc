import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/features/auth/auth.dart';
import 'package:taskly_bloc/features/labels/labels.dart';
import 'package:taskly_bloc/features/next_action/next_action.dart';
import 'package:taskly_bloc/features/projects/projects.dart';
import 'package:taskly_bloc/features/next_action/view/next_actions_settings_page.dart';
import 'package:taskly_bloc/features/tasks/tasks.dart';
import 'package:taskly_bloc/routing/routes.dart';
import 'package:taskly_bloc/routing/widgets/scaffold_with_nested_navigation.dart';

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
                sortAdapter: PageSortAdapter(
                  settingsRepository: getIt<SettingsRepositoryContract>(),
                  pageKey: SettingsPageKey.inbox,
                ),
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
                sortAdapter: PageSortAdapter(
                  settingsRepository: getIt<SettingsRepositoryContract>(),
                  pageKey: SettingsPageKey.today,
                ),
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
                sortAdapter: PageSortAdapter(
                  settingsRepository: getIt<SettingsRepositoryContract>(),
                  pageKey: SettingsPageKey.upcoming,
                ),
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
                sortAdapter: PageSortAdapter(
                  settingsRepository: getIt<SettingsRepositoryContract>(),
                  pageKey: SettingsPageKey.projects,
                ),
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
            GoRoute(
              name: AppRouteName.tasks,
              path: AppRoutePath.tasks,
              builder: (context, state) => TaskOverviewPage(
                taskRepository: getIt<TaskRepositoryContract>(),
                projectRepository: getIt<ProjectRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
                sortAdapter: PageSortAdapter(
                  settingsRepository: getIt<SettingsRepositoryContract>(),
                  pageKey: SettingsPageKey.tasks,
                ),
              ),
            ),
            GoRoute(
              name: AppRouteName.labels,
              path: AppRoutePath.labels,
              builder: (context, state) => LabelOverviewPage(
                labelRepository: getIt<LabelRepositoryContract>(),
                sortAdapter: PageSortAdapter(
                  settingsRepository: getIt<SettingsRepositoryContract>(),
                  pageKey: SettingsPageKey.labels,
                ),
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
            GoRoute(
              name: AppRouteName.values,
              path: AppRoutePath.values,
              builder: (context, state) => ValueOverviewPage(
                labelRepository: getIt<LabelRepositoryContract>(),
                sortAdapter: PageSortAdapter(
                  settingsRepository: getIt<SettingsRepositoryContract>(),
                  pageKey: SettingsPageKey.values,
                ),
              ),
            ),

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
      ],
    ),
  ],
);
