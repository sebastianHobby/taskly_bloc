import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/features/projects/view/projects_page.dart';
import 'package:taskly_bloc/features/tasks/view/tasks_page.dart';
import 'package:taskly_bloc/routing/routes.dart';
import 'package:taskly_bloc/routing/widgets/scaffold_with_nested_navigation.dart';

final router = GoRouter(
  initialLocation: Routes.projects,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.projects,
              builder: (context, state) => const ProjectsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.tasks,
              builder: (context, state) => const TasksPage(),
            ),
          ],
        ),
      ],
    ),


  ],
);
