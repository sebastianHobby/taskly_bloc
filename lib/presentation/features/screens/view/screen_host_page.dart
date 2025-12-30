import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/domain/repositories/problem_acknowledgments_repository.dart';
import 'package:taskly_bloc/domain/repositories/workflow_item_reviews_repository.dart';
import 'package:taskly_bloc/domain/repositories/workflow_sessions_repository.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_definition_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/view/workflow_run_page.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_overview_view.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_overview_view.dart';
import 'package:taskly_bloc/presentation/features/labels/view/value_overview_view.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/next_actions_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/inbox_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/upcoming_view.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/views/schedule_view.dart';
import 'package:taskly_bloc/presentation/widgets/views/schedule_view_config.dart';

/// Hosts a persisted screen definition and renders the appropriate existing UI.
///
/// This is the bridge from persisted ScreenDefinitions -> current hardcoded
/// pages, without changing UX.
class ScreenHostPage extends StatelessWidget {
  const ScreenHostPage({
    required this.screenId,
    required this.screensRepository,
    required this.queryBuilder,
    required this.supportBlockComputer,
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    required this.settingsRepository,
    required this.workflowSessionsRepository,
    required this.workflowItemReviewsRepository,
    required this.problemAcknowledgmentsRepository,
    super.key,
  });

  final String screenId;
  final ScreenDefinitionsRepository screensRepository;
  final ScreenQueryBuilder queryBuilder;
  final SupportBlockComputer supportBlockComputer;
  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final ProblemAcknowledgmentsRepository problemAcknowledgmentsRepository;
  final WorkflowSessionsRepository workflowSessionsRepository;
  final WorkflowItemReviewsRepository workflowItemReviewsRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScreenDefinitionBloc(repository: screensRepository)
        ..add(ScreenDefinitionEvent.subscriptionRequested(screenId: screenId)),
      child: BlocBuilder<ScreenDefinitionBloc, ScreenDefinitionState>(
        builder: (context, state) {
          return state.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            notFound: () => Scaffold(
              appBar: AppBar(title: Text(context.l10n.browseTitle)),
              body: Center(
                child: Text('Screen not found: $screenId'),
              ),
            ),
            error: (error, _) => Scaffold(
              appBar: AppBar(title: Text(context.l10n.browseTitle)),
              body: Center(
                child: Text('Failed to load screen: $error'),
              ),
            ),
            loaded: (screen) => _buildForScreen(context, screen),
          );
        },
      ),
    );
  }

  Widget _buildForScreen(BuildContext context, ScreenDefinition screen) {
    return screen.map(
      collection: (collection) {
        final selector = collection.selector;
        final display = collection.display;

        // For now, keep the existing UX per system screen.
        switch (collection.screenId) {
          case 'inbox':
            final query = queryBuilder.buildTaskQuery(
              selector: selector,
              display: display,
              now: DateTime.now(),
            );
            return InboxPage(
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              labelRepository: labelRepository,
              settingsRepository: settingsRepository,
              pageKey: _pageKeyForTaskScreen(collection.screenId),
              queryOverride: query,
            );
          case 'today':
            return SchedulePage(
              config: _PersistedTodayScheduleConfig(
                titleBuilder: (context) => context.l10n.todayTitle,
                emptyStateBuilder: (context) => EmptyStateWidget.today(
                  title: context.l10n.emptyTodayTitle,
                  description: context.l10n.emptyTodayDescription,
                ),
                screen: collection,
                queryBuilder: queryBuilder,
              ),
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              labelRepository: labelRepository,
              settingsRepository: settingsRepository,
              sortAdapter: _pageKeyForTaskScreen(collection.screenId),
            );
          case 'upcoming':
            final query = queryBuilder.buildTaskQuery(
              selector: selector,
              display: display,
              now: DateTime.now(),
            );
            return UpcomingPage(
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              labelRepository: labelRepository,
              settingsRepository: settingsRepository,
              pageKey: _pageKeyForTaskScreen(collection.screenId),
              queryOverride: query,
            );
          case 'projects':
            return ProjectOverviewPage(
              projectRepository: projectRepository,
              taskRepository: taskRepository,
              labelRepository: labelRepository,
              settingsRepository: settingsRepository,
              pageKey: PageKey.projectOverview,
            );
          case 'labels':
            return LabelOverviewPage(
              labelRepository: labelRepository,
              settingsRepository: settingsRepository,
              pageKey: PageKey.labelOverview,
            );
          case 'values':
            return ValueOverviewPage(
              labelRepository: labelRepository,
              settingsRepository: settingsRepository,
              pageKey: PageKey.labelValueOverview,
            );
          case 'next_actions':
            return TaskNextActionsPage(
              projectRepository: projectRepository,
              taskRepository: taskRepository,
              labelRepository: labelRepository,
            );
          default:
            if (collection.selector.entityType != EntityType.task) {
              return Scaffold(
                appBar: AppBar(title: Text(collection.name)),
                body: Center(
                  child: Text(
                    'No renderer for ${collection.selector.entityType.name} yet.',
                  ),
                ),
              );
            }

            // Fall back to a task list-style page for other task collection
            // screens until they get their own renderer.
            final query = queryBuilder.buildTaskQuery(
              selector: selector,
              display: display,
              now: DateTime.now(),
            );
            return InboxPage(
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              labelRepository: labelRepository,
              settingsRepository: settingsRepository,
              pageKey: _pageKeyForTaskScreen(collection.screenId),
              queryOverride: query,
            );
        }
      },
      workflow: (workflow) {
        return WorkflowRunPage(
          screen: workflow,
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          labelRepository: labelRepository,
          settingsRepository: settingsRepository,
          problemAcknowledgmentsRepository: problemAcknowledgmentsRepository,
          queryBuilder: queryBuilder,
          supportBlockComputer: supportBlockComputer,
        );
      },
    );
  }
}

PageKey _pageKeyForTaskScreen(String screenId) {
  switch (screenId) {
    case 'inbox':
      return PageKey.tasksInbox;
    case 'today':
      return PageKey.tasksToday;
    case 'upcoming':
      return PageKey.tasksUpcoming;
    default:
      return PageKey.taskOverview;
  }
}

class _PersistedTodayScheduleConfig extends ScheduleViewConfig {
  _PersistedTodayScheduleConfig({
    required super.titleBuilder,
    required super.emptyStateBuilder,
    required CollectionScreen screen,
    required ScreenQueryBuilder queryBuilder,
  }) : super(
         pageKey: SettingsPageKey.today,
         taskSelectorFactory: (now, sortCriteria) {
           final base = queryBuilder.buildTaskQuery(
             selector: screen.selector,
             display: screen.display,
             now: now,
           );
           return base.copyWith(sortCriteria: sortCriteria);
         },
         projectMatcher: _matchesOnOrBeforeDay,
         defaultSortPreferences: const SortPreferences(),
         showBannerToggleInSettings: true,
       );

  static bool _matchesOnOrBeforeDay(
    DateTime? startDate,
    DateTime? deadlineDate,
    DateTime cutoffDay,
  ) {
    bool matchesDate(DateTime? candidate) {
      if (candidate == null) return false;
      final day = DateTime(candidate.year, candidate.month, candidate.day);
      return !day.isAfter(cutoffDay);
    }

    return matchesDate(startDate) || matchesDate(deadlineDate);
  }

  @override
  DateTime getCutoffDay(DateTime now) => DateTime(now.year, now.month, now.day);
}
