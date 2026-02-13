import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_feedback.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/widgets/routine_form.dart';
import 'package:taskly_bloc/presentation/shared/mixins/form_submission_mixin.dart';
import 'package:taskly_bloc/presentation/shared/ui/confirmation_dialog_helpers.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

class RoutineDetailSheetPage extends StatelessWidget {
  const RoutineDetailSheetPage({
    required this.routineRepository,
    required this.projectRepository,
    required this.routineWriteService,
    this.routineId,
    this.defaultProjectId,
    this.openToProjectPicker = false,
    super.key,
  });

  final RoutineRepositoryContract routineRepository;
  final ProjectRepositoryContract projectRepository;
  final RoutineWriteService routineWriteService;
  final String? routineId;
  final String? defaultProjectId;
  final bool openToProjectPicker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RoutineDetailBloc(
        routineRepository: routineRepository,
        projectRepository: projectRepository,
        routineWriteService: routineWriteService,
        errorReporter: context.read<AppErrorReporter>(),
        routineId: routineId,
      ),
      lazy: false,
      child: RoutineDetailSheetView(
        routineId: routineId,
        defaultProjectId: defaultProjectId,
        openToProjectPicker: openToProjectPicker,
      ),
    );
  }
}

class RoutineDetailSheetView extends StatefulWidget {
  const RoutineDetailSheetView({
    this.routineId,
    this.defaultProjectId,
    this.openToProjectPicker = false,
    super.key,
  });

  final String? routineId;
  final String? defaultProjectId;
  final bool openToProjectPicker;

  @override
  State<RoutineDetailSheetView> createState() => _RoutineDetailSheetViewState();
}

