import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/journal_entry.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/repositories/wellbeing_repository.dart';

part 'journal_entry_bloc.freezed.dart';

// Events
@freezed
class JournalEntryEvent with _$JournalEntryEvent {
  const factory JournalEntryEvent.load(String entryId) = _Load;
  const factory JournalEntryEvent.loadByDate({
    required DateTime date,
  }) = _LoadByDate;
  const factory JournalEntryEvent.save(JournalEntry entry) = _Save;
  const factory JournalEntryEvent.delete(String entryId) = _Delete;
}

// State
@freezed
class JournalEntryState with _$JournalEntryState {
  const factory JournalEntryState.initial() = _Initial;
  const factory JournalEntryState.loading() = _Loading;
  const factory JournalEntryState.loaded(JournalEntry? entry) = _Loaded;
  const factory JournalEntryState.saved() = _Saved;
  const factory JournalEntryState.error(String message) = _Error;
}

// BLoC
class JournalEntryBloc extends Bloc<JournalEntryEvent, JournalEntryState> {
  JournalEntryBloc(this._repository)
    : super(const JournalEntryState.initial()) {
    on<_Load>(_onLoad);
    on<_LoadByDate>(_onLoadByDate);
    on<_Save>(_onSave);
    on<_Delete>(_onDelete);
  }
  final WellbeingRepository _repository;

  Future<void> _onLoad(_Load event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      final entry = await _repository.getJournalEntryById(event.entryId);
      emit(JournalEntryState.loaded(entry));
    } catch (e) {
      emit(JournalEntryState.error(e.toString()));
    }
  }

  Future<void> _onLoadByDate(_LoadByDate event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      final entry = await _repository.getJournalEntryByDate(
        date: event.date,
      );
      emit(JournalEntryState.loaded(entry));
    } catch (e) {
      emit(JournalEntryState.error(e.toString()));
    }
  }

  Future<void> _onSave(_Save event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      await _repository.saveJournalEntry(event.entry);
      emit(const JournalEntryState.saved());
    } catch (e) {
      emit(JournalEntryState.error(e.toString()));
    }
  }

  Future<void> _onDelete(_Delete event, Emitter emit) async {
    emit(const JournalEntryState.loading());
    try {
      await _repository.deleteJournalEntry(event.entryId);
      emit(const JournalEntryState.saved());
    } catch (e) {
      emit(JournalEntryState.error(e.toString()));
    }
  }
}
