import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/journal_unit_catalog.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;

enum JournalTrackerWizardStep { name, scope, measurement }

enum JournalTrackerScopeOption { day, entry, sleepNight }

enum JournalTrackerMeasurementType { toggle, rating, quantity, choice }

sealed class JournalTrackerWizardEvent {
  const JournalTrackerWizardEvent();
}

final class JournalTrackerWizardStarted extends JournalTrackerWizardEvent {
  const JournalTrackerWizardStarted();
}

final class JournalTrackerWizardStepChanged extends JournalTrackerWizardEvent {
  const JournalTrackerWizardStepChanged(this.step);

  final int step;
}

final class JournalTrackerWizardNameChanged extends JournalTrackerWizardEvent {
  const JournalTrackerWizardNameChanged(this.name);

  final String name;
}

final class JournalTrackerWizardGroupChanged extends JournalTrackerWizardEvent {
  const JournalTrackerWizardGroupChanged(this.groupId);

  final String? groupId;
}

final class JournalTrackerWizardIconChanged extends JournalTrackerWizardEvent {
  const JournalTrackerWizardIconChanged(this.iconName);

  final String? iconName;
}

final class JournalTrackerWizardScopeChanged extends JournalTrackerWizardEvent {
  const JournalTrackerWizardScopeChanged(this.scope);

  final JournalTrackerScopeOption scope;
}

final class JournalTrackerWizardMeasurementChanged
    extends JournalTrackerWizardEvent {
  const JournalTrackerWizardMeasurementChanged(this.measurement);

  final JournalTrackerMeasurementType measurement;
}

final class JournalTrackerWizardRatingConfigChanged
    extends JournalTrackerWizardEvent {
  const JournalTrackerWizardRatingConfigChanged({
    required this.min,
    required this.max,
    required this.step,
  });

  final int min;
  final int max;
  final int step;
}

final class JournalTrackerWizardQuantityConfigChanged
    extends JournalTrackerWizardEvent {
  const JournalTrackerWizardQuantityConfigChanged({
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
  });

  final String unit;
  final int? min;
  final int? max;
  final int step;
}

final class JournalTrackerWizardChoiceAdded extends JournalTrackerWizardEvent {
  const JournalTrackerWizardChoiceAdded(this.label);

  final String label;
}

final class JournalTrackerWizardChoiceRemoved
    extends JournalTrackerWizardEvent {
  const JournalTrackerWizardChoiceRemoved(this.index);

  final int index;
}

final class JournalTrackerWizardChoiceUpdated
    extends JournalTrackerWizardEvent {
  const JournalTrackerWizardChoiceUpdated({
    required this.index,
    required this.label,
  });

  final int index;
  final String label;
}

final class JournalTrackerWizardSaveRequested
    extends JournalTrackerWizardEvent {
  const JournalTrackerWizardSaveRequested();
}

sealed class JournalTrackerWizardStatus {
  const JournalTrackerWizardStatus();
}

final class JournalTrackerWizardLoading extends JournalTrackerWizardStatus {
  const JournalTrackerWizardLoading();
}

final class JournalTrackerWizardIdle extends JournalTrackerWizardStatus {
  const JournalTrackerWizardIdle();
}

final class JournalTrackerWizardSaving extends JournalTrackerWizardStatus {
  const JournalTrackerWizardSaving();
}

final class JournalTrackerWizardSaved extends JournalTrackerWizardStatus {
  const JournalTrackerWizardSaved();
}

final class JournalTrackerWizardError extends JournalTrackerWizardStatus {
  const JournalTrackerWizardError(this.message);

  final String message;
}

final class JournalTrackerWizardState {
  const JournalTrackerWizardState({
    required this.status,
    required this.step,
    required this.name,
    required this.groupId,
    required this.iconName,
    required this.groups,
    required this.scope,
    required this.measurement,
    required this.ratingMin,
    required this.ratingMax,
    required this.ratingStep,
    required this.quantityUnit,
    required this.quantityMin,
    required this.quantityMax,
    required this.quantityStep,
    required this.choiceLabels,
  });

