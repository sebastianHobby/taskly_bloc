import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/repositories/wellbeing_repository.dart';

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
    on<_LoadTrackers>(_onLoadTrackers);
    on<_SaveTracker>(_onSaveTracker);
    on<_DeleteTracker>(_onDeleteTracker);
    on<_ReorderTrackers>(_onReorderTrackers);
  }
  final WellbeingRepository _repository;

  Future<void> _onLoadTrackers(_LoadTrackers event, Emitter emit) async {
    emit(const TrackerManagementState.loading());
    try {
      final trackers = await _repository.getAllTrackers();
      emit(TrackerManagementState.loaded(trackers));
    } catch (e) {
      emit(TrackerManagementState.error(e.toString()));
    }
  }

  Future<void> _onSaveTracker(_SaveTracker event, Emitter emit) async {
    emit(const TrackerManagementState.loading());
    try {
      await _repository.saveTracker(event.tracker);
      emit(const TrackerManagementState.saved());
    } catch (e) {
      emit(TrackerManagementState.error(e.toString()));
    }
  }

  Future<void> _onDeleteTracker(_DeleteTracker event, Emitter emit) async {
    emit(const TrackerManagementState.loading());
    try {
      await _repository.deleteTracker(event.trackerId);
      emit(const TrackerManagementState.saved());
    } catch (e) {
      emit(TrackerManagementState.error(e.toString()));
    }
  }

  Future<void> _onReorderTrackers(_ReorderTrackers event, Emitter emit) async {
    try {
      await _repository.reorderTrackers(event.trackerIds);
      emit(const TrackerManagementState.saved());
    } catch (e) {
      emit(TrackerManagementState.error(e.toString()));
    }
  }
}
