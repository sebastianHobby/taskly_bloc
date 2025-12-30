import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/repositories/screen_definitions_repository.dart';

@immutable
abstract class ScreenOrderEvent {
  const ScreenOrderEvent();
}

class ScreenOrderStarted extends ScreenOrderEvent {
  const ScreenOrderStarted();
}

class ScreenOrderScreensChanged extends ScreenOrderEvent {
  const ScreenOrderScreensChanged(this.screens);

  final List<ScreenDefinition> screens;
}

class ScreenOrderReordered extends ScreenOrderEvent {
  const ScreenOrderReordered({required this.oldIndex, required this.newIndex});

  final int oldIndex;
  final int newIndex;
}

enum ScreenOrderStatus { loading, ready, failure }

class ScreenOrderState {
  const ScreenOrderState({
    required this.status,
    required this.screens,
    this.error,
  });

  const ScreenOrderState.loading()
    : status = ScreenOrderStatus.loading,
      screens = const [],
      error = null;

  const ScreenOrderState.ready({required List<ScreenDefinition> screens})
    : status = ScreenOrderStatus.ready,
      screens = screens,
      error = null;

  const ScreenOrderState.failure(String message)
    : status = ScreenOrderStatus.failure,
      screens = const [],
      error = message;

  final ScreenOrderStatus status;
  final List<ScreenDefinition> screens;
  final String? error;
}

class ScreenOrderBloc extends Bloc<ScreenOrderEvent, ScreenOrderState> {
  ScreenOrderBloc({required ScreenDefinitionsRepository screensRepository})
    : _screensRepository = screensRepository,
      super(const ScreenOrderState.loading()) {
    on<ScreenOrderStarted>(_onStarted);
    on<ScreenOrderScreensChanged>(_onScreensChanged);
    on<ScreenOrderReordered>(_onReordered);
  }

  final ScreenDefinitionsRepository _screensRepository;
  StreamSubscription<List<ScreenDefinition>>? _sub;

  Future<void> _onStarted(
    ScreenOrderStarted event,
    Emitter<ScreenOrderState> emit,
  ) async {
    await _sub?.cancel();
    _sub = _screensRepository.watchAllScreens().listen(
      (screens) => add(ScreenOrderScreensChanged(screens)),
      onError: (Object error, StackTrace _) => emit(
        ScreenOrderState.failure(error.toString()),
      ),
    );
  }

  void _onScreensChanged(
    ScreenOrderScreensChanged event,
    Emitter<ScreenOrderState> emit,
  ) {
    final sorted = event.screens.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    emit(ScreenOrderState.ready(screens: sorted));
  }

  Future<void> _onReordered(
    ScreenOrderReordered event,
    Emitter<ScreenOrderState> emit,
  ) async {
    final current = state.screens.toList();
    if (current.isEmpty) return;

    var newIndex = event.newIndex;
    // ReorderableListView reports newIndex as the index the item would occupy
    // after removal; adjust when moving down the list.
    if (event.newIndex > event.oldIndex) {
      newIndex -= 1;
    }
    final item = current.removeAt(event.oldIndex);
    current.insert(newIndex, item);
    emit(ScreenOrderState.ready(screens: current));

    try {
      final orderedIds = current.map((s) => s.id).toList(growable: false);
      await _screensRepository.reorderScreens(orderedIds);
    } catch (e) {
      emit(ScreenOrderState.failure(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
