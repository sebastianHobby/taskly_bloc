import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/shared/views/schedule_view.dart';
import 'package:taskly_bloc/core/shared/views/schedule_view_config.dart';
import 'package:taskly_bloc/core/shared/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/next_action/next_action.dart';
import 'package:taskly_bloc/features/settings/settings.dart';
import 'package:taskly_bloc/routing/routes.dart';

/// The Today page displaying tasks and projects due today or earlier.
class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

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
    );
  }
}

class _NextActionsBanner extends StatelessWidget {
  const _NextActionsBanner({required this.taskRepository});

  final TaskRepositoryContract taskRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NextActionsBloc>(
      create: (context) => NextActionsBloc(
        taskRepository: taskRepository,
        settingsBloc: context.read<SettingsBloc>(),
      )..add(const NextActionsSubscriptionRequested()),
      child: BlocBuilder<NextActionsBloc, NextActionsState>(
        builder: (context, state) {
          final hasData =
              state.status == NextActionsStatus.success && state.totalCount > 0;
          if (!hasData) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(
                  '${state.totalCount} next actions are available to start',
                ),
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
