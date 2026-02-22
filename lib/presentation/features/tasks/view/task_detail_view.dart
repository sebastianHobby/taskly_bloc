import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_feedback.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';

class TaskDetailSheet extends StatefulWidget {
  const TaskDetailSheet({
    this.defaultProjectId,
    this.defaultStartDate,
    this.defaultDeadlineDate,
    this.openToProjectPicker = false,
    this.includeInMyDayDefault = false,
    super.key,
  });

  final String? defaultProjectId;

  /// Optional planned day to prefill when creating a new task.
  final DateTime? defaultStartDate;

  /// Optional due date to prefill when creating a new task.
  final DateTime? defaultDeadlineDate;

  /// When true, scrolls to the project picker chip and opens the picker on
  /// first build.
  final bool openToProjectPicker;

  /// Defaults the include-in-My-Day toggle when creating a task.
  final bool includeInMyDayDefault;

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet>
    with FormSubmissionMixin, LocalSubmitGuardMixin {
  // Create a global key that uniquely identifies the Form widget
  final _formKey = GlobalKey<FormBuilderState>();

  TaskDraft _draft = TaskDraft.empty();
  bool _includeInMyDay = false;

  bool _isUnchangedTaskDraft(
    TaskDraft initial,
    TaskDraft next, {
    required bool initialIncludeInMyDay,
    required bool nextIncludeInMyDay,
  }) {
    return initial.name == next.name &&
        initial.description == next.description &&
        initial.completed == next.completed &&
        initial.startDate == next.startDate &&
        initial.deadlineDate == next.deadlineDate &&
        initial.projectId == next.projectId &&
        initial.priority == next.priority &&
        initial.reminderKind == next.reminderKind &&
        initial.reminderAtUtc == next.reminderAtUtc &&
        initial.reminderMinutesBeforeDue == next.reminderMinutesBeforeDue &&
        initial.repeatIcalRrule == next.repeatIcalRrule &&
        initial.repeatFromCompletion == next.repeatFromCompletion &&
        initial.seriesEnded == next.seriesEnded &&
        listEquals(initial.valueIds, next.valueIds) &&
        listEquals(initial.checklistTitles, next.checklistTitles) &&
        initialIncludeInMyDay == nextIncludeInMyDay;
  }

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

    final repeatFromCompletion = extractBoolValue(
      formValues,
      TaskFieldKeys.repeatFromCompletion.id,
    );
    final seriesEnded = extractBoolValue(
      formValues,
      TaskFieldKeys.seriesEnded.id,
    );

    final startDate = extractDateTimeValue(
      formValues,
      TaskFieldKeys.startDate.id,
    );
    final deadlineDate = extractDateTimeValue(
      formValues,
      TaskFieldKeys.deadlineDate.id,
    );
    final priority = formValues[TaskFieldKeys.priority.id] as int?;
    final reminderKind =
        formValues[TaskFieldKeys.reminderKind.id] as TaskReminderKind? ??
        TaskReminderKind.none;
    final reminderAtUtc =
        formValues[TaskFieldKeys.reminderAtUtc.id] as DateTime?;
    final reminderMinutesBeforeDue =
        formValues[TaskFieldKeys.reminderMinutesBeforeDue.id] as int?;
    final valueIds = extractStringListValue(
      formValues,
      TaskFieldKeys.valueIds.id,
    );
    final includeInMyDay = extractBoolValue(
      formValues,
      TaskFormFieldKeys.includeInMyDay,
    );
    final checklistTitles = extractStringListValue(
      formValues,
      TaskFormFieldKeys.checklistTitles,
    );

    _draft = _draft.copyWith(
      name: name,
      description: description,
      completed: completed,
      projectId: projectId,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      startDate: startDate,
      deadlineDate: deadlineDate,
      priority: priority,
      reminderKind: reminderKind,
      reminderAtUtc: reminderAtUtc,
      reminderMinutesBeforeDue: reminderMinutesBeforeDue,
      valueIds: valueIds,
      checklistTitles: checklistTitles,
    );
    _includeInMyDay = includeInMyDay;
  }

