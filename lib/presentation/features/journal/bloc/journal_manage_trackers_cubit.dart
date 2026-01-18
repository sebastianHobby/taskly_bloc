import 'package:bloc/bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';

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
  JournalManageTrackersCubit({
    required JournalRepositoryContract repository,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _nowUtc = nowUtc,
       super(JournalManageTrackersState.initial());

  final JournalRepositoryContract _repository;
  final DateTime Function() _nowUtc;

  Future<List<TrackerDefinitionChoice>> getChoices(String trackerId) async {
    final trimmed = trackerId.trim();
    if (trimmed.isEmpty) return const <TrackerDefinitionChoice>[];
    try {
      final all = await _repository
          .watchTrackerDefinitionChoices(trackerId: trimmed)
          .first;
      return all;
    } catch (_) {
      return const <TrackerDefinitionChoice>[];
    }
  }

  Future<void> createTracker({
    required String name,
    required int sortOrder,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));

    try {
      final nowUtc = _nowUtc();

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

  Future<void> upsertTrackerDefinition(
    TrackerDefinition definition,
  ) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));
    try {
      await _repository.saveTrackerDefinition(definition);
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to save tracker: $e'),
        ),
      );
    }
  }

  Future<void> upsertTrackerFromEditor({
    required TrackerDefinition definition,
    required bool pinned,
    required bool showInQuickAdd,
    required List<TrackerDefinitionChoice> choices,
    TrackerPreference? existingPreference,
  }) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));

    try {
      await _repository.saveTrackerDefinition(definition);

      final trackerId = definition.id.isNotEmpty
          ? definition.id
          : await _resolveTrackerIdByName(definition.name);

      if (trackerId == null || trackerId.trim().isEmpty) {
        throw StateError('Failed to resolve tracker ID after save.');
      }

      final definitionWithId = definition.copyWith(id: trackerId);

      final existingChoices = await getChoices(trackerId);
      await _saveChoices(
        trackerId: trackerId,
        existing: existingChoices,
        desired: choices,
      );

      await _savePreference(
        definition: definitionWithId,
        existing: existingPreference,
        pinned: pinned,
        showInQuickAdd: showInQuickAdd,
      );

      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalManageTrackersError('Failed to save tracker: $e'),
        ),
      );
    }
  }

  Future<String?> _resolveTrackerIdByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final defs = await _repository.watchTrackerDefinitions().first;
    final match = defs
        .where((d) => d.systemKey == null)
        .where((d) => d.deletedAt == null)
        .where((d) => d.name.trim() == trimmed)
        .toList(growable: false);

    if (match.isEmpty) return null;
    // Deterministic IDs make name collisions resolve to the same ID.
    return match.first.id;
  }

  Future<void> _saveChoices({
    required String trackerId,
    required List<TrackerDefinitionChoice> existing,
    required List<TrackerDefinitionChoice> desired,
  }) async {
    final nowUtc = _nowUtc();
    final existingByKey = {
      for (final c in existing) c.choiceKey: c,
    };

    var sort = 100;
    for (final c in desired) {
      final choiceKey = c.choiceKey.trim();
      if (choiceKey.isEmpty) continue;
      final label = c.label.trim();
      if (label.isEmpty) continue;

      final prev = existingByKey[choiceKey];

      await _repository.saveTrackerDefinitionChoice(
        TrackerDefinitionChoice(
          id: prev?.id ?? '',
          trackerId: trackerId,
          choiceKey: choiceKey,
          label: label,
          createdAt: prev?.createdAt ?? nowUtc,
          updatedAt: nowUtc,
          sortOrder: sort,
          isActive: true,
          userId: prev?.userId,
        ),
      );
      sort += 10;
    }

    final desiredKeys = desired.map((c) => c.choiceKey).toSet();
    for (final prev in existing) {
      if (!desiredKeys.contains(prev.choiceKey) && prev.isActive) {
        await _repository.saveTrackerDefinitionChoice(
          prev.copyWith(isActive: false, updatedAt: nowUtc),
        );
      }
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
      final nowUtc = _nowUtc();
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
      final nowUtc = _nowUtc();
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
      final nowUtc = _nowUtc();
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
      final nowUtc = _nowUtc();

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
