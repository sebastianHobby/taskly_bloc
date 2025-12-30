import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/repositories/screen_definitions_repository.dart';

part 'screen_definition_bloc.freezed.dart';

@freezed
sealed class ScreenDefinitionEvent with _$ScreenDefinitionEvent {
  const factory ScreenDefinitionEvent.subscriptionRequested({
    required String screenId,
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
  ScreenDefinitionBloc({required ScreenDefinitionsRepository repository})
    : _repository = repository,
      super(const ScreenDefinitionState.loading()) {
    on<_SubscriptionRequested>(_onSubscriptionRequested);
  }

  final ScreenDefinitionsRepository _repository;

  Future<void> _onSubscriptionRequested(
    _SubscriptionRequested event,
    Emitter<ScreenDefinitionState> emit,
  ) async {
    emit(const ScreenDefinitionState.loading());

    await emit.forEach<ScreenDefinition?>(
      _repository.watchScreenByScreenId(event.screenId),
      onData: (screen) {
        if (screen == null) {
          return const ScreenDefinitionState.notFound();
        }
        return ScreenDefinitionState.loaded(screen: screen);
      },
      onError: (error, stackTrace) => ScreenDefinitionState.error(
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
