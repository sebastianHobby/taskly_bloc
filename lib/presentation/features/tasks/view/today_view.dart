import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/views/schedule_view.dart';
import 'package:taskly_bloc/presentation/widgets/views/schedule_view_config.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/allocation_bloc.dart';
import 'package:taskly_bloc/core/routing/routes.dart';

/// The Today page displaying tasks and projects due today or earlier.
class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    required this.settingsRepository,
    required this.pageKey,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final PageKey pageKey;

  @override
  Widget build(BuildContext context) {
    return SchedulePage(
      config: TodayScheduleConfig(
        titleBuilder: (context) => context.l10n.todayTitle,
        emptyStateBuilder: (context) => EmptyStateWidget.today(
          title: context.l10n.emptyTodayTitle,
          description: context.l10n.emptyTodayDescription,
        ),
        bannerBuilder: (context) => _NextActionsBanner(
          taskRepository: taskRepository,
        ),
      ),
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      labelRepository: labelRepository,
      settingsRepository: settingsRepository,
      sortAdapter: pageKey,
    );
  }
}

class _NextActionsBanner extends StatelessWidget {
  const _NextActionsBanner({required this.taskRepository});

  final TaskRepositoryContract taskRepository;

  @override
  Widget build(BuildContext context) {
    // Create a local AllocationBloc for the banner
    return BlocProvider(
      create: (_) => AllocationBloc(
        orchestrator: getIt<AllocationOrchestrator>(),
      )..add(const AllocationSubscriptionRequested()),
      child: BlocBuilder<AllocationBloc, AllocationState>(
        builder: (context, state) {
          final hasData = state.status == AllocationStatus.success;
          final totalCount =
              state.pinnedTasks.length +
              state.tasksByValue.values.fold(
                0,
                (sum, group) => sum + group.tasks.length,
              );

          if (!hasData || totalCount == 0) return const SizedBox.shrink();

          // Show warning if there are excluded urgent tasks
          final hasExcludedUrgent = state.excludedUrgent.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: hasExcludedUrgent
                  ? Theme.of(context).colorScheme.errorContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  hasExcludedUrgent
                      ? Icons.warning_amber_rounded
                      : Icons.play_circle_outline,
                  color: hasExcludedUrgent
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                title: Text(
                  '$totalCount next actions available',
                ),
                subtitle: hasExcludedUrgent
                    ? Text(
                        '${state.excludedUrgent.length} urgent tasks need attention',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goNamed(
                  AppRouteName.taskNextActions,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
