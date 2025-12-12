import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/features/projects/view/projects_page.dart';
import 'package:taskly_bloc/routing/routes.dart';

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const ProjectsPage(),
    ),
  ],
);
