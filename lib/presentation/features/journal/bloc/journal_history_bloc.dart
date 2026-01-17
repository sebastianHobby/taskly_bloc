import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/queries.dart';

sealed class JournalHistoryState {
  const JournalHistoryState();
}

final class JournalHistoryLoading extends JournalHistoryState {
  const JournalHistoryLoading();
}

final class JournalHistoryLoaded extends JournalHistoryState {
  const JournalHistoryLoaded(this.entries);

  final List<JournalEntry> entries;
}

final class JournalHistoryError extends JournalHistoryState {
  const JournalHistoryError(this.message);

  final String message;
}

class JournalHistoryBloc extends Cubit<JournalHistoryState> {
  JournalHistoryBloc({required JournalRepositoryContract repository})
    : _repository = repository,
      super(const JournalHistoryLoading()) {
    _subscribe();
  }

  final JournalRepositoryContract _repository;

  StreamSubscription<List<JournalEntry>>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  void _subscribe() {
    _sub = _repository
        .watchJournalEntriesByQuery(JournalQuery.recent(days: 30))
        .listen(
          (entries) {
            emit(JournalHistoryLoaded(entries));
          },
          onError: (Object e) {
            emit(JournalHistoryError('Failed to load history: $e'));
          },
        );
  }
}
