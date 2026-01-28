import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

enum OnboardingStep { welcome, name, valuesSetup, planMyDay, overview }

@immutable
final class OnboardingValueSelection {
  const OnboardingValueSelection({
    required this.id,
    required this.name,
    required this.color,
    required this.iconName,
    required this.priority,
  });

  factory OnboardingValueSelection.fromValue(Value value) {
    return OnboardingValueSelection(
      id: value.id,
      name: value.name,
      color: value.color ?? '#000000',
      iconName: value.iconName,
      priority: value.priority,
    );
  }

  final String id;
  final String name;
  final String color;
  final String? iconName;
  final ValuePriority priority;

  OnboardingValueSelection copyWith({
    String? id,
    String? name,
    String? color,
    String? iconName,
    ValuePriority? priority,
  }) {
    return OnboardingValueSelection(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      priority: priority ?? this.priority,
    );
  }
}

@immutable
sealed class OnboardingEffect {
  const OnboardingEffect();

  const factory OnboardingEffect.error(String message) = OnboardingErrorEffect;
  const factory OnboardingEffect.completed() = OnboardingCompletedEffect;
}

final class OnboardingErrorEffect extends OnboardingEffect {
  const OnboardingErrorEffect(this.message);

  final String message;
}

final class OnboardingCompletedEffect extends OnboardingEffect {
  const OnboardingCompletedEffect();
}

@immutable
final class OnboardingState {
  const OnboardingState({
    required this.step,
    required this.displayName,
    required this.selectedValues,
    required this.isSavingName,
    required this.isCreatingValue,
    required this.isCompleting,
    required this.effect,
  });

  factory OnboardingState.initial() => const OnboardingState(
    step: OnboardingStep.welcome,
    displayName: '',
    selectedValues: <OnboardingValueSelection>[],
    isSavingName: false,
    isCreatingValue: false,
    isCompleting: false,
    effect: null,
  );

  final OnboardingStep step;
  final String displayName;
  final List<OnboardingValueSelection> selectedValues;
  final bool isSavingName;
  final bool isCreatingValue;
  final bool isCompleting;
  final OnboardingEffect? effect;

  bool get hasMinimumValues => selectedValues.isNotEmpty;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? displayName,
    List<OnboardingValueSelection>? selectedValues,
    bool? isSavingName,
    bool? isCreatingValue,
    bool? isCompleting,
    OnboardingEffect? effect,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      displayName: displayName ?? this.displayName,
      selectedValues: selectedValues ?? this.selectedValues,
      isSavingName: isSavingName ?? this.isSavingName,
      isCreatingValue: isCreatingValue ?? this.isCreatingValue,
      isCompleting: isCompleting ?? this.isCompleting,
      effect: effect,
    );
  }
}

@immutable
sealed class OnboardingEvent {
  const OnboardingEvent();
}

final class OnboardingNameChanged extends OnboardingEvent {
  const OnboardingNameChanged(this.displayName);
  final String displayName;
}

final class OnboardingNextRequested extends OnboardingEvent {
  const OnboardingNextRequested();
}

final class OnboardingBackRequested extends OnboardingEvent {
  const OnboardingBackRequested();
}

final class OnboardingQuickPickConfirmed extends OnboardingEvent {
  const OnboardingQuickPickConfirmed(this.draft);
  final ValueDraft draft;
}

final class OnboardingCustomValueConfirmed extends OnboardingEvent {
  const OnboardingCustomValueConfirmed(this.draft);
  final ValueDraft draft;
}

final class OnboardingValueRemoved extends OnboardingEvent {
  const OnboardingValueRemoved(this.valueId);
  final String valueId;
}

final class OnboardingValueRefreshRequested extends OnboardingEvent {
  const OnboardingValueRefreshRequested(this.valueId);
  final String valueId;
}

final class OnboardingCompleteRequested extends OnboardingEvent {
  const OnboardingCompleteRequested();
}