  Future<void> _scrollToFirstInvalidField() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    for (final fieldState in formState.fields.values) {
      if (!fieldState.hasError) continue;
      await Scrollable.ensureVisible(
        fieldState.context,
        alignment: 0.15,
        duration: const Duration(milliseconds: 220),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) =>
          current is TaskDetailOperationSuccess ||
          current is TaskDetailInlineActionSuccess ||
          current is TaskDetailValidationFailure ||
          current is TaskDetailOperationFailure,
      listener: (context, state) {
        if (state is TaskDetailOperationSuccess ||
            state is TaskDetailValidationFailure ||
            state is TaskDetailOperationFailure ||
            state is TaskDetailInlineActionSuccess) {
          setSubmitting(false);
        }
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
          inlineActionSuccess: (message) {
            showEditorSuccessSnackBar(context, message);
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
          inlineActionSuccess: (_) => SizedBox.shrink(),
          initialDataLoadSuccess: (availableProjects, availableValues) =>
              TaskForm(
                formKey: _formKey,
                onChanged: _syncDraftFromFormValues,
                onSubmit: () {
                  if (isSubmitting) return;
                  final formValues = validateAndGetFormValues(_formKey);
                  if (formValues == null) {
                    unawaited(_scrollToFirstInvalidField());
                    return;
                  }

                  _syncDraftFromFormValues(formValues);

                  setSubmitting(true);
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
                        reminderKind: _draft.reminderKind,
                        reminderAtUtc: _draft.reminderAtUtc,
                        reminderMinutesBeforeDue:
                            _draft.reminderMinutesBeforeDue,
                        repeatIcalRrule: _draft.repeatIcalRrule,
                        repeatFromCompletion: _draft.repeatFromCompletion,
                        seriesEnded: _draft.seriesEnded,
                        valueIds: _draft.valueIds,
                        checklistTitles: _draft.checklistTitles,
                      ),
                      includeInMyDay: _includeInMyDay,
                    ),
                  );
                },
                submitTooltip: context.l10n.addTaskAction,
                availableProjects: availableProjects,
                availableValues: availableValues,
                defaultProjectId: widget.defaultProjectId,
                defaultStartDate: widget.defaultStartDate,
                defaultDeadlineDate: widget.defaultDeadlineDate,
                includeInMyDayDefault: widget.includeInMyDayDefault,
                showMyDayToggle: true,
                isSubmitting: isSubmitting,
                initialChecklistTitles: _draft.checklistTitles,
                openToProjectPicker: widget.openToProjectPicker,
                onClose: () => unawaited(closeEditor(context)),
              ),
          loadSuccess:
              (
                availableProjects,
                availableValues,
                task,
                checklistTitles,
              ) => TaskForm(
                initialData: task,
                initialChecklistTitles: checklistTitles,
                formKey: _formKey,
                onChanged: _syncDraftFromFormValues,
                onSubmit: () {
                  if (isSubmitting) return;
                  final formValues = validateAndGetFormValues(_formKey);
                  if (formValues == null) {
                    unawaited(_scrollToFirstInvalidField());
                    return;
                  }

                  _syncDraftFromFormValues(formValues);
                  final initialDraft = TaskDraft.fromTask(
                    task,
                  ).copyWith(checklistTitles: checklistTitles);
                  if (_isUnchangedTaskDraft(
                    initialDraft,
                    _draft,
                    initialIncludeInMyDay: widget.includeInMyDayDefault,
                    nextIncludeInMyDay: _includeInMyDay,
                  )) {
                    unawaited(closeEditor(context));
                    return;
                  }

                  setSubmitting(true);
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
                        reminderKind: _draft.reminderKind,
                        reminderAtUtc: _draft.reminderAtUtc,
                        reminderMinutesBeforeDue:
                            _draft.reminderMinutesBeforeDue,
                        repeatIcalRrule: _draft.repeatIcalRrule,
                        repeatFromCompletion: _draft.repeatFromCompletion,
                        seriesEnded: _draft.seriesEnded,
                        valueIds: _draft.valueIds,
                        checklistTitles: _draft.checklistTitles,
                      ),
                    ),
                  );
                },
                trailingActions: _buildDetailActions(
                  context,
                  taskId: task.id,
                  taskName: task.name,
                  completed: task.completed,
                  isRepeating: task.isRepeating,
                  seriesEnded: task.seriesEnded,
                ),
                submitTooltip: context.l10n.saveLabel,
                availableProjects: availableProjects,
                availableValues: availableValues,
                defaultProjectId: widget.defaultProjectId,
                includeInMyDayDefault: widget.includeInMyDayDefault,
                showMyDayToggle: false,
                isSubmitting: isSubmitting,
                openToProjectPicker: widget.openToProjectPicker,
                onClose: () => unawaited(closeEditor(context)),
              ),
          operationSuccess: (_) => SizedBox.shrink(),
          operationFailure: (_) => SizedBox.shrink(),
          validationFailure: (_) => SizedBox.shrink(),
        );
      },
    );
  }

  List<Widget> _buildDetailActions(
    BuildContext context, {
    required String taskId,
    required String taskName,
    required bool completed,
    required bool isRepeating,
    required bool seriesEnded,
  }) {
    final actions = TileOverflowActionCatalog.forEntityDetail(
      l10n: context.l10n,
      entityType: EntityType.task,
      entityId: taskId,
      entityName: taskName,
      completed: completed,
      isRepeating: isRepeating,
      seriesEnded: seriesEnded,
    );

    final enabledActions = actions.where((a) => a.enabled).toList();
    if (enabledActions.isEmpty) return const <Widget>[];

    return [
      PopupMenuButton<TileOverflowActionId>(
        tooltip: context.l10n.moreLabel,
        icon: const Icon(Icons.more_horiz),
        onSelected: (actionId) async {
          final dispatcher = context.read<TileIntentDispatcher>();
          final action = actions.firstWhere((a) => a.id == actionId);
          return dispatcher.dispatch(context, action.intent);
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<TileOverflowActionId>>[];
          TileOverflowActionGroup? lastGroup;

          for (final action in actions) {
            if (lastGroup != null && action.group != lastGroup) {
              if (items.isNotEmpty) items.add(const PopupMenuDivider());
            }
            lastGroup = action.group;

            items.add(
              PopupMenuItem<TileOverflowActionId>(
                value: action.id,
                enabled: action.enabled,
                child: Text(action.label),
              ),
            );
          }

          return items;
        },
      ),
    ];
  }
}
