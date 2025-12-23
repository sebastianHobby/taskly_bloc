import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/shared/views/schedule_view.dart';
import 'package:taskly_bloc/core/shared/views/schedule_view_config.dart';
import 'package:taskly_bloc/core/shared/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

/// The Upcoming page displaying tasks and projects due in the future.
class UpcomingPage extends StatelessWidget {
  const UpcomingPage({
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
      config: UpcomingScheduleConfig(
        titleBuilder: (context) => context.l10n.upcomingTitle,
        emptyStateBuilder: (context) => EmptyStateWidget.upcoming(
          title: context.l10n.emptyUpcomingTitle,
          description: context.l10n.emptyUpcomingDescription,
        ),
      ),
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      labelRepository: labelRepository,
    );
  }
}