final class OnboardingEffectHandled extends OnboardingEvent {
  const OnboardingEffectHandled();
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required AuthRepositoryContract authRepository,
    required ValueRepositoryContract valueRepository,
    required ValueWriteService valueWriteService,
    required AppErrorReporter errorReporter,
  }) : _authRepository = authRepository,
       _valueRepository = valueRepository,
       _valueWriteService = valueWriteService,
       _errorReporter = errorReporter,
       super(OnboardingState.initial()) {
    on<OnboardingNameChanged>(_onNameChanged);
    on<OnboardingNextRequested>(_onNextRequested);
    on<OnboardingBackRequested>(_onBackRequested);
    on<OnboardingQuickPickConfirmed>(_onQuickPickConfirmed);
    on<OnboardingCustomValueConfirmed>(_onCustomValueConfirmed);
    on<OnboardingValueRemoved>(_onValueRemoved);
    on<OnboardingValueRefreshRequested>(_onValueRefreshRequested);
    on<OnboardingCompleteRequested>(_onCompleteRequested);
    on<OnboardingEffectHandled>(_onEffectHandled);
  }

  final AuthRepositoryContract _authRepository;
  final ValueRepositoryContract _valueRepository;
  final ValueWriteService _valueWriteService;
  final AppErrorReporter _errorReporter;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  void _onNameChanged(
    OnboardingNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(displayName: event.displayName, effect: null));
  }

  Future<void> _onNextRequested(
    OnboardingNextRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    switch (state.step) {
      case OnboardingStep.welcome:
        emit(state.copyWith(step: OnboardingStep.name, effect: null));
      case OnboardingStep.name:
        final trimmed = state.displayName.trim();
        if (trimmed.isEmpty) {
          emit(
            state.copyWith(
              effect: const OnboardingEffect.error('Please enter a name.'),
            ),
          );
          return;
        }
        await _saveDisplayName(trimmed, emit);
      case OnboardingStep.valuesSetup:
        if (!state.hasMinimumValues) {
          emit(
            state.copyWith(
              effect: const OnboardingEffect.error('Pick at least 1 value.'),
            ),
          );
          return;
        }
        emit(state.copyWith(step: OnboardingStep.planMyDay, effect: null));
      case OnboardingStep.planMyDay:
        emit(state.copyWith(step: OnboardingStep.overview, effect: null));
      case OnboardingStep.overview:
        add(const OnboardingCompleteRequested());
    }
  }

  void _onBackRequested(
    OnboardingBackRequested event,
    Emitter<OnboardingState> emit,
  ) {
    final step = state.step;
    if (step == OnboardingStep.welcome) return;
    final previousIndex = step.index - 1;
    emit(
      state.copyWith(
        step: OnboardingStep.values[previousIndex],
        effect: null,
      ),
    );
  }

  Future<void> _saveDisplayName(
    String name,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(isSavingName: true, effect: null));

    final context = _newContext(
      intent: 'onboarding_name_set',
      operation: 'auth.update_profile',
    );
    try {
      await _authRepository.updateUserProfile(
        displayName: name,
        context: context,
      );
      emit(
        state.copyWith(
          isSavingName: false,
          step: OnboardingStep.valuesSetup,
          effect: null,
        ),
      );
    } catch (error, stackTrace) {
      _reportUnexpected(error, stackTrace, context);
      emit(
        state.copyWith(
          isSavingName: false,
          effect: const OnboardingEffect.error(
            'Could not save your name. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _onQuickPickConfirmed(
    OnboardingQuickPickConfirmed event,
    Emitter<OnboardingState> emit,
  ) async {
    await _createValueFromDraft(event.draft, emit);
  }

  Future<void> _onCustomValueConfirmed(
    OnboardingCustomValueConfirmed event,
    Emitter<OnboardingState> emit,
  ) async {
    await _createValueFromDraft(event.draft, emit);
  }

  Future<void> _createValueFromDraft(
    ValueDraft draft,
    Emitter<OnboardingState> emit,
  ) async {
    if (state.isCreatingValue) return;

    emit(state.copyWith(isCreatingValue: true, effect: null));
    final context = _newContext(
      intent: 'onboarding_value_create',
      operation: 'values.create',
    );

    try {
      final result = await _valueWriteService.create(
        CreateValueCommand(
          name: draft.name,
          color: draft.color,
          priority: draft.priority,
          iconName: draft.iconName,
        ),
        context: context,
      );
      if (result is CommandValidationFailure) {
        emit(
          state.copyWith(
            isCreatingValue: false,
            effect: const OnboardingEffect.error(
              'Please check the value details.',
            ),
          ),
        );
        return;
      }

      final created = await _lookupNewestValueByName(draft.name);
      if (created == null) {
        emit(
          state.copyWith(
            isCreatingValue: false,
            effect: const OnboardingEffect.error(
              'Could not save that value. Please try again.',
            ),
          ),
        );
        return;
      }

      final updatedSelections =
          List<OnboardingValueSelection>.from(
              state.selectedValues,
            )
            ..removeWhere((item) => item.id == created.id)
            ..add(OnboardingValueSelection.fromValue(created));

      emit(
        state.copyWith(
          isCreatingValue: false,
          selectedValues: updatedSelections,
          effect: null,
        ),
      );
    } catch (error, stackTrace) {
      _reportUnexpected(error, stackTrace, context);
      emit(
        state.copyWith(
          isCreatingValue: false,
          effect: const OnboardingEffect.error(
            'Could not save that value. Please try again.',
          ),
        ),
      );
    }
  }

  Future<Value?> _lookupNewestValueByName(String name) async {
    final values = await _valueRepository.getAll();
    final normalized = name.trim().toLowerCase();
    final matches = values
        .where((value) => value.name.trim().toLowerCase() == normalized)
        .toList(growable: false);
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matches.first;
  }

  void _onValueRemoved(
    OnboardingValueRemoved event,
    Emitter<OnboardingState> emit,
  ) {
    final updated = state.selectedValues
        .where((value) => value.id != event.valueId)
        .toList(growable: false);
    emit(state.copyWith(selectedValues: updated, effect: null));
  }

  Future<void> _onValueRefreshRequested(
    OnboardingValueRefreshRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final value = await _valueRepository.getById(event.valueId);
    if (value == null) return;
    final updated = state.selectedValues
        .map(
          (item) => item.id == value.id
              ? OnboardingValueSelection.fromValue(value)
              : item,
        )
        .toList(growable: false);
    emit(state.copyWith(selectedValues: updated, effect: null));
  }

  void _onCompleteRequested(
    OnboardingCompleteRequested event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      state.copyWith(
        isCompleting: true,
        effect: const OnboardingEffect.completed(),
      ),
    );
  }

  void _onEffectHandled(
    OnboardingEffectHandled event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(effect: null));
  }

  OperationContext _newContext({
    required String intent,
    required String operation,
  }) {
    return _contextFactory.create(
      feature: 'onboarding',
      screen: 'onboarding',
      intent: intent,
      operation: operation,
      entityType: 'user',
    );
  }

  void _reportUnexpected(
    Object error,
    StackTrace stackTrace,
    OperationContext context,
  ) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: 'Onboarding action failed (unexpected failure)',
      );
      return;
    }
    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: 'Onboarding action failed (unmapped exception)',
      );
    }
  }
}
