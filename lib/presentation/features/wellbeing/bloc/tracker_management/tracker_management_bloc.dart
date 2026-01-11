import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';

part 'tracker_management_bloc.freezed.dart';

// Events
@freezed
class TrackerManagementEvent with _$TrackerManagementEvent {
  const factory TrackerManagementEvent.loadTrackers() = _LoadTrackers;
  const factory TrackerManagementEvent.saveTracker(Tracker tracker) =
      _SaveTracker;
  const factory TrackerManagementEvent.deleteTracker(String trackerId) =
      _DeleteTracker;
  const factory TrackerManagementEvent.reorderTrackers(
    List<String> trackerIds,
  ) = _ReorderTrackers;
}

// State
@freezed
class TrackerManagementState with _$TrackerManagementState {
  const factory TrackerManagementState.initial() = _Initial;
  const factory TrackerManagementState.loading() = _Loading;
  const factory TrackerManagementState.loaded(List<Tracker> trackers) = _Loaded;
  const factory TrackerManagementState.saved() = _Saved;
  const factory TrackerManagementState.error(String message) = _Error;
}

// BLoC
class TrackerManagementBloc
    extends Bloc<TrackerManagementEvent, TrackerManagementState> {
  TrackerManagementBloc(this._repository)
    : super(const TrackerManagementState.initial()) {
    on<_LoadTrackers>(_onLoadTrackers, transformer: restartable());
    on<_SaveTracker>(_onSaveTracker, transformer: droppable());
    on<_DeleteTracker>(_onDeleteTracker, transformer: droppable());
    on<_ReorderTrackers>(_onReorderTrackers, transformer: restartable());
  }

  final WellbeingRepositoryContract _repository;

  Future<void> _onLoadTrackers(_LoadTrackers event, Emitter emit) async {
    emit(const TrackerManagementState.loading());
    try {
      final trackers = await _repository.getAllTrackers();
      emit(TrackerManagementState.loaded(trackers));
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to load trackers');
      emit(TrackerManagementState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onSaveTracker(_SaveTracker event, Emitter emit) async {
    emit(const TrackerManagementState.loading());
    try {
      await _repository.saveTracker(event.tracker);
      emit(const TrackerManagementState.saved());
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to save tracker');
      emit(TrackerManagementState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onDeleteTracker(_DeleteTracker event, Emitter emit) async {
    emit(const TrackerManagementState.loading());
    try {
      await _repository.deleteTracker(event.trackerId);
      emit(const TrackerManagementState.saved());
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to delete tracker');
      emit(TrackerManagementState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onReorderTrackers(_ReorderTrackers event, Emitter emit) async {
    try {
      await _repository.reorderTrackers(event.trackerIds);
      emit(const TrackerManagementState.saved());
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to reorder trackers');
      emit(TrackerManagementState.error(friendlyErrorMessage(e)));
    }
  }
}
