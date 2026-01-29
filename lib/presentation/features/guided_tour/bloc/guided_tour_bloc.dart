import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/model/guided_tour_step.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';

@immutable
sealed class GuidedTourEvent {
  const GuidedTourEvent();
}

final class GuidedTourStarted extends GuidedTourEvent {
  const GuidedTourStarted({this.force = false});
  final bool force;
}

final class GuidedTourNextRequested extends GuidedTourEvent {
  const GuidedTourNextRequested();
}

final class GuidedTourBackRequested extends GuidedTourEvent {
  const GuidedTourBackRequested();
}

final class GuidedTourSkipped extends GuidedTourEvent {
  const GuidedTourSkipped();
}

@immutable
final class GuidedTourState {
  const GuidedTourState({
    required this.steps,
    required this.active,
    required this.currentIndex,
    required this.navRequestId,
  });

  factory GuidedTourState.initial() => GuidedTourState(
    steps: buildGuidedTourSteps(),
    active: false,
    currentIndex: 0,
    navRequestId: 0,
  );

  final List<GuidedTourStep> steps;
  final bool active;
  final int currentIndex;
  final int navRequestId;

  GuidedTourStep? get currentStep =>
      steps.isEmpty ? null : steps[currentIndex.clamp(0, steps.length - 1)];

  bool get hasPrevious => currentIndex > 0;
  bool get hasNext => currentIndex < steps.length - 1;

  GuidedTourState copyWith({
    List<GuidedTourStep>? steps,
    bool? active,
    int? currentIndex,
    int? navRequestId,
  }) {
    return GuidedTourState(
      steps: steps ?? this.steps,
      active: active ?? this.active,
      currentIndex: currentIndex ?? this.currentIndex,
      navRequestId: navRequestId ?? this.navRequestId,
    );
  }
}

class GuidedTourBloc extends Bloc<GuidedTourEvent, GuidedTourState> {
  GuidedTourBloc({
    required SettingsRepositoryContract settingsRepository,
    required DemoModeService demoModeService,
  }) : _settingsRepository = settingsRepository,
       _demoModeService = demoModeService,
       super(GuidedTourState.initial()) {
    on<GuidedTourStarted>(_onStarted);
    on<GuidedTourNextRequested>(_onNextRequested);
    on<GuidedTourBackRequested>(_onBackRequested);
    on<GuidedTourSkipped>(_onSkipped);
  }

  final SettingsRepositoryContract _settingsRepository;
  final DemoModeService _demoModeService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  void _onStarted(
    GuidedTourStarted event,
    Emitter<GuidedTourState> emit,
  ) {
    if (state.active && !event.force) return;
    _demoModeService.enable();
    emit(
      state.copyWith(
        active: true,
        currentIndex: 0,
        navRequestId: state.navRequestId + 1,
      ),
    );
  }

  Future<void> _onNextRequested(
    GuidedTourNextRequested event,
    Emitter<GuidedTourState> emit,
  ) async {
    if (!state.active) return;
    if (!state.hasNext) {
      await _complete(emit);
      return;
    }
    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
        navRequestId: state.navRequestId + 1,
      ),
    );
  }

  void _onBackRequested(
    GuidedTourBackRequested event,
    Emitter<GuidedTourState> emit,
  ) {
    if (!state.active || !state.hasPrevious) return;
    emit(
      state.copyWith(
        currentIndex: state.currentIndex - 1,
        navRequestId: state.navRequestId + 1,
      ),
    );
  }

  Future<void> _onSkipped(
    GuidedTourSkipped event,
    Emitter<GuidedTourState> emit,
  ) async {
    if (!state.active) return;
    await _complete(emit);
  }

  Future<void> _complete(Emitter<GuidedTourState> emit) async {
    emit(state.copyWith(active: false));
    _demoModeService.disable();

    final context = _contextFactory.create(
      feature: 'guided_tour',
      screen: 'guided_tour',
      intent: 'guided_tour_completed',
      operation: 'settings.save.global',
      entityType: 'user',
    );

    try {
      final settings = await _settingsRepository.load(SettingsKey.global);
      final updated = settings.copyWith(guidedTourCompleted: true);
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        // Avoid crashing the tour if settings fail to persist.
        debugPrint(
          '[GuidedTourBloc] Failed to persist completion: $error\n$stackTrace',
        );
      }
    }
  }

  @override
  Future<void> close() {
    _demoModeService.disable();
    return super.close();
  }
}
