import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/taskly_domain.dart';

sealed class ScheduledScopeHeaderEvent {
  const ScheduledScopeHeaderEvent();
}

final class ScheduledScopeHeaderStarted extends ScheduledScopeHeaderEvent {
  const ScheduledScopeHeaderStarted();
}

final class ScheduledScopeHeaderRetryRequested
    extends ScheduledScopeHeaderEvent {
  const ScheduledScopeHeaderRetryRequested();
}

sealed class ScheduledScopeHeaderState {
  const ScheduledScopeHeaderState();
}

final class ScheduledScopeHeaderLoading extends ScheduledScopeHeaderState {
  const ScheduledScopeHeaderLoading();
}

final class ScheduledScopeHeaderLoaded extends ScheduledScopeHeaderState {
  const ScheduledScopeHeaderLoaded({required this.title});

  final String title;
}

final class ScheduledScopeHeaderError extends ScheduledScopeHeaderState {
  const ScheduledScopeHeaderError({required this.message});

  final String message;
}

class ScheduledScopeHeaderBloc
    extends Bloc<ScheduledScopeHeaderEvent, ScheduledScopeHeaderState> {
  ScheduledScopeHeaderBloc({
    required ScheduledScope scope,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
  }) : _scope = scope,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       super(const ScheduledScopeHeaderLoading()) {
    on<ScheduledScopeHeaderStarted>(_onStarted, transformer: restartable());
    on<ScheduledScopeHeaderRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );

    add(const ScheduledScopeHeaderStarted());
  }

  final ScheduledScope _scope;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;

  Future<void> _onStarted(
    ScheduledScopeHeaderStarted event,
    Emitter<ScheduledScopeHeaderState> emit,
  ) async {
    await _bind(emit);
  }

  Future<void> _onRetryRequested(
    ScheduledScopeHeaderRetryRequested event,
    Emitter<ScheduledScopeHeaderState> emit,
  ) async {
    emit(const ScheduledScopeHeaderLoading());
    await _bind(emit);
  }

  Future<void> _bind(Emitter<ScheduledScopeHeaderState> emit) async {
    switch (_scope) {
      case GlobalScheduledScope():
        return;
      case ProjectScheduledScope(:final projectId):
        await emit.forEach<Project?>(
          _projectRepository.watchById(projectId),
          onData: (project) {
            if (project == null) {
              return const ScheduledScopeHeaderError(
                message: 'Project not found',
              );
            }
            return ScheduledScopeHeaderLoaded(
              title: 'Project: ${project.name}',
            );
          },
          onError: (error, stackTrace) => const ScheduledScopeHeaderError(
            message: 'Failed to load project',
          ),
        );
      case ValueScheduledScope(:final valueId):
        await emit.forEach<Value?>(
          _valueRepository.watchById(valueId),
          onData: (value) {
            if (value == null) {
              return const ScheduledScopeHeaderError(
                message: 'Value not found',
              );
            }
            return ScheduledScopeHeaderLoaded(title: 'Value: ${value.name}');
          },
          onError: (error, stackTrace) => const ScheduledScopeHeaderError(
            message: 'Failed to load value',
          ),
        );
    }
  }
}
