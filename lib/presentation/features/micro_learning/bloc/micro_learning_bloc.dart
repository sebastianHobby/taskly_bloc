import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';

abstract final class MicroLearningTips {
  static const myDay = 'my_day';
  static const planMyDay = 'plan_my_day';
  static const projects = 'projects';
  static const scheduled = 'scheduled';
  static const projectDetail = 'project_detail';
  static const routineDetail = 'routine_detail';

  static const all = <String>{
    myDay,
    planMyDay,
    projects,
    scheduled,
    projectDetail,
    routineDetail,
  };
}

sealed class MicroLearningEvent extends Equatable {
  const MicroLearningEvent();

  @override
  List<Object?> get props => const [];
}

final class MicroLearningStarted extends MicroLearningEvent {
  const MicroLearningStarted();
}

final class MicroLearningRouteVisited extends MicroLearningEvent {
  const MicroLearningRouteVisited(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

final class MicroLearningTipDismissed extends MicroLearningEvent {
  const MicroLearningTipDismissed(this.tipId);

  final String tipId;

  @override
  List<Object?> get props => [tipId];
}

final class MicroLearningReplayRequested extends MicroLearningEvent {
  const MicroLearningReplayRequested();
}

final class MicroLearningState extends Equatable {
  const MicroLearningState({
    this.isLoaded = false,
    this.lastPath,
    this.seenTipIds = const <String>{},
    this.activeTipId,
  });

  final bool isLoaded;
  final String? lastPath;
  final Set<String> seenTipIds;
  final String? activeTipId;

  MicroLearningState copyWith({
    bool? isLoaded,
    String? lastPath,
    Set<String>? seenTipIds,
    String? activeTipId,
  }) {
    return MicroLearningState(
      isLoaded: isLoaded ?? this.isLoaded,
      lastPath: lastPath ?? this.lastPath,
      seenTipIds: seenTipIds ?? this.seenTipIds,
      activeTipId: activeTipId,
    );
  }

  @override
  List<Object?> get props => [isLoaded, lastPath, seenTipIds, activeTipId];
}

class MicroLearningBloc extends Bloc<MicroLearningEvent, MicroLearningState> {
  MicroLearningBloc({required SettingsRepositoryContract settingsRepository})
    : _settingsRepository = settingsRepository,
      super(const MicroLearningState()) {
    on<MicroLearningStarted>(_onStarted);
    on<MicroLearningRouteVisited>(_onRouteVisited);
    on<MicroLearningTipDismissed>(_onTipDismissed);
    on<MicroLearningReplayRequested>(_onReplayRequested);
  }

  final SettingsRepositoryContract _settingsRepository;

  Future<void> _onStarted(
    MicroLearningStarted event,
    Emitter<MicroLearningState> emit,
  ) async {
    if (state.isLoaded) return;
    final seen = <String>{};
    for (final tipId in MicroLearningTips.all) {
      final isSeen = await _settingsRepository.load(
        SettingsKey.microLearningSeen(tipId),
      );
      if (isSeen) {
        seen.add(tipId);
      }
    }

    emit(
      state.copyWith(
        isLoaded: true,
        seenTipIds: seen,
        activeTipId: null,
      ),
    );
  }

  void _onRouteVisited(
    MicroLearningRouteVisited event,
    Emitter<MicroLearningState> emit,
  ) {
    final nextTipId = _tipIdForPath(event.path);
    if (!state.isLoaded) {
      emit(state.copyWith(lastPath: event.path, activeTipId: null));
      return;
    }

    if (nextTipId == null || state.seenTipIds.contains(nextTipId)) {
      emit(state.copyWith(lastPath: event.path, activeTipId: null));
      return;
    }

    emit(state.copyWith(lastPath: event.path, activeTipId: nextTipId));
  }

  Future<void> _onTipDismissed(
    MicroLearningTipDismissed event,
    Emitter<MicroLearningState> emit,
  ) async {
    await _settingsRepository.save(
      SettingsKey.microLearningSeen(event.tipId),
      true,
    );

    emit(
      state.copyWith(
        seenTipIds: <String>{...state.seenTipIds, event.tipId},
        activeTipId: null,
      ),
    );
  }

  Future<void> _onReplayRequested(
    MicroLearningReplayRequested event,
    Emitter<MicroLearningState> emit,
  ) async {
    for (final tipId in MicroLearningTips.all) {
      await _settingsRepository.save(
        SettingsKey.microLearningSeen(tipId),
        false,
      );
    }

    emit(
      state.copyWith(
        seenTipIds: const <String>{},
        activeTipId: null,
      ),
    );
  }

  String? _tipIdForPath(String path) {
    if (path == '/my-day') return MicroLearningTips.myDay;
    if (path == '/my-day/plan') return MicroLearningTips.planMyDay;
    if (path == '/projects') return MicroLearningTips.projects;
    if (path == '/scheduled') return MicroLearningTips.scheduled;

    final projectDetail = RegExp(r'^/project/[^/]+/detail$');
    if (projectDetail.hasMatch(path)) return MicroLearningTips.projectDetail;

    final routineDetail = RegExp(r'^/routine/[^/]+$');
    if (routineDetail.hasMatch(path)) return MicroLearningTips.routineDetail;

    return null;
  }
}
