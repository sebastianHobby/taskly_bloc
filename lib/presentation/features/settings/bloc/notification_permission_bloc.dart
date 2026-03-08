import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:taskly_bloc/core/notifications/notification_permission_service.dart';
import 'package:taskly_core/logging.dart';

@immutable
sealed class NotificationPermissionEvent {
  const NotificationPermissionEvent();
}

final class NotificationPermissionStarted extends NotificationPermissionEvent {
  const NotificationPermissionStarted();
}

final class NotificationPermissionRefreshRequested
    extends NotificationPermissionEvent {
  const NotificationPermissionRefreshRequested();
}

final class NotificationPermissionRequestRequested
    extends NotificationPermissionEvent {
  const NotificationPermissionRequestRequested();
}

final class NotificationPermissionOpenSettingsRequested
    extends NotificationPermissionEvent {
  const NotificationPermissionOpenSettingsRequested();
}

class NotificationPermissionState extends Equatable {
  const NotificationPermissionState({
    this.status = NotificationPermissionStatus.denied,
    this.isLoading = true,
    this.requestsCompleted = 0,
  });

  final NotificationPermissionStatus status;
  final bool isLoading;
  final int requestsCompleted;

  NotificationPermissionState copyWith({
    NotificationPermissionStatus? status,
    bool? isLoading,
    int? requestsCompleted,
  }) {
    return NotificationPermissionState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      requestsCompleted: requestsCompleted ?? this.requestsCompleted,
    );
  }

  @override
  List<Object> get props => <Object>[status, isLoading, requestsCompleted];
}

class NotificationPermissionBloc
    extends Bloc<NotificationPermissionEvent, NotificationPermissionState> {
  NotificationPermissionBloc({
    required NotificationPermissionService permissionService,
  }) : _permissionService = permissionService,
       super(const NotificationPermissionState()) {
    on<NotificationPermissionStarted>(
      _onStarted,
      transformer: droppable(),
    );
    on<NotificationPermissionRefreshRequested>(
      _onRefreshRequested,
      transformer: sequential(),
    );
    on<NotificationPermissionRequestRequested>(
      _onRequestRequested,
      transformer: sequential(),
    );
    on<NotificationPermissionOpenSettingsRequested>(
      _onOpenSettingsRequested,
      transformer: droppable(),
    );
  }

  final NotificationPermissionService _permissionService;

  Future<void> _onStarted(
    NotificationPermissionStarted event,
    Emitter<NotificationPermissionState> emit,
  ) async {
    await _refresh(emit);
  }

  Future<void> _onRefreshRequested(
    NotificationPermissionRefreshRequested event,
    Emitter<NotificationPermissionState> emit,
  ) async {
    await _refresh(emit);
  }

  Future<void> _onRequestRequested(
    NotificationPermissionRequestRequested event,
    Emitter<NotificationPermissionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final status = await _permissionService.requestPermission();
      emit(
        state.copyWith(
          status: status,
          isLoading: false,
          requestsCompleted: state.requestsCompleted + 1,
        ),
      );
    } catch (error, stackTrace) {
      talker.handle(
        error,
        stackTrace,
        '[NotificationPermissionBloc] request failed',
      );
      emit(
        state.copyWith(
          isLoading: false,
          requestsCompleted: state.requestsCompleted + 1,
        ),
      );
    }
  }

  Future<void> _onOpenSettingsRequested(
    NotificationPermissionOpenSettingsRequested event,
    Emitter<NotificationPermissionState> emit,
  ) async {
    try {
      await _permissionService.openSettings();
    } catch (error, stackTrace) {
      talker.handle(
        error,
        stackTrace,
        '[NotificationPermissionBloc] open settings failed',
      );
    }
  }

  Future<void> _refresh(Emitter<NotificationPermissionState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final status = await _permissionService.getStatus();
      emit(state.copyWith(status: status, isLoading: false));
    } catch (error, stackTrace) {
      talker.handle(
        error,
        stackTrace,
        '[NotificationPermissionBloc] refresh failed',
      );
      emit(state.copyWith(isLoading: false));
    }
  }
}
