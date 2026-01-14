import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_feedback.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
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

  TaskDraft _draft = TaskDraft.empty();

  void _syncDraftFromFormValues(Map<String, dynamic> formValues) {
    final name = extractStringValue(formValues, TaskFieldKeys.name.id);
    final description = extractNullableStringValue(
      formValues,
      TaskFieldKeys.description.id,
    );
    final completed = extractBoolValue(formValues, TaskFieldKeys.completed.id);

    final projectIdCandidate = extractNullableStringValue(
      formValues,
      TaskFieldKeys.projectId.id,
    );
    final projectId = (projectIdCandidate == null || projectIdCandidate.isEmpty)
        ? null
        : projectIdCandidate;

    final repeatCandidate = extractNullableStringValue(
      formValues,
      TaskFieldKeys.repeatIcalRrule.id,
    );
    final repeatIcalRrule = (repeatCandidate == null || repeatCandidate.isEmpty)
        ? null
        : repeatCandidate;

    final startDate = extractDateTimeValue(
      formValues,
      TaskFieldKeys.startDate.id,
    );
    final deadlineDate = extractDateTimeValue(
      formValues,
      TaskFieldKeys.deadlineDate.id,
    );
    final priority = formValues[TaskFieldKeys.priority.id] as int?;
    final valueIds = extractStringListValue(
      formValues,
      TaskFieldKeys.valueIds.id,
    );

    _draft = _draft.copyWith(
      name: name,
      description: description,
      completed: completed,
      projectId: projectId,
      repeatIcalRrule: repeatIcalRrule,
      startDate: startDate,
      deadlineDate: deadlineDate,
      priority: priority,
      valueIds: valueIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) =>
          current is TaskDetailOperationSuccess ||
          current is TaskDetailValidationFailure ||
          current is TaskDetailOperationFailure,
      listener: (context, state) {
        state.maybeWhen(
          operationSuccess: (operation) {
            unawaited(
              handleEditorOperationSuccess(
                context,
                operation: operation,
                createdMessage: context.l10n.taskCreatedSuccessfully,
                updatedMessage: context.l10n.taskUpdatedSuccessfully,
                deletedMessage: context.l10n.taskDeletedSuccessfully,
              ),
            );
          },
          validationFailure: (failure) {
            applyValidationFailureToForm(_formKey, failure, context);
          },
          operationFailure: (errorDetails) {
            showEditorErrorSnackBar(context, errorDetails.error);
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
                onChanged: _syncDraftFromFormValues,
                onSubmit: () {
                  final formValues = validateAndGetFormValues(_formKey);
                  if (formValues == null) return;

                  _syncDraftFromFormValues(formValues);

                  context.read<TaskDetailBloc>().add(
                    TaskDetailEvent.create(
                      command: CreateTaskCommand(
                        name: _draft.name,
                        description: _draft.description,
                        completed: _draft.completed,
                        startDate: _draft.startDate,
                        deadlineDate: _draft.deadlineDate,
                        projectId: _draft.projectId,
                        priority: _draft.priority,
                        repeatIcalRrule: _draft.repeatIcalRrule,
                        valueIds: _draft.valueIds,
                      ),
                    ),
                  );
                },
                submitTooltip: context.l10n.actionCreate,
                availableProjects: availableProjects,
                availableValues: availableValues,
                defaultProjectId: widget.defaultProjectId,
                onClose: () => unawaited(closeEditor(context)),
              ),
          loadSuccess:
              (
                availableProjects,
                availableValues,
                task,
              ) => TaskForm(
                initialData: task,
                formKey: _formKey,
                onChanged: _syncDraftFromFormValues,
                onSubmit: () {
                  final formValues = validateAndGetFormValues(_formKey);
                  if (formValues == null) return;

                  _syncDraftFromFormValues(formValues);

                  context.read<TaskDetailBloc>().add(
                    TaskDetailEvent.update(
                      command: UpdateTaskCommand(
                        id: task.id,
                        name: _draft.name,
                        description: _draft.description,
                        completed: _draft.completed,
                        startDate: _draft.startDate,
                        deadlineDate: _draft.deadlineDate,
                        projectId: _draft.projectId,
                        priority: _draft.priority,
                        repeatIcalRrule: _draft.repeatIcalRrule,
                        valueIds: _draft.valueIds,
                      ),
                    ),
                  );
                },
                onDelete: () async {
                  final confirmed = await showDeleteConfirmationDialog(
                    context: context,
                    title: context.l10n.deleteTaskAction,
                    itemName: task.name,
                    description:
                        context.l10n.deleteConfirmationIrreversibleDescription,
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
                onClose: () => unawaited(closeEditor(context)),
              ),
          operationSuccess: (_) => const SizedBox.shrink(),
          operationFailure: (_) => const SizedBox.shrink(),
          validationFailure: (_) => const SizedBox.shrink(),
        );
      },
    );
  }
}
