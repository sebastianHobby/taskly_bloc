// drift types are provided by the generated database import below
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_form.dart';

class TaskDetailSheet extends StatefulWidget {
  const TaskDetailSheet({
    super.key,
  });

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  // Create a global key that uniquely identifies the Form widget
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) =>
          current is TaskDetailOperationSuccess ||
          current is TaskDetailOperationFailure,
      listener: (context, state) {
        state.maybeWhen(
          operationSuccess: (operation) {
            final message = switch (operation) {
              EntityOperation.create => context.l10n.taskCreatedSuccessfully,
              EntityOperation.update => context.l10n.taskUpdatedSuccessfully,
              EntityOperation.delete => context.l10n.taskDeletedSuccessfully,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            unawaited(Navigator.of(context).maybePop());
          },
          operationFailure: (errorDetails) {
            final message = friendlyErrorMessageForUi(
              errorDetails.error,
              context.l10n,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          orElse: () {},
        );
      },
      buildWhen: (previous, current) =>
          current is TaskDetailInitial ||
          current is TaskDetailLoadInProgress ||
          current is TaskDetailInitialDataLoadSuccess ||
          current is TaskDetailLoadSuccess,
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loadInProgress: () =>
              const Center(child: CircularProgressIndicator()),
          initialDataLoadSuccess: (availableProjects, availableLabels) =>
              TaskForm(
                formKey: _formKey,
                onSubmit: () {
                  final formState = _formKey.currentState;
                  if (formState == null) return;
                  if (!formState.saveAndValidate()) return;
                  final formValues = formState.value;
                  final name = formValues['name'] as String;
                  final description = formValues['description'] as String?;
                  final projectIdCandidate = formValues['projectId'] as String?;
                  final projectId =
                      (projectIdCandidate == null || projectIdCandidate.isEmpty)
                      ? null
                      : projectIdCandidate;
                  final repeatCandidate =
                      (formValues['repeatIcalRrule'] as String?)?.trim();
                  final repeatIcalRrule =
                      (repeatCandidate == null || repeatCandidate.isEmpty)
                      ? null
                      : repeatCandidate;
                  final startDate = formValues['startDate'] as DateTime?;
                  final deadlineDate = formValues['deadlineDate'] as DateTime?;
                  final labelIds =
                      (formValues['labelIds'] as List<dynamic>?)
                          ?.cast<String>() ??
                      <String>[];
                  final selectedLabels = availableLabels
                      .where((l) => labelIds.contains(l.id))
                      .toList();

                  context.read<TaskDetailBloc>().add(
                    TaskDetailEvent.create(
                      name: name,
                      description: description,
                      completed: formValues['completed'] as bool? ?? false,
                      startDate: startDate,
                      deadlineDate: deadlineDate,
                      projectId: projectId,
                      repeatIcalRrule: repeatIcalRrule,
                      labels: selectedLabels,
                    ),
                  );
                },
                submitTooltip: context.l10n.actionCreate,
                availableProjects: availableProjects,
                availableLabels: availableLabels,
              ),
          loadSuccess:
              (
                availableProjects,
                availableLabels,
                task,
              ) => TaskForm(
                initialData: task,
                formKey: _formKey,
                onSubmit: () {
                  final formState = _formKey.currentState;
                  if (formState == null) return;
                  if (!formState.saveAndValidate()) return;
                  final formValues = formState.value;
                  final name = formValues['name'] as String;
                  final description = formValues['description'] as String?;
                  final projectIdCandidate = formValues['projectId'] as String?;
                  final projectId =
                      (projectIdCandidate == null || projectIdCandidate.isEmpty)
                      ? null
                      : projectIdCandidate;
                  final repeatCandidate =
                      (formValues['repeatIcalRrule'] as String?)?.trim();
                  final repeatIcalRrule =
                      (repeatCandidate == null || repeatCandidate.isEmpty)
                      ? null
                      : repeatCandidate;
                  final startDate = formValues['startDate'] as DateTime?;
                  final deadlineDate = formValues['deadlineDate'] as DateTime?;
                  final labelIds =
                      (formValues['labelIds'] as List<dynamic>?)
                          ?.cast<String>() ??
                      <String>[];
                  final selectedLabels = availableLabels
                      .where((l) => labelIds.contains(l.id))
                      .toList();

                  context.read<TaskDetailBloc>().add(
                    TaskDetailEvent.update(
                      id: task.id,
                      name: name,
                      description: description,
                      completed: formValues['completed'] as bool? ?? false,
                      startDate: startDate,
                      deadlineDate: deadlineDate,
                      projectId: projectId,
                      repeatIcalRrule: repeatIcalRrule,
                      labels: selectedLabels,
                    ),
                  );
                },
                submitTooltip: context.l10n.actionUpdate,
                availableProjects: availableProjects,
                availableLabels: availableLabels,
              ),
          operationSuccess: (_) => const SizedBox.shrink(),
          operationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}
