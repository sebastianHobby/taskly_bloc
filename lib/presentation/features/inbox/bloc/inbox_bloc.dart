import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/taskly_domain.dart';

sealed class InboxState {
  const InboxState();
}

final class InboxLoading extends InboxState {
  const InboxLoading();
}

final class InboxLoaded extends InboxState {
  const InboxLoaded({required this.tasks});

  final List<Task> tasks;
}

final class InboxError extends InboxState {
  const InboxError(this.message);

  final String message;
}

class InboxBloc extends Cubit<InboxState> {
  InboxBloc({required TaskRepositoryContract taskRepository})
    : _taskRepository = taskRepository,
      super(const InboxLoading()) {
    _subscribe();
  }

  final TaskRepositoryContract _taskRepository;

  StreamSubscription<List<Task>>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  void _subscribe() {
    _sub = _taskRepository
        .watchAll(TaskQuery.inbox())
        .listen(
          (tasks) {
            emit(InboxLoaded(tasks: tasks));
          },
          onError: (Object error, StackTrace _) {
            emit(InboxError(error.toString()));
          },
        );
  }
}
