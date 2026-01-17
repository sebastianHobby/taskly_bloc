import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/taskly_domain.dart';

sealed class InboxFeedEvent {
  const InboxFeedEvent();
}

final class InboxFeedStarted extends InboxFeedEvent {
  const InboxFeedStarted();
}

final class InboxFeedRetryRequested extends InboxFeedEvent {
  const InboxFeedRetryRequested();
}

sealed class InboxFeedState {
  const InboxFeedState();
}

final class InboxFeedLoading extends InboxFeedState {
  const InboxFeedLoading();
}

final class InboxFeedLoaded extends InboxFeedState {
  const InboxFeedLoaded({required this.rows});

  final List<ListRowUiModel> rows;
}

final class InboxFeedError extends InboxFeedState {
  const InboxFeedError({required this.message});

  final String message;
}

class InboxFeedBloc extends Bloc<InboxFeedEvent, InboxFeedState> {
  InboxFeedBloc({required TaskRepositoryContract taskRepository})
    : _taskRepository = taskRepository,
      super(const InboxFeedLoading()) {
    on<InboxFeedStarted>(_onStarted);
    on<InboxFeedRetryRequested>(_onRetryRequested);

    add(const InboxFeedStarted());
  }

  final TaskRepositoryContract _taskRepository;

  StreamSubscription<List<Task>>? _sub;

  Future<void> _onStarted(
    InboxFeedStarted event,
    Emitter<InboxFeedState> emit,
  ) async {
    await _subscribe(emit);
  }

  Future<void> _onRetryRequested(
    InboxFeedRetryRequested event,
    Emitter<InboxFeedState> emit,
  ) async {
    emit(const InboxFeedLoading());
    await _subscribe(emit);
  }

  Future<void> _subscribe(Emitter<InboxFeedState> emit) async {
    await _sub?.cancel();

    _sub = _taskRepository
        .watchAll(TaskQuery.inbox())
        .listen(
          (tasks) {
            try {
              final rows = _mapToRows(tasks);
              emit(InboxFeedLoaded(rows: rows));
            } catch (e) {
              emit(InboxFeedError(message: e.toString()));
            }
          },
          onError: (Object e, StackTrace s) {
            emit(InboxFeedError(message: e.toString()));
          },
        );
  }

  List<ListRowUiModel> _mapToRows(List<Task> tasks) {
    if (tasks.isEmpty) return const <ListRowUiModel>[];

    return [
      for (final task in tasks)
        TaskRowUiModel(
          rowKey: RowKey.v1(
            screen: 'inbox',
            rowType: 'task',
            params: <String, String>{'id': task.id},
          ),
          depth: 0,
          task: task,
        ),
    ];
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