  factory JournalTrackerWizardState.initial() {
    return const JournalTrackerWizardState(
      status: JournalTrackerWizardLoading(),
      step: 0,
      name: '',
      groupId: null,
      iconName: null,
      groups: <TrackerGroup>[],
      scope: null,
      measurement: null,
      ratingMin: 1,
      ratingMax: 5,
      ratingStep: 1,
      quantityUnit: '',
      quantityMin: null,
      quantityMax: null,
      quantityStep: 1,
      choiceLabels: <String>[],
    );
  }

  final JournalTrackerWizardStatus status;
  final int step;
  final String name;
  final String? groupId;
  final String? iconName;
  final List<TrackerGroup> groups;
  final JournalTrackerScopeOption? scope;
  final JournalTrackerMeasurementType? measurement;
  final int ratingMin;
  final int ratingMax;
  final int ratingStep;
  final String quantityUnit;
  final int? quantityMin;
  final int? quantityMax;
  final int quantityStep;
  final List<String> choiceLabels;

  JournalTrackerWizardState copyWith({
    JournalTrackerWizardStatus? status,
    int? step,
    String? name,
    String? groupId,
    String? iconName,
    List<TrackerGroup>? groups,
    JournalTrackerScopeOption? scope,
    JournalTrackerMeasurementType? measurement,
    int? ratingMin,
    int? ratingMax,
    int? ratingStep,
    String? quantityUnit,
    int? quantityMin,
    int? quantityMax,
    int? quantityStep,
    List<String>? choiceLabels,
  }) {
    return JournalTrackerWizardState(
      status: status ?? this.status,
      step: step ?? this.step,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      iconName: iconName ?? this.iconName,
      groups: groups ?? this.groups,
      scope: scope ?? this.scope,
      measurement: measurement ?? this.measurement,
      ratingMin: ratingMin ?? this.ratingMin,
      ratingMax: ratingMax ?? this.ratingMax,
      ratingStep: ratingStep ?? this.ratingStep,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      quantityMin: quantityMin ?? this.quantityMin,
      quantityMax: quantityMax ?? this.quantityMax,
      quantityStep: quantityStep ?? this.quantityStep,
      choiceLabels: choiceLabels ?? this.choiceLabels,
    );
  }
}

