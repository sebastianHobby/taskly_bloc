import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';

class TaskDetailSheet extends StatefulWidget {
  const TaskDetailSheet({
    this.defaultProjectId,
    super.key,
  });

  final String? defaultProjectId;

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet>
    with FormSubmissionMixin {
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
          initialDataLoadSuccess: (availableProjects, availableValues) =>
              TaskForm(
                formKey: _formKey,
                onSubmit: () {
                  final formValues = validateAndGetFormValues(_formKey);
                  if (formValues == null) return;

                  final name = extractStringValue(formValues, 'name');
                  final description = extractNullableStringValue(
                    formValues,
                    'description',
                  );
                  final projectIdCandidate = extractNullableStringValue(
                    formValues,
                    'projectId',
                  );
                  final projectId =
                      (projectIdCandidate == null || projectIdCandidate.isEmpty)
                      ? null
                      : projectIdCandidate;
                  final repeatCandidate = extractNullableStringValue(
                    formValues,
                    'repeatIcalRrule',
                  );
                  final repeatIcalRrule =
                      (repeatCandidate == null || repeatCandidate.isEmpty)
                      ? null
                      : repeatCandidate;
                  final startDate = extractDateTimeValue(
                    formValues,
                    'startDate',
                  );
                  final deadlineDate = extractDateTimeValue(
                    formValues,
                    'deadlineDate',
                  );
                  final priority = formValues['priority'] as int?;
                  final valueIds = extractStringListValue(
                    formValues,
                    'valueIds',
                  );

                  context.read<TaskDetailBloc>().add(
                    TaskDetailEvent.create(
                      name: name,
                      description: description,
                      completed: extractBoolValue(formValues, 'completed'),
                      startDate: startDate,
                      deadlineDate: deadlineDate,
                      projectId: projectId,
                      priority: priority,
                      repeatIcalRrule: repeatIcalRrule,
                      valueIds: valueIds,
                    ),
                  );
                },
                submitTooltip: context.l10n.actionCreate,
                availableProjects: availableProjects,
                availableValues: availableValues,
                defaultProjectId: widget.defaultProjectId,
                onClose: () => Navigator.of(context).maybePop(),
              ),
          loadSuccess:
              (
                availableProjects,
                availableValues,
                task,
              ) => TaskForm(
                initialData: task,
                formKey: _formKey,
                onSubmit: () {
                  final formValues = validateAndGetFormValues(_formKey);
                  if (formValues == null) return;
                  final name = extractStringValue(formValues, 'name');
                  final description = extractNullableStringValue(
                    formValues,
                    'description',
                  );
                  final projectIdCandidate = extractNullableStringValue(
                    formValues,
                    'projectId',
                  );
                  final projectId =
                      (projectIdCandidate == null || projectIdCandidate.isEmpty)
                      ? null
                      : projectIdCandidate;
                  final repeatCandidate = extractNullableStringValue(
                    formValues,
                    'repeatIcalRrule',
                  );
                  final repeatIcalRrule =
                      (repeatCandidate == null || repeatCandidate.isEmpty)
                      ? null
                      : repeatCandidate;
                  final startDate = extractDateTimeValue(
                    formValues,
                    'startDate',
                  );
                  final deadlineDate = extractDateTimeValue(
                    formValues,
                    'deadlineDate',
                  );
                  final priority = formValues['priority'] as int?;
                  final valueIds = extractStringListValue(
                    formValues,
                    'valueIds',
                  );

                  context.read<TaskDetailBloc>().add(
                    TaskDetailEvent.update(
                      id: task.id,
                      name: name,
                      description: description,
                      completed: extractBoolValue(formValues, 'completed'),
                      startDate: startDate,
                      deadlineDate: deadlineDate,
                      projectId: projectId,
                      priority: priority,
                      repeatIcalRrule: repeatIcalRrule,
                      valueIds: valueIds,
                    ),
                  );
                },
                onDelete: () async {
                  final confirmed = await showDeleteConfirmationDialog(
                    context: context,
                    title: 'Delete Task',
                    itemName: task.name,
                    description: 'This action cannot be undone.',
                  );
                  if (confirmed && context.mounted) {
                    context.read<TaskDetailBloc>().add(
                      TaskDetailEvent.delete(id: task.id),
                    );
                  }
                },
                submitTooltip: context.l10n.actionUpdate,
                availableProjects: availableProjects,
                availableValues: availableValues,
                defaultProjectId: widget.defaultProjectId,
                onClose: () => Navigator.of(context).maybePop(),
              ),
          operationSuccess: (_) => const SizedBox.shrink(),
          operationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}
