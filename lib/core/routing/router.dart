import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/core/routing/widgets/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_run_page.dart';

/// Router for authenticated app shell.
///
/// Uses convention-based routing with only two patterns:
/// - **Screens**: `/:segment` → handled by [Routing.buildScreen]
/// - **Entities**: `/:entityType/:id` → handled by [Routing.buildEntityDetail]
///
/// All screen/entity builders are registered in [Routing] at bootstrap.
/// No legacy redirects - all paths are canonical.
final router = GoRouter(
  initialLocation: Routing.screenPath('my_day'),
  observers: [TalkerRouteObserver(talker.raw), appRouteObserver],
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // Derive activeScreenId from URL segment
        final segment = state.pathParameters['segment'];
        final activeScreenId = segment != null
            ? Routing.parseScreenKey(segment)
            : null;

        return ScaffoldWithNestedNavigation(
          activeScreenId: activeScreenId,
          child: child,
        );
      },
      routes: [
        // === ENTITY DETAIL ROUTES ===
        // These are parameterized routes that need IDs
        GoRoute(
          path: '/task/:id',
          builder: (_, state) => Routing.buildEntityDetail(
            'task',
            state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/project/:id',
          builder: (_, state) => Routing.buildEntityDetail(
            'project',
            state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/label/:id',
          builder: (_, state) => Routing.buildEntityDetail(
            'label',
            state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/value/:id',
          builder: (_, state) => Routing.buildEntityDetail(
            'value',
            state.pathParameters['id']!,
          ),
        ),

        // === WORKFLOW RUN (transient state, not a screen) ===
        GoRoute(
          path: '/workflow-run',
          builder: (context, state) {
            final definition = state.extra! as WorkflowDefinition;
            return WorkflowRunPage(definition: definition);
          },
        ),

        // === UNIFIED SCREEN ROUTE (convention-based catch-all) ===
        // ALL screens: my_day, settings, journal, etc.
        // Builders are registered in Routing at bootstrap.
        GoRoute(
          path: '/:segment',
          builder: (_, state) {
            final screenKey = Routing.parseScreenKey(
              state.pathParameters['segment']!,
            );
            return Routing.buildScreen(screenKey);
          },
        ),
      ],
    ),
  ],
);
