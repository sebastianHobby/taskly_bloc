import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';

sealed class JournalManageTrackersStatus {
  const JournalManageTrackersStatus();
}

final class JournalManageTrackersIdle extends JournalManageTrackersStatus {
  const JournalManageTrackersIdle();
}

final class JournalManageTrackersSaving extends JournalManageTrackersStatus {
  const JournalManageTrackersSaving();
}

final class JournalManageTrackersError extends JournalManageTrackersStatus {
  const JournalManageTrackersError(this.message);

  final String message;
}

final class JournalManageTrackersState {
  const JournalManageTrackersState({required this.status});

  factory JournalManageTrackersState.initial() =>
      const JournalManageTrackersState(status: JournalManageTrackersIdle());

  final JournalManageTrackersStatus status;

  JournalManageTrackersState copyWith({JournalManageTrackersStatus? status}) {
    return JournalManageTrackersState(status: status ?? this.status);
  }
}

class JournalManageTrackersCubit extends Cubit<JournalManageTrackersState> {
  JournalManageTrackersCubit({required JournalRepositoryContract repository})
    : _repository = repository,
      super(JournalManageTrackersState.initial());

  final JournalRepositoryContract _repository;

  Future<void> createTracker({
    required String name,
    required int sortOrder,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));

    try {
      final nowUtc = DateTime.now().toUtc();

      await _repository.saveTrackerDefinition(
        TrackerDefinition(
          id: '',
          name: trimmed,
          description: null,
          scope: 'entry',
          valueType: 'yes_no',
          valueKind: 'boolean',
          opKind: 'set',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          roles: const <String>[],
          config: const <String, dynamic>{},
          goal: const <String, dynamic>{},
          isActive: true,
          sortOrder: sortOrder,
          deletedAt: null,
          source: 'user',
          systemKey: null,
          minInt: null,
          maxInt: null,
          stepInt: null,
          linkedValueId: null,
          isOutcome: false,
          isInsightEnabled: false,
          higherIsBetter: null,
          unitKind: null,
          userId: null,
        ),
      );

      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to create tracker: $e'),
        ),
      );
    }
  }

  Future<void> setPinned({
    required TrackerDefinition definition,
    required TrackerPreference? existing,
    required bool pinned,
  }) async {
    await _savePreference(
      definition: definition,
      existing: existing,
      pinned: pinned,
      showInQuickAdd: existing?.showInQuickAdd,
    );
  }

  Future<void> setShowInQuickAdd({
    required TrackerDefinition definition,
    required TrackerPreference? existing,
    required bool showInQuickAdd,
  }) async {
    await _savePreference(
      definition: definition,
      existing: existing,
      pinned: existing?.pinned,
      showInQuickAdd: showInQuickAdd,
    );
  }

  Future<void> setOutcome({
    required TrackerDefinition definition,
    required bool isOutcome,
  }) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));
    try {
      final nowUtc = DateTime.now().toUtc();
      await _repository.saveTrackerDefinition(
        definition.copyWith(isOutcome: isOutcome, updatedAt: nowUtc),
      );
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to update tracker: $e'),
        ),
      );
    }
  }

  Future<void> setArchived({
    required TrackerDefinition definition,
    required bool archived,
  }) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));
    try {
      final nowUtc = DateTime.now().toUtc();
      await _repository.saveTrackerDefinition(
        definition.copyWith(isActive: !archived, updatedAt: nowUtc),
      );
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to update tracker: $e'),
        ),
      );
    }
  }

  Future<void> deleteTrackerAndData({
    required TrackerDefinition definition,
  }) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));
    try {
      await _repository.deleteTrackerAndData(definition.id);
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to delete tracker: $e'),
        ),
      );
    }
  }

  Future<void> reorderDefinitions({
    required List<TrackerDefinition> ordered,
  }) async {
    emit(state.copyWith(status: const JournalManageTrackersSaving()));
    try {
      final nowUtc = DateTime.now().toUtc();
      var sort = 100;
      for (final d in ordered) {
        await _repository.saveTrackerDefinition(
          d.copyWith(sortOrder: sort, updatedAt: nowUtc),
        );
        sort += 10;
      }
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to reorder: $e'),
        ),
      );
    }
  }

  Future<void> _savePreference({
    required TrackerDefinition definition,
    required TrackerPreference? existing,
    bool? pinned,
    bool? showInQuickAdd,
  }) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));
    try {
      final nowUtc = DateTime.now().toUtc();

      final pref =
          existing ??
          TrackerPreference(
            id: '',
            trackerId: definition.id,
            createdAt: nowUtc,
            updatedAt: nowUtc,
            isActive: true,
            sortOrder: definition.sortOrder,
            pinned: false,
            showInQuickAdd: false,
          );

      await _repository.saveTrackerPreference(
        pref.copyWith(
          pinned: pinned ?? pref.pinned,
          showInQuickAdd: showInQuickAdd ?? pref.showInQuickAdd,
          updatedAt: nowUtc,
        ),
      );

      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to save preference: $e'),
        ),
      );
    }
  }
}
