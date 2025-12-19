import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/features/projects/view/project_overview_view.dart';
import 'package:taskly_bloc/features/tasks/view/task_overview_page.dart';
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
              builder: (context, state) => const ProjectOverviewPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: AppRouteName.tasks,
              path: AppRoutePath.tasks,
              builder: (context, state) => const TaskOverviewPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
