import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/core/routing/widgets/scaffold_with_nested_navigation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/navigation_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
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
  observers: [TalkerRouteObserver(talker), appRouteObserver],
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // Derive activeScreenId from URL segment
        final segment = state.pathParameters['segment'];
        final activeScreenId = segment != null
            ? Routing.parseScreenKey(segment)
            : null;

        // Use a constant key to prevent NavigationBloc from being recreated
        // on every ShellRoute builder call. Without a key, each navigation
        // would dispose the old BlocProvider and create a new one, closing
        // all child blocs (ScreenDefinitionBloc, TaskOverviewBloc, etc.)
        return BlocProvider(
          key: const ValueKey('navigation_bloc_provider'),
          create: (_) => NavigationBloc(
            screensRepository: getIt<ScreenDefinitionsRepositoryContract>(),
            badgeService: NavigationBadgeService(
              taskRepository: getIt<TaskRepositoryContract>(),
              projectRepository: getIt<ProjectRepositoryContract>(),
            ),
            iconResolver: const NavigationIconResolver(),
          )..add(const NavigationStarted()),
          child: ScaffoldWithNestedNavigation(
            activeScreenId: activeScreenId,
            child: child,
          ),
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
