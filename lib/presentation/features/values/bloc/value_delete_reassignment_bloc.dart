import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';

enum ValueDeleteReassignmentStep { impact, replacement }

enum ValueDeleteReassignmentStatus {
  loading,
  ready,
  submitting,
  success,
  error,
}

sealed class ValueDeleteReassignmentEvent {
  const ValueDeleteReassignmentEvent();
}

final class ValueDeleteReassignmentStarted
    extends ValueDeleteReassignmentEvent {
  const ValueDeleteReassignmentStarted();
}

final class ValueDeleteReassignmentContinuePressed
    extends ValueDeleteReassignmentEvent {
  const ValueDeleteReassignmentContinuePressed();
}

final class ValueDeleteReassignmentBackPressed
    extends ValueDeleteReassignmentEvent {
  const ValueDeleteReassignmentBackPressed();
}

final class ValueDeleteReassignmentReplacementSelected
    extends ValueDeleteReassignmentEvent {
  const ValueDeleteReassignmentReplacementSelected(this.replacementValueId);

  final String replacementValueId;
}

final class ValueDeleteReassignmentReplacementCreated
    extends ValueDeleteReassignmentEvent {
  const ValueDeleteReassignmentReplacementCreated(this.createdValueId);

  final String createdValueId;
}

final class ValueDeleteReassignmentConfirmPressed
    extends ValueDeleteReassignmentEvent {
  const ValueDeleteReassignmentConfirmPressed();
}

final class ValueDeleteReassignmentState {
  const ValueDeleteReassignmentState({
    required this.status,
    required this.step,
    required this.valueId,
    required this.valueName,
    required this.affectedProjects,
    required this.replacementValues,
    required this.selectedReplacementValueId,
    this.error,
    this.reassignedProjectCount = 0,
  });

  factory ValueDeleteReassignmentState.initial({
    required String valueId,
    required String valueName,
  }) {
    return ValueDeleteReassignmentState(
      status: ValueDeleteReassignmentStatus.loading,
      step: ValueDeleteReassignmentStep.impact,
      valueId: valueId,
      valueName: valueName,
      affectedProjects: const <Project>[],
      replacementValues: const <Value>[],
      selectedReplacementValueId: null,
    );
  }

  final ValueDeleteReassignmentStatus status;
  final ValueDeleteReassignmentStep step;
  final String valueId;
  final String valueName;
  final List<Project> affectedProjects;
  final List<Value> replacementValues;
  final String? selectedReplacementValueId;
  final Object? error;
  final int reassignedProjectCount;

  bool get canConfirm =>
      selectedReplacementValueId != null &&
      selectedReplacementValueId!.trim().isNotEmpty &&
      status != ValueDeleteReassignmentStatus.submitting;

  ValueDeleteReassignmentState copyWith({
    ValueDeleteReassignmentStatus? status,
    ValueDeleteReassignmentStep? step,
    String? valueName,
    List<Project>? affectedProjects,
    List<Value>? replacementValues,
    Object? error = _unset,
    Object? selectedReplacementValueId = _unset,
    int? reassignedProjectCount,
  }) {
    return ValueDeleteReassignmentState(
      status: status ?? this.status,
      step: step ?? this.step,
      valueId: valueId,
      valueName: valueName ?? this.valueName,
      affectedProjects: affectedProjects ?? this.affectedProjects,
      replacementValues: replacementValues ?? this.replacementValues,
      selectedReplacementValueId: identical(selectedReplacementValueId, _unset)
          ? this.selectedReplacementValueId
          : selectedReplacementValueId as String?,
      error: identical(error, _unset) ? this.error : error,
      reassignedProjectCount:
          reassignedProjectCount ?? this.reassignedProjectCount,
    );
  }
}

const Object _unset = Object();

