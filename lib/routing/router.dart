import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/labels/labels.dart';
import 'package:taskly_bloc/features/projects/projects.dart';
import 'package:taskly_bloc/features/tasks/tasks.dart';
import 'package:taskly_bloc/features/values/values.dart';
import 'package:taskly_bloc/routing/routes.dart';
import 'package:taskly_bloc/routing/widgets/scaffold_with_nested_navigation.dart';

final router = GoRouter(
  initialLocation: AppRoutePath.projects,
  routes: [
    StatefulShellRoute.indexedStack(
      // A builder that adds a navigation bar or rail depending on screen size
      // to all the branches below
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.projects,
              path: AppRoutePath.projects,
              builder: (context, state) => ProjectOverviewPage(
                projectRepository: getIt<ProjectRepositoryContract>(),
                valueRepository: getIt<ValueRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
              ),
              routes: [
                GoRoute(
                  name: AppRouteName.projectDetail,
                  path: ':projectId',
                  builder: (context, state) => ProjectDetailPage(
                    projectId: state.pathParameters['projectId']!,
                    projectRepository: getIt<ProjectRepositoryContract>(),
                    taskRepository: getIt<TaskRepositoryContract>(),
                    valueRepository: getIt<ValueRepositoryContract>(),
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
              name: AppRouteName.inbox,
              path: AppRoutePath.inbox,
              builder: (context, state) => InboxPage(
                taskRepository: getIt<TaskRepositoryContract>(),
                projectRepository: getIt<ProjectRepositoryContract>(),
                valueRepository: getIt<ValueRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
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
                valueRepository: getIt<ValueRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
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
                valueRepository: getIt<ValueRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.tasks,
              path: AppRoutePath.tasks,
              builder: (context, state) => TaskOverviewPage(
                taskRepository: getIt<TaskRepositoryContract>(),
                projectRepository: getIt<ProjectRepositoryContract>(),
                valueRepository: getIt<ValueRepositoryContract>(),
                labelRepository: getIt<LabelRepositoryContract>(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.values,
              path: AppRoutePath.values,
              builder: (context, state) => ValueOverviewPage(
                valueRepository: getIt<ValueRepositoryContract>(),
              ),
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
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
