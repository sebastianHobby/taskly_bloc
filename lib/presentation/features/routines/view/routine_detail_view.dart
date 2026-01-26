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
    required this.valueRepository,
    required this.routineWriteService,
    this.routineId,
    super.key,
  });

  final RoutineRepositoryContract routineRepository;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final RoutineWriteService routineWriteService;
  final String? routineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RoutineDetailBloc(
        routineRepository: routineRepository,
        projectRepository: projectRepository,
        valueRepository: valueRepository,
        routineWriteService: routineWriteService,
        errorReporter: context.read<AppErrorReporter>(),
        routineId: routineId,
      ),
      lazy: false,
      child: RoutineDetailSheetView(routineId: routineId),
    );
  }
}

class RoutineDetailSheetView extends StatefulWidget {
  const RoutineDetailSheetView({
    this.routineId,
    super.key,
  });

  final String? routineId;

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
    final valueId = extractStringValue(
      formValues,
      RoutineFieldKeys.valueId.id,
    );
    final projectId = extractNullableStringValue(
      formValues,
      RoutineFieldKeys.projectId.id,
    );
    final routineType =
        formValues[RoutineFieldKeys.routineType.id] as RoutineType? ??
        _draft.routineType;

    final rawTarget = formValues[RoutineFieldKeys.targetCount.id] as int?;
    final rawScheduleDays =
        (formValues[RoutineFieldKeys.scheduleDays.id] as List<int>?) ??
        const <int>[];
    final rawPreferredWeeks =
        (formValues[RoutineFieldKeys.preferredWeeks.id] as List<int>?) ??
        const <int>[];
    final minSpacingDays =
        formValues[RoutineFieldKeys.minSpacingDays.id] as int?;
    final restDayBuffer = formValues[RoutineFieldKeys.restDayBuffer.id] as int?;
    final fixedDayOfMonth =
        formValues[RoutineFieldKeys.fixedDayOfMonth.id] as int?;
    final fixedWeekday = formValues[RoutineFieldKeys.fixedWeekday.id] as int?;
    final fixedWeekOfMonth =
        formValues[RoutineFieldKeys.fixedWeekOfMonth.id] as int?;
    final isActive = extractBoolValue(
      formValues,
      RoutineFieldKeys.isActive.id,
      defaultValue: true,
    );

    var targetCount = rawTarget ?? _draft.targetCount;
    var scheduleDays = rawScheduleDays;
    var preferredWeeks = rawPreferredWeeks;
    int? resolvedMinSpacing = minSpacingDays;
    int? resolvedRestBuffer = restDayBuffer;
    int? resolvedFixedDay = fixedDayOfMonth;
    int? resolvedFixedWeekday = fixedWeekday;
    int? resolvedFixedWeekOfMonth = fixedWeekOfMonth;

    switch (routineType) {
      case RoutineType.weeklyFixed:
        final sorted = scheduleDays.toSet().toList()..sort();
        scheduleDays = sorted;
        targetCount = sorted.length;
        preferredWeeks = const <int>[];
        resolvedMinSpacing = null;
        resolvedRestBuffer = null;
        resolvedFixedDay = null;
        resolvedFixedWeekday = null;
        resolvedFixedWeekOfMonth = null;
      case RoutineType.weeklyFlexible:
        final sorted = scheduleDays.toSet().toList()..sort();
        scheduleDays = sorted;
        resolvedMinSpacing = null;
        resolvedRestBuffer = null;
        preferredWeeks = const <int>[];
        resolvedFixedDay = null;
        resolvedFixedWeekday = null;
        resolvedFixedWeekOfMonth = null;
      case RoutineType.monthlyFlexible:
        scheduleDays = const <int>[];
        resolvedMinSpacing = null;
        resolvedRestBuffer = null;
        resolvedFixedDay = null;
        resolvedFixedWeekday = null;
        resolvedFixedWeekOfMonth = null;
        final sortedWeeks = preferredWeeks.toSet().toList()..sort();
        preferredWeeks = sortedWeeks;
      case RoutineType.monthlyFixed:
        scheduleDays = const <int>[];
        preferredWeeks = const <int>[];
        resolvedMinSpacing = null;
        resolvedRestBuffer = null;
        targetCount = 1;
        if (resolvedFixedDay != null) {
          resolvedFixedWeekday = null;
          resolvedFixedWeekOfMonth = null;
        } else if (resolvedFixedWeekday != null ||
            resolvedFixedWeekOfMonth != null) {
          resolvedFixedDay = null;
        }
    }

    _draft = _draft.copyWith(
      name: name,
      valueId: valueId,
      projectId: projectId,
      routineType: routineType,
      targetCount: targetCount,
      scheduleDays: scheduleDays,
      minSpacingDays: resolvedMinSpacing,
      restDayBuffer: resolvedRestBuffer,
      preferredWeeks: preferredWeeks,
      fixedDayOfMonth: resolvedFixedDay,
      fixedWeekday: resolvedFixedWeekday,
      fixedWeekOfMonth: resolvedFixedWeekOfMonth,
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
            valueId: _draft.valueId,
            projectId: _draft.projectId,
            routineType: _draft.routineType,
            targetCount: _draft.targetCount,
            scheduleDays: _draft.scheduleDays,
            minSpacingDays: _draft.minSpacingDays,
            restDayBuffer: _draft.restDayBuffer,
            preferredWeeks: _draft.preferredWeeks,
            fixedDayOfMonth: _draft.fixedDayOfMonth,
            fixedWeekday: _draft.fixedWeekday,
            fixedWeekOfMonth: _draft.fixedWeekOfMonth,
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
            valueId: _draft.valueId,
            projectId: _draft.projectId,
            routineType: _draft.routineType,
            targetCount: _draft.targetCount,
            scheduleDays: _draft.scheduleDays,
            minSpacingDays: _draft.minSpacingDays,
            restDayBuffer: _draft.restDayBuffer,
            preferredWeeks: _draft.preferredWeeks,
            fixedDayOfMonth: _draft.fixedDayOfMonth,
            fixedWeekday: _draft.fixedWeekday,
            fixedWeekOfMonth: _draft.fixedWeekOfMonth,
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
              availableValues: success.availableValues,
              initialDraft: _draft,
              onChanged: _syncDraftFromFormValues,
              onSubmit: () => _onSubmit(null),
              submitTooltip: context.l10n.actionCreate,
              onClose: () => unawaited(closeEditor(context)),
            );
          },
          loadSuccess: (success) {
            _ensureFreshFormKeyFor(success.routine.id);
            _draft = RoutineDraft.fromRoutine(success.routine);
            return RoutineForm(
              formKey: _formKey,
              availableProjects: success.availableProjects,
              availableValues: success.availableValues,
              initialData: success.routine,
              onChanged: _syncDraftFromFormValues,
              onSubmit: () => _onSubmit(success.routine.id),
              onDelete: () => _onDelete(
                id: success.routine.id,
                name: success.routine.name,
              ),
              submitTooltip: context.l10n.actionUpdate,
              onClose: () => unawaited(closeEditor(context)),
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
