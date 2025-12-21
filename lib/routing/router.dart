import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/projects/view/project_overview_view.dart';
import 'package:taskly_bloc/features/tasks/view/task_overview_page.dart';
import 'package:taskly_bloc/features/values/view/value_overview_view.dart';
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
      ],
    ),
  ],
);
