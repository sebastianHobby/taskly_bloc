import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

sealed class SyncIssuesDebugEvent {
  const SyncIssuesDebugEvent();
}

final class SyncIssuesDebugStarted extends SyncIssuesDebugEvent {
  const SyncIssuesDebugStarted();
}

final class SyncIssuesDebugRefreshRequested extends SyncIssuesDebugEvent {
  const SyncIssuesDebugRefreshRequested();
}

@immutable
final class SyncIssuesDebugState {
  const SyncIssuesDebugState({
    required this.loading,
    required this.issues,
    this.errorMessage,
  });

  const SyncIssuesDebugState.initial()
    : this(loading: false, issues: const <SyncIssue>[]);

  final bool loading;
  final List<SyncIssue> issues;
  final String? errorMessage;

  SyncIssuesDebugState copyWith({
    bool? loading,
    List<SyncIssue>? issues,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncIssuesDebugState(
      loading: loading ?? this.loading,
      issues: issues ?? this.issues,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final class SyncIssuesDebugBloc
    extends Bloc<SyncIssuesDebugEvent, SyncIssuesDebugState> {
  SyncIssuesDebugBloc({required SyncIssueRepositoryContract repository})
    : _repository = repository,
      super(const SyncIssuesDebugState.initial()) {
    on<SyncIssuesDebugStarted>(_onLoad);
    on<SyncIssuesDebugRefreshRequested>(_onLoad);
  }

  final SyncIssueRepositoryContract _repository;

  Future<void> _onLoad(
    SyncIssuesDebugEvent event,
    Emitter<SyncIssuesDebugState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final issues = await _repository.fetchOpen(limit: 200);
      if (emit.isDone) return;
      emit(
        state.copyWith(
          loading: false,
          issues: issues,
          clearError: true,
        ),
      );
    } catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          loading: false,
          errorMessage: '$error',
        ),
      );
    }
  }
}