class JournalTrackerWizardBloc
    extends Bloc<JournalTrackerWizardEvent, JournalTrackerWizardState> {
  JournalTrackerWizardBloc({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required DateTime Function() nowUtc,
    this.forcedScope,
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       super(JournalTrackerWizardState.initial()) {
    on<JournalTrackerWizardStarted>(_onStarted, transformer: restartable());
    on<JournalTrackerWizardStepChanged>(_onStepChanged);
    on<JournalTrackerWizardNameChanged>(_onNameChanged);
    on<JournalTrackerWizardGroupChanged>(_onGroupChanged);
    on<JournalTrackerWizardIconChanged>(_onIconChanged);
    on<JournalTrackerWizardScopeChanged>(_onScopeChanged);
    on<JournalTrackerWizardMeasurementChanged>(_onMeasurementChanged);
    on<JournalTrackerWizardRatingConfigChanged>(_onRatingConfigChanged);
    on<JournalTrackerWizardQuantityConfigChanged>(_onQuantityConfigChanged);
    on<JournalTrackerWizardChoiceAdded>(_onChoiceAdded);
    on<JournalTrackerWizardChoiceRemoved>(_onChoiceRemoved);
    on<JournalTrackerWizardChoiceUpdated>(_onChoiceUpdated);
    on<JournalTrackerWizardSaveRequested>(
      _onSaveRequested,
      transformer: sequential(),
    );
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;
  final JournalTrackerScopeOption? forcedScope;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'journal',
      screen: 'journal_tracker_wizard',
      intent: intent,
      operation: operation,
      entityType: 'tracker_definition',
      extraFields: extraFields,
    );
  }

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unexpected failure)',
      );
      return;
    }

    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unmapped exception)',
      );
    }
  }

  String _uiMessageFor(Object error, {required String fallback}) {
    if (error is AppFailure) return error.uiMessage();
    return fallback;
  }

  Future<void> _onStarted(
    JournalTrackerWizardStarted event,
    Emitter<JournalTrackerWizardState> emit,
  ) async {
    final groups$ = _repository.watchTrackerGroups().startWith(
      const <TrackerGroup>[],
    );

    await emit.forEach<List<TrackerGroup>>(
      groups$,
      onData: (groups) {
        final active = groups.where((g) => g.isActive).toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final defaultGroupId =
            forcedScope == JournalTrackerScopeOption.entry &&
                (state.groupId == null || state.groupId!.trim().isEmpty) &&
                active.isNotEmpty
            ? active.first.id
            : state.groupId;
        return state.copyWith(
          status: const JournalTrackerWizardIdle(),
          groups: active,
          groupId: defaultGroupId,
          scope: forcedScope,
        );
      },
      onError: (e, st) {
        final context = _newContext(
          intent: 'stream_error',
          operation: 'journal.watchTrackerGroups',
        );
        _reportIfUnexpectedOrUnmapped(
          e,
          st,
          context: context,
          message: '[JournalTrackerWizardBloc] groups stream error',
        );
        return state.copyWith(
          status: JournalTrackerWizardError(
            _uiMessageFor(
              e,
              fallback: 'Failed to load groups. Please try again.',
            ),
          ),
        );
      },
    );
  }

  void _onStepChanged(
    JournalTrackerWizardStepChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    emit(
      state.copyWith(
        step: event.step,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onNameChanged(
    JournalTrackerWizardNameChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    final trimmed = event.name.trim();
    final fallbackIcon = trimmed.isEmpty ? null : _defaultIconForName(trimmed);
    emit(
      state.copyWith(
        name: event.name,
        iconName: state.iconName ?? fallbackIcon,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onGroupChanged(
    JournalTrackerWizardGroupChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    emit(
      state.copyWith(
        groupId: event.groupId,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onIconChanged(
    JournalTrackerWizardIconChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    emit(
      state.copyWith(
        iconName: event.iconName?.trim(),
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onScopeChanged(
    JournalTrackerWizardScopeChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    emit(
      state.copyWith(
        scope: forcedScope ?? event.scope,
        measurement: null,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onMeasurementChanged(
    JournalTrackerWizardMeasurementChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    emit(
      state.copyWith(
        measurement: event.measurement,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onRatingConfigChanged(
    JournalTrackerWizardRatingConfigChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    emit(
      state.copyWith(
        ratingMin: event.min,
        ratingMax: event.max,
        ratingStep: event.step,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onQuantityConfigChanged(
    JournalTrackerWizardQuantityConfigChanged event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    emit(
      state.copyWith(
        quantityUnit: event.unit,
        quantityMin: event.min,
        quantityMax: event.max,
        quantityStep: event.step,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onChoiceAdded(
    JournalTrackerWizardChoiceAdded event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    final label = event.label.trim();
    if (label.isEmpty) return;
    final next = [...state.choiceLabels, label];
    emit(
      state.copyWith(
        choiceLabels: next,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onChoiceRemoved(
    JournalTrackerWizardChoiceRemoved event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    final next = [...state.choiceLabels];
    if (event.index < 0 || event.index >= next.length) return;
    next.removeAt(event.index);
    emit(
      state.copyWith(
        choiceLabels: next,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  void _onChoiceUpdated(
    JournalTrackerWizardChoiceUpdated event,
    Emitter<JournalTrackerWizardState> emit,
  ) {
    final next = [...state.choiceLabels];
    if (event.index < 0 || event.index >= next.length) return;
    next[event.index] = event.label;
    emit(
      state.copyWith(
        choiceLabels: next,
        status: const JournalTrackerWizardIdle(),
      ),
    );
  }

  Future<void> _onSaveRequested(
    JournalTrackerWizardSaveRequested event,
    Emitter<JournalTrackerWizardState> emit,
  ) async {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(
        state.copyWith(
          status: const JournalTrackerWizardError('Name is required.'),
        ),
      );
      return;
    }

    final scope = forcedScope ?? state.scope;
    if (scope == null) {
      emit(
        state.copyWith(
          status: const JournalTrackerWizardError('Choose a scope.'),
        ),
      );
      return;
    }

    final measurement = state.measurement;
    if (measurement == null) {
      emit(
        state.copyWith(
          status: const JournalTrackerWizardError('Choose a measurement type.'),
        ),
      );
      return;
    }

    if (scope == JournalTrackerScopeOption.entry &&
        (state.groupId == null || state.groupId!.trim().isEmpty)) {
      emit(
        state.copyWith(
          status: const JournalTrackerWizardError('Choose a group.'),
        ),
      );
      return;
    }

    if (measurement == JournalTrackerMeasurementType.rating) {
      if (state.ratingMin >= state.ratingMax || state.ratingStep <= 0) {
        emit(
          state.copyWith(
            status: const JournalTrackerWizardError('Check rating range.'),
          ),
        );
        return;
      }
    }

    if (measurement == JournalTrackerMeasurementType.quantity) {
      final unitKey = state.quantityUnit.trim().toLowerCase();
      if (!isCanonicalUnitKey(unitKey)) {
        emit(
          state.copyWith(
            status: const JournalTrackerWizardError('Choose a valid unit.'),
          ),
        );
        return;
      }
      if (state.quantityStep <= 0) {
        emit(
          state.copyWith(
            status: const JournalTrackerWizardError('Step must be > 0.'),
          ),
        );
        return;
      }
    }

    if (measurement == JournalTrackerMeasurementType.choice) {
      final trimmed = state.choiceLabels
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (trimmed.isEmpty) {
        emit(
          state.copyWith(
            status: const JournalTrackerWizardError('Add at least one option.'),
          ),
        );
        return;
      }
    }

    emit(state.copyWith(status: const JournalTrackerWizardSaving()));

    final context = _newContext(
      intent: 'create_tracker',
      operation: 'journal.saveTrackerDefinition',
      extraFields: <String, Object?>{
        'scope': scope.name,
        'measurement': measurement.name,
      },
    );

    try {
      final now = _nowUtc();
      final defs = await _repository.watchTrackerDefinitions().first;
      final groupDefs =
          defs.where((d) => (d.groupId ?? '') == (state.groupId ?? '')).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final scopeValue = switch (scope) {
        JournalTrackerScopeOption.day => 'day',
        JournalTrackerScopeOption.entry => 'entry',
        JournalTrackerScopeOption.sleepNight => 'sleep_night',
      };

      final valueType = switch (measurement) {
        JournalTrackerMeasurementType.toggle => 'yes_no',
        JournalTrackerMeasurementType.rating => 'rating',
        JournalTrackerMeasurementType.quantity => 'quantity',
        JournalTrackerMeasurementType.choice => 'choice',
      };

      final valueKind = switch (measurement) {
        JournalTrackerMeasurementType.toggle => 'boolean',
        JournalTrackerMeasurementType.rating => 'rating',
        JournalTrackerMeasurementType.quantity => 'number',
        JournalTrackerMeasurementType.choice => 'single_choice',
      };

      final opKind = switch (measurement) {
        JournalTrackerMeasurementType.quantity =>
          (scope == JournalTrackerScopeOption.entry ? 'set' : 'add'),
        _ => 'set',
      };

      await _repository.saveTrackerDefinition(
        TrackerDefinition(
          id: '',
          name: name,
          description: null,
          scope: scopeValue,
          valueType: valueType,
          valueKind: valueKind,
          opKind: opKind,
          createdAt: now,
          updatedAt: now,
          roles: const <String>[],
          config: <String, dynamic>{
            if (state.iconName != null && state.iconName!.trim().isNotEmpty)
              'iconName': state.iconName!.trim(),
          },
          goal: const <String, dynamic>{},
          isActive: true,
          sortOrder: groupDefs.length * 10 + 100,
          groupId: state.groupId,
          deletedAt: null,
          source: 'user',
          systemKey: null,
          minInt: measurement == JournalTrackerMeasurementType.rating
              ? state.ratingMin
              : measurement == JournalTrackerMeasurementType.quantity
              ? state.quantityMin
              : null,
          maxInt: measurement == JournalTrackerMeasurementType.rating
              ? state.ratingMax
              : measurement == JournalTrackerMeasurementType.quantity
              ? state.quantityMax
              : null,
          stepInt: measurement == JournalTrackerMeasurementType.rating
              ? state.ratingStep
              : measurement == JournalTrackerMeasurementType.quantity
              ? state.quantityStep
              : null,
          linkedValueId: null,
          isOutcome: false,
          isInsightEnabled: false,
          higherIsBetter: null,
          unitKind:
              measurement == JournalTrackerMeasurementType.quantity &&
                  state.quantityUnit.trim().isNotEmpty
              ? state.quantityUnit.trim().toLowerCase()
              : null,
          userId: null,
        ),
        context: context,
      );

      if (measurement == JournalTrackerMeasurementType.choice) {
        final definitions = await _repository.watchTrackerDefinitions().first;
        final definition = definitions.firstWhere(
          (d) =>
              d.name == name &&
              d.scope == scopeValue &&
              d.valueType == valueType,
          orElse: () => throw StateError('Tracker definition not found'),
        );

        final cleaned = state.choiceLabels
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final usedKeys = <String>{};
        for (var i = 0; i < cleaned.length; i++) {
          final label = cleaned[i];
          var key = _choiceKeyFromLabel(label);
          var suffix = 2;
          while (usedKeys.contains(key)) {
            key = '${_choiceKeyFromLabel(label)}_$suffix';
            suffix += 1;
          }
          usedKeys.add(key);
          await _repository.saveTrackerDefinitionChoice(
            TrackerDefinitionChoice(
              id: '',
              trackerId: definition.id,
              choiceKey: key,
              label: label,
              createdAt: now,
              updatedAt: now,
              sortOrder: i * 10,
              isActive: true,
              userId: null,
            ),
            context: context,
          );
        }
      }

      emit(state.copyWith(status: const JournalTrackerWizardSaved()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalTrackerWizardBloc] save failed',
      );
      emit(
        state.copyWith(
          status: JournalTrackerWizardError(
            _uiMessageFor(
              error,
              fallback: 'Failed to create tracker. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  String _choiceKeyFromLabel(String label) {
    final normalized = label
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'option' : normalized;
  }

  String _defaultIconForName(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('mood')) return 'mood';
    if (normalized.contains('sleep')) return 'bedtime';
    if (normalized.contains('exercise')) return 'fitness_center';
    if (normalized.contains('water')) return 'water_drop';
    if (normalized.contains('social')) return 'group';
    if (normalized.contains('stress')) return 'health';
    if (normalized.contains('energy')) return 'bolt';
    if (normalized.contains('running')) return 'directions_run';
    if (normalized.contains('guitar')) return 'music_note';
    if (normalized.contains('reading')) return 'menu_book';
    if (normalized.contains('cooking')) return 'restaurant';
    if (normalized.contains('gaming')) return 'sports_esports';
    return 'trackers';
  }
}
