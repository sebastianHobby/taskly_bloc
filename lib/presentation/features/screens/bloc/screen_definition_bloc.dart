import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';

part 'screen_definition_bloc.freezed.dart';

@freezed
sealed class ScreenDefinitionEvent with _$ScreenDefinitionEvent {
  const factory ScreenDefinitionEvent.subscriptionRequested({
    required String screenKey,
  }) = _SubscriptionRequested;
}

@freezed
sealed class ScreenDefinitionState with _$ScreenDefinitionState {
  const factory ScreenDefinitionState.loading() = _Loading;

  const factory ScreenDefinitionState.loaded({
    required ScreenDefinition screen,
  }) = _Loaded;

  const factory ScreenDefinitionState.notFound() = _NotFound;

  const factory ScreenDefinitionState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _Error;
}

class ScreenDefinitionBloc
    extends Bloc<ScreenDefinitionEvent, ScreenDefinitionState> {
  ScreenDefinitionBloc({
    required ScreenDefinitionsRepositoryContract repository,
  }) : _repository = repository,
       _createdAt = DateTime.now(),
       super(const ScreenDefinitionState.loading()) {
    talker.blocLog('ScreenDefinitionBloc', 'CREATED at $_createdAt');
    on<_SubscriptionRequested>(_onSubscriptionRequested);
  }

  final ScreenDefinitionsRepositoryContract _repository;
  final DateTime _createdAt;
  String? _currentScreenKey;

  @override
  Future<void> close() {
    talker.blocLog(
      'ScreenDefinitionBloc',
      'CLOSING - was created at $_createdAt, screenKey=$_currentScreenKey',
    );
    return super.close();
  }

  /// Grace period to wait before showing "not found" state.
  /// This allows time for system screen seeding to complete after auth.
  static const _gracePeriod = Duration(seconds: 3);

  Future<void> _onSubscriptionRequested(
    _SubscriptionRequested event,
    Emitter<ScreenDefinitionState> emit,
  ) async {
    _currentScreenKey = event.screenKey;
    talker.blocLog(
      'ScreenDefinition',
      '_onSubscriptionRequested START for screenKey="${event.screenKey}"',
    );
    emit(const ScreenDefinitionState.loading());
    talker.blocLog('ScreenDefinition', 'Emitted loading state');

    // Track whether we've received a valid screen within the grace period
    var receivedScreen = false;
    final graceDeadline = DateTime.now().add(_gracePeriod);
    var emissionCount = 0;

    // Start a timer to force state update after grace period if still loading
    Timer? graceTimer;
    // ignore: unused_local_variable, Flag checked in timer callback
    var needsGraceCheck = false;

    graceTimer = Timer(_gracePeriod + const Duration(milliseconds: 100), () {
      talker.blocLog(
        'ScreenDefinition',
        'Grace timer fired! needsGraceCheck=true, emissionCount=$emissionCount',
      );
      // If we're still waiting and haven't received a screen, this flag
      // will be checked on next emission. But if there's no emission,
      // we need to handle it differently.
      needsGraceCheck = true;
    });

    talker.blocLog(
      'ScreenDefinition',
      'Starting emit.forEach on watchScreenByScreenKey stream...',
    );
    try {
      await emit.forEach<ScreenDefinition?>(
        _repository.watchScreenByScreenKey(event.screenKey),
        onData: (screen) {
          emissionCount++;
          talker.blocLog(
            'ScreenDefinition',
            'onData #$emissionCount: screen=${screen == null ? "null" : "ScreenDefinition(screenKey=${screen.screenKey}, name=${screen.name})"}',
          );

          if (screen != null) {
            receivedScreen = true;
            graceTimer?.cancel();
            talker.blocLog('ScreenDefinition', 'Returning loaded state');
            return ScreenDefinitionState.loaded(screen: screen);
          }

          // If we already received a screen and now it's null, it was deleted
          if (receivedScreen) {
            graceTimer?.cancel();
            talker.blocLog(
              'ScreenDefinition',
              'Previously had screen, now null -> returning notFound',
            );
            return const ScreenDefinitionState.notFound();
          }

          // During grace period, stay in loading state to allow seeding
          final now = DateTime.now();
          final isBeforeDeadline = now.isBefore(graceDeadline);
          talker.blocLog(
            'ScreenDefinition',
            'Grace check: now=$now, deadline=$graceDeadline, isBeforeDeadline=$isBeforeDeadline',
          );

          if (isBeforeDeadline) {
            talker.blocLog(
              'ScreenDefinition',
              'Still in grace period -> returning loading',
            );
            return const ScreenDefinitionState.loading();
          }

          // Grace period expired, screen truly not found
          graceTimer?.cancel();
          talker.blocLog(
            'ScreenDefinition',
            'Grace period expired -> returning notFound',
          );
          return const ScreenDefinitionState.notFound();
        },
        onError: (error, stackTrace) {
          talker.handle(
            error,
            stackTrace,
            '[ScreenDefinitionBloc] Stream error',
          );
          graceTimer?.cancel();
          return ScreenDefinitionState.error(
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      talker.blocLog('ScreenDefinition', 'emit.forEach completed normally');
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[ScreenDefinitionBloc] emit.forEach threw exception',
      );
      rethrow;
    } finally {
      graceTimer.cancel();
      talker.blocLog(
        'ScreenDefinition',
        '_onSubscriptionRequested END for screenKey="${event.screenKey}"',
      );
    }
  }
}
