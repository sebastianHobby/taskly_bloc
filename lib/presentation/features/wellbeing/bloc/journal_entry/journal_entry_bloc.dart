import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/domain/wellbeing/model/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/wellbeing/model/journal_entry.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';

part 'journal_entry_bloc.freezed.dart';

// Events
@freezed
class JournalEntryEvent with _$JournalEntryEvent {
  const factory JournalEntryEvent.load(String entryId) = _Load;
  const factory JournalEntryEvent.loadByDate({
    required DateTime date,
  }) = _LoadByDate;

  /// Load all entries for a given date (supports multiple entries per day)
  const factory JournalEntryEvent.loadEntriesForDate({
    required DateTime date,
  }) = _LoadEntriesForDate;

  const factory JournalEntryEvent.save(JournalEntry entry) = _Save;

  /// Save entry along with daily tracker responses
  const factory JournalEntryEvent.saveWithDailyResponses({
    required JournalEntry entry,
    required List<DailyTrackerResponse> dailyResponses,
  }) = _SaveWithDailyResponses;

  const factory JournalEntryEvent.delete(String entryId) = _Delete;
}

// State
@freezed
class JournalEntryState with _$JournalEntryState {
  const factory JournalEntryState.initial() = _Initial;
  const factory JournalEntryState.loading() = _Loading;
  const factory JournalEntryState.loaded(JournalEntry? entry) = _Loaded;

  /// State for multiple entries view (timeline)
  const factory JournalEntryState.entriesLoaded({
    required List<JournalEntry> entries,
    required List<DailyTrackerResponse> dailyResponses,
    required DateTime date,
  }) = _EntriesLoaded;

  const factory JournalEntryState.saved() = _Saved;
  const factory JournalEntryState.error(String message) = _Error;
}

// BLoC
class JournalEntryBloc extends Bloc<JournalEntryEvent, JournalEntryState> {
  JournalEntryBloc(this._repository)
    : super(const JournalEntryState.initial()) {
    on<_Load>(_onLoad, transformer: restartable());
    on<_LoadByDate>(_onLoadByDate, transformer: restartable());
    on<_LoadEntriesForDate>(_onLoadEntriesForDate, transformer: restartable());
    on<_Save>(_onSave, transformer: droppable());
    on<_SaveWithDailyResponses>(
      _onSaveWithDailyResponses,
      transformer: droppable(),
    );
    on<_Delete>(_onDelete, transformer: droppable());
  }

  final WellbeingRepositoryContract _repository;

  Future<void> _onLoad(_Load event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      final entry = await _repository.getJournalEntryById(event.entryId);
      emit(JournalEntryState.loaded(entry));
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to load journal entry');
      emit(JournalEntryState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onLoadByDate(_LoadByDate event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      final entry = await _repository.getJournalEntryByDate(
        date: event.date,
      );
      emit(JournalEntryState.loaded(entry));
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to load journal entry by date');
      emit(JournalEntryState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onLoadEntriesForDate(
    _LoadEntriesForDate event,
    Emitter emit,
  ) async {
    emit(const JournalEntryState.loading());
    try {
      // Load all entries for the date and daily tracker responses
      final dateOnly = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      final dailyResponses = await _repository.getDailyTrackerResponses(
        date: dateOnly,
      );

      // Get all entries for the date (supports multiple entries per day)
      final entries = await _repository.getJournalEntriesByDate(date: dateOnly);

      emit(
        JournalEntryState.entriesLoaded(
          entries: entries,
          dailyResponses: dailyResponses,
          date: dateOnly,
        ),
      );
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to load entries for date');
      emit(JournalEntryState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onSave(_Save event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      await _repository.saveJournalEntry(event.entry);
      emit(const JournalEntryState.saved());
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to save journal entry');
      emit(JournalEntryState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onSaveWithDailyResponses(
    _SaveWithDailyResponses event,
    Emitter emit,
  ) async {
    emit(const JournalEntryState.loading());
    try {
      // Save the journal entry first
      await _repository.saveJournalEntry(event.entry);

      // Save all daily tracker responses
      for (final response in event.dailyResponses) {
        await _repository.saveDailyTrackerResponse(response);
      }

      emit(const JournalEntryState.saved());
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to save journal entry with responses');
      emit(JournalEntryState.error(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onDelete(_Delete event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      await _repository.deleteJournalEntry(event.entryId);
      emit(const JournalEntryState.saved());
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to delete journal entry');
      emit(JournalEntryState.error(friendlyErrorMessage(e)));
    }
  }
}