class ValueDeleteReassignmentBloc
    extends Bloc<ValueDeleteReassignmentEvent, ValueDeleteReassignmentState> {
  ValueDeleteReassignmentBloc({
    required ValueRepositoryContract valueRepository,
    required ProjectRepositoryContract projectRepository,
    required ValueWriteService valueWriteService,
    required AppErrorReporter errorReporter,
    required String valueId,
    required String valueName,
  }) : _valueRepository = valueRepository,
       _projectRepository = projectRepository,
       _valueWriteService = valueWriteService,
       _errorReporter = errorReporter,
       super(
         ValueDeleteReassignmentState.initial(
           valueId: valueId,
           valueName: valueName,
         ),
       ) {
    on<ValueDeleteReassignmentStarted>(_onStarted);
    on<ValueDeleteReassignmentContinuePressed>(_onContinuePressed);
    on<ValueDeleteReassignmentBackPressed>(_onBackPressed);
    on<ValueDeleteReassignmentReplacementSelected>(_onReplacementSelected);
    on<ValueDeleteReassignmentReplacementCreated>(_onReplacementCreated);
    on<ValueDeleteReassignmentConfirmPressed>(_onConfirmPressed);
  }

  final ValueRepositoryContract _valueRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueWriteService _valueWriteService;
  final AppErrorReporter _errorReporter;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> _onStarted(
    ValueDeleteReassignmentStarted event,
    Emitter<ValueDeleteReassignmentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ValueDeleteReassignmentStatus.loading,
        error: null,
      ),
    );
    await _reloadState(emit);
  }

  void _onContinuePressed(
    ValueDeleteReassignmentContinuePressed event,
    Emitter<ValueDeleteReassignmentState> emit,
  ) {
    emit(state.copyWith(step: ValueDeleteReassignmentStep.replacement));
  }

  void _onBackPressed(
    ValueDeleteReassignmentBackPressed event,
    Emitter<ValueDeleteReassignmentState> emit,
  ) {
    emit(state.copyWith(step: ValueDeleteReassignmentStep.impact));
  }

  void _onReplacementSelected(
    ValueDeleteReassignmentReplacementSelected event,
    Emitter<ValueDeleteReassignmentState> emit,
  ) {
    emit(
      state.copyWith(
        selectedReplacementValueId: event.replacementValueId,
        error: null,
      ),
    );
  }

  Future<void> _onReplacementCreated(
    ValueDeleteReassignmentReplacementCreated event,
    Emitter<ValueDeleteReassignmentState> emit,
  ) async {
    await _reloadState(
      emit,
      preferredReplacementValueId: event.createdValueId,
    );
  }

  Future<void> _onConfirmPressed(
    ValueDeleteReassignmentConfirmPressed event,
    Emitter<ValueDeleteReassignmentState> emit,
  ) async {
    final replacementValueId = state.selectedReplacementValueId?.trim();
    if (replacementValueId == null || replacementValueId.isEmpty) return;

    final context = _contextFactory.create(
      feature: 'values',
      screen: 'value_delete_reassignment_sheet',
      intent: 'value_delete_with_reassignment',
      operation: 'values.reassign_projects_and_delete',
      entityType: 'value',
      entityId: state.valueId,
      extraFields: <String, Object?>{
        'replacementValueId': replacementValueId,
      },
    );

    emit(
      state.copyWith(
        status: ValueDeleteReassignmentStatus.submitting,
        error: null,
      ),
    );

    try {
      final reassigned = await _valueWriteService.reassignProjectsAndDelete(
        valueId: state.valueId,
        replacementValueId: replacementValueId,
        context: context,
      );
      emit(
        state.copyWith(
          status: ValueDeleteReassignmentStatus.success,
          reassignedProjectCount: reassigned,
          error: null,
        ),
      );
    } catch (error, stackTrace) {
      if (error is AppFailure && error.reportAsUnexpected) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: context,
          message: 'Value reassignment delete failed (unexpected failure)',
        );
      } else if (error is! AppFailure) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: context,
          message: 'Value reassignment delete failed (unmapped exception)',
        );
      }
      emit(
        state.copyWith(
          status: ValueDeleteReassignmentStatus.error,
          error: error,
        ),
      );
    }
  }

  Future<void> _reloadState(
    Emitter<ValueDeleteReassignmentState> emit, {
    String? preferredReplacementValueId,
  }) async {
    try {
      final value = await _valueRepository.getById(state.valueId);
      final affectedProjects = await _projectRepository.getAll(
        ProjectQuery.byValues(<String>[state.valueId]),
      );
      final values = await _valueRepository.getAll();
      values.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      final replacementValues = values
          .where((candidate) => candidate.id != state.valueId)
          .toList(growable: false);

      String? selected = state.selectedReplacementValueId;
      if (preferredReplacementValueId != null &&
          replacementValues.any((v) => v.id == preferredReplacementValueId)) {
        selected = preferredReplacementValueId;
      } else if (selected == null || selected.trim().isEmpty) {
        if (replacementValues.isNotEmpty) {
          selected = replacementValues.first.id;
        }
      } else if (!replacementValues.any((v) => v.id == selected)) {
        selected = replacementValues.isEmpty
            ? null
            : replacementValues.first.id;
      }

      emit(
        state.copyWith(
          status: ValueDeleteReassignmentStatus.ready,
          valueName: value?.name ?? state.valueName,
          affectedProjects: affectedProjects,
          replacementValues: replacementValues,
          selectedReplacementValueId: selected,
          error: null,
        ),
      );
    } catch (error, stackTrace) {
      if (error is AppFailure && error.reportAsUnexpected) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          message: 'Load value reassignment delete data failed',
        );
      } else if (error is! AppFailure) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          message: 'Load value reassignment delete data failed (unmapped)',
        );
      }
      emit(
        state.copyWith(
          status: ValueDeleteReassignmentStatus.error,
          error: error,
        ),
      );
    }
  }
}
