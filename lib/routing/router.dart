import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/features/projects/view/project_detail_view.dart';
import 'package:taskly_bloc/features/projects/view/project_list_view.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/features/tasks/view/tasks_list_view.dart';
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
    GoRoute(
      path: Routes.editTaskModal,
      pageBuilder: (context, state) {
        // Use ModalSheetPage to show a modal sheet with Navigator 2.0.
        // It works with any *Sheet provided by this package!
        return ModalSheetPage(
          key: state.pageKey,
          // Enable the swipe-to-dismiss behavior.
          swipeDismissible: true,
          // Use `SwipeDismissSensitivity` to tweak the sensitivity of the swipe-to-dismiss behavior.
          swipeDismissSensitivity: const SwipeDismissSensitivity(
            dismissalOffset: SheetOffset.proportionalToViewport(0.4),
          ),
          // You don't need a SheetViewport for the modal sheet.
          child: TaskDetailPage(
            taskCompanion: state.extra! as TaskTableCompanion,
          ),
        );
      },
    ),
    GoRoute(
      path: Routes.editProjectModal,
      pageBuilder: (context, state) {
        // Use ModalSheetPage to show a modal sheet with Navigator 2.0.
        // It works with any *Sheet provided by this package!
        return ModalSheetPage(
          key: state.pageKey,
          // Enable the   swipe-to-dismiss behavior.
          swipeDismissible: true,
          // Use `SwipeDismissSensitivity` to tweak the sensitivity of the swipe-to-dismiss behavior.
          swipeDismissSensitivity: const SwipeDismissSensitivity(
            dismissalOffset: SheetOffset.proportionalToViewport(0.4),
          ),
          // You don't need a SheetViewport for the modal sheet.
          child: ProjectDetailPage(
            projectId: state.pathParameters['projectId'],
          ),
        );
      },
    ),
  ],
);