class _RoutineDetailSheetViewState extends State<RoutineDetailSheetView>
    with FormSubmissionMixin {
  GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  String? _formRoutineId;
  RoutineDraft _draft = RoutineDraft.empty();

  void _ensureFreshFormKeyFor(String? routineId) {
    if (_formRoutineId == routineId) return;
    _formRoutineId = routineId;
    _formKey = GlobalKey<FormBuilderState>();
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

  void _syncDraftFromFormValues(Map<String, dynamic> formValues) {
    final name = extractStringValue(formValues, RoutineFieldKeys.name.id);
    final projectId = extractStringValue(
      formValues,
      RoutineFieldKeys.projectId.id,
    );
    final periodType =
        formValues[RoutineFieldKeys.periodType.id] as RoutinePeriodType? ??
        _draft.periodType;
    final scheduleMode =
        formValues[RoutineFieldKeys.scheduleMode.id] as RoutineScheduleMode? ??
        _draft.scheduleMode;
    final rawTarget = formValues[RoutineFieldKeys.targetCount.id] as int?;
    final rawScheduleDays =
        (formValues[RoutineFieldKeys.scheduleDays.id] as List<int>?) ??
        const <int>[];
    final rawScheduleMonthDays =
        (formValues[RoutineFieldKeys.scheduleMonthDays.id] as List<int>?) ??
        const <int>[];
    final scheduleTimeMinutes =
        formValues[RoutineFieldKeys.scheduleTimeMinutes.id] as int?;
    final minSpacingDays =
        formValues[RoutineFieldKeys.minSpacingDays.id] as int?;
    final restDayBuffer = formValues[RoutineFieldKeys.restDayBuffer.id] as int?;
    final isActive = extractBoolValue(
      formValues,
      RoutineFieldKeys.isActive.id,
      defaultValue: true,
    );

    final resolvedPeriodType = periodType;
    var resolvedScheduleMode = scheduleMode;
    if (resolvedPeriodType == RoutinePeriodType.day) {
      resolvedScheduleMode = RoutineScheduleMode.flexible;
    }

    var targetCount = rawTarget ?? _draft.targetCount;
    var scheduleDays = rawScheduleDays;
    var scheduleMonthDays = rawScheduleMonthDays;
    final int? resolvedMinSpacing = minSpacingDays;
    final int? resolvedRestBuffer = restDayBuffer;
    final sortedScheduleDays = scheduleDays.toSet().toList()..sort();
    scheduleDays = sortedScheduleDays;
    final sortedMonthDays = scheduleMonthDays.toSet().toList()..sort();
    scheduleMonthDays = sortedMonthDays;

    if (resolvedScheduleMode == RoutineScheduleMode.scheduled) {
      if (resolvedPeriodType == RoutinePeriodType.week) {
        targetCount = scheduleDays.length;
        scheduleMonthDays = const <int>[];
      } else if (resolvedPeriodType == RoutinePeriodType.month) {
        targetCount = scheduleMonthDays.length;
        scheduleDays = const <int>[];
      } else {
        resolvedScheduleMode = RoutineScheduleMode.flexible;
      }
    }

    _draft = _draft.copyWith(
      name: name,
      projectId: projectId,
      periodType: resolvedPeriodType,
      scheduleMode: resolvedScheduleMode,
      targetCount: targetCount,
      scheduleDays: scheduleDays,
      scheduleMonthDays: scheduleMonthDays,
      scheduleTimeMinutes: scheduleTimeMinutes,
      minSpacingDays: resolvedMinSpacing,
      restDayBuffer: resolvedRestBuffer,
      isActive: isActive,
    );
  }

  void _onSubmit(String? routineId) {
    final formValues = validateAndGetFormValues(_formKey);
    if (formValues == null) {
      unawaited(_scrollToFirstInvalidField());
      return;
    }

    _syncDraftFromFormValues(formValues);

    final bloc = context.read<RoutineDetailBloc>();
    if (routineId == null) {
      bloc.add(
        RoutineDetailEvent.create(
          command: CreateRoutineCommand(
            name: _draft.name,
            projectId: _draft.projectId,
            periodType: _draft.periodType,
            scheduleMode: _draft.scheduleMode,
            targetCount: _draft.targetCount,
            scheduleDays: _draft.scheduleDays,
            scheduleMonthDays: _draft.scheduleMonthDays,
            scheduleTimeMinutes: _draft.scheduleTimeMinutes,
            minSpacingDays: _draft.minSpacingDays,
            restDayBuffer: _draft.restDayBuffer,
            isActive: _draft.isActive,
            pausedUntilUtc: _draft.pausedUntilUtc,
          ),
        ),
      );
    } else {
      bloc.add(
        RoutineDetailEvent.update(
          command: UpdateRoutineCommand(
            id: routineId,
            name: _draft.name,
            projectId: _draft.projectId,
            periodType: _draft.periodType,
            scheduleMode: _draft.scheduleMode,
            targetCount: _draft.targetCount,
            scheduleDays: _draft.scheduleDays,
            scheduleMonthDays: _draft.scheduleMonthDays,
            scheduleTimeMinutes: _draft.scheduleTimeMinutes,
            minSpacingDays: _draft.minSpacingDays,
            restDayBuffer: _draft.restDayBuffer,
            isActive: _draft.isActive,
            pausedUntilUtc: _draft.pausedUntilUtc,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete({
    required String id,
    required String name,
  }) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: context.l10n.routineDeleteTitle,
      confirmLabel: context.l10n.deleteLabel,
      cancelLabel: context.l10n.cancelLabel,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      iconBackgroundColor: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.3),
      content: buildDeleteConfirmationContent(
        context,
        itemName: name,
        description: context.l10n.routineDeleteDescription,
      ),
    );

    if (confirmed && mounted) {
      context.read<RoutineDetailBloc>().add(RoutineDetailEvent.delete(id: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutineDetailBloc, RoutineDetailState>(
      listenWhen: (previous, current) =>
          current is RoutineDetailOperationSuccess ||
          current is RoutineDetailValidationFailure ||
          current is RoutineDetailOperationFailure,
      listener: (context, state) {
        state.mapOrNull(
          operationSuccess: (success) {
            unawaited(
              handleEditorOperationSuccess(
                context,
                operation: success.operation,
                createdMessage: context.l10n.routineCreatedSuccessfully,
                updatedMessage: context.l10n.routineUpdatedSuccessfully,
                deletedMessage: context.l10n.routineDeletedSuccessfully,
              ),
            );
          },
          validationFailure: (failure) {
            applyValidationFailureToForm(_formKey, failure.failure, context);
            unawaited(_scrollToFirstInvalidField());
          },
          operationFailure: (failure) {
            showEditorErrorSnackBar(context, failure.errorDetails.error);
          },
        );
      },
      buildWhen: (previous, current) =>
          current is RoutineDetailInitial ||
          current is RoutineDetailLoadInProgress ||
          current is RoutineDetailInitialDataLoadSuccess ||
          current is RoutineDetailLoadSuccess,
      builder: (context, state) {
        return state.maybeMap(
          initialDataLoadSuccess: (success) {
            _ensureFreshFormKeyFor(null);
            _draft = RoutineDraft.empty();
            return RoutineForm(
              formKey: _formKey,
              availableProjects: success.availableProjects,
              initialDraft: _draft,
              onChanged: _syncDraftFromFormValues,
              onSubmit: () => _onSubmit(null),
              submitTooltip: context.l10n.routineCreateCta,
              onClose: () => unawaited(closeEditor(context)),
              defaultProjectId: widget.defaultProjectId,
              openToProjectPicker: widget.openToProjectPicker,
            );
          },
          loadSuccess: (success) {
            _ensureFreshFormKeyFor(success.routine.id);
            _draft = RoutineDraft.fromRoutine(success.routine);
            return RoutineForm(
              formKey: _formKey,
              availableProjects: success.availableProjects,
              initialData: success.routine,
              onChanged: _syncDraftFromFormValues,
              onSubmit: () => _onSubmit(success.routine.id),
              onDelete: () => _onDelete(
                id: success.routine.id,
                name: success.routine.name,
              ),
              submitTooltip: context.l10n.saveLabel,
              onClose: () => unawaited(closeEditor(context)),
              defaultProjectId: widget.defaultProjectId,
            );
          },
          loadInProgress: (_) =>
              const Center(child: CircularProgressIndicator()),
          orElse: () {
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }
}
