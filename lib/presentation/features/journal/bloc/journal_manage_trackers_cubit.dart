import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;

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
    required AppErrorReporter errorReporter,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       super(JournalManageTrackersState.initial());

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? trackerId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'journal',
      screen: 'journal_manage_trackers',
      intent: intent,
      operation: operation,
      entityType: 'tracker_definition',
      entityId: trackerId,
      extraFields: extraFields,
    );
  }

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unexpected failure)',
      );
      return;
    }

    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unmapped exception)',
      );
    }
  }

  String _uiMessageFor(Object error, {required String fallback}) {
    if (error is AppFailure) return error.uiMessage();
    return fallback;
  }

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

    final context = _newContext(
      intent: 'create_tracker',
      operation: 'journal.saveTrackerDefinition',
      extraFields: <String, Object?>{'sortOrder': sortOrder},
    );

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
        context: context,
      );

      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] createTracker failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to create tracker. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> upsertTrackerDefinition(
    TrackerDefinition definition,
  ) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));

    final context = _newContext(
      intent: 'save_tracker',
      operation: 'journal.saveTrackerDefinition',
      trackerId: definition.id.isEmpty ? null : definition.id,
    );

    try {
      await _repository.saveTrackerDefinition(definition, context: context);
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] upsertTrackerDefinition failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to save tracker. Please try again.',
            ),
          ),
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

    final context = _newContext(
      intent: 'save_tracker_from_editor',
      operation: 'journal.saveTrackerDefinition',
      trackerId: definition.id.isEmpty ? null : definition.id,
      extraFields: <String, Object?>{
        'choicesCount': choices.length,
        'pinned': pinned,
        'showInQuickAdd': showInQuickAdd,
      },
    );

    try {
      await _repository.saveTrackerDefinition(definition, context: context);

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
        context: context,
      );

      await _savePreference(
        definition: definitionWithId,
        existing: existingPreference,
        pinned: pinned,
        showInQuickAdd: showInQuickAdd,
        context: context,
      );

      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] upsertTrackerFromEditor failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to save tracker. Please try again.',
            ),
          ),
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
    required OperationContext context,
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
        context: context,
      );
      sort += 10;
    }

    final desiredKeys = desired.map((c) => c.choiceKey).toSet();
    for (final prev in existing) {
      if (!desiredKeys.contains(prev.choiceKey) && prev.isActive) {
        await _repository.saveTrackerDefinitionChoice(
          prev.copyWith(isActive: false, updatedAt: nowUtc),
          context: context,
        );
      }
    }
  }

  Future<void> setPinned({
    required TrackerDefinition definition,
    required TrackerPreference? existing,
    required bool pinned,
  }) async {
    final context = _newContext(
      intent: 'set_pinned',
      operation: 'journal.saveTrackerPreference',
      trackerId: definition.id,
      extraFields: <String, Object?>{'pinned': pinned},
    );

    await _savePreference(
      definition: definition,
      existing: existing,
      pinned: pinned,
      showInQuickAdd: existing?.showInQuickAdd,
      context: context,
    );
  }

  Future<void> setShowInQuickAdd({
    required TrackerDefinition definition,
    required TrackerPreference? existing,
    required bool showInQuickAdd,
  }) async {
    final context = _newContext(
      intent: 'set_show_in_quick_add',
      operation: 'journal.saveTrackerPreference',
      trackerId: definition.id,
      extraFields: <String, Object?>{'showInQuickAdd': showInQuickAdd},
    );

    await _savePreference(
      definition: definition,
      existing: existing,
      pinned: existing?.pinned,
      showInQuickAdd: showInQuickAdd,
      context: context,
    );
  }

  Future<void> setOutcome({
    required TrackerDefinition definition,
    required bool isOutcome,
  }) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));

    final context = _newContext(
      intent: 'set_outcome',
      operation: 'journal.saveTrackerDefinition',
      trackerId: definition.id,
      extraFields: <String, Object?>{'isOutcome': isOutcome},
    );

    try {
      final nowUtc = _nowUtc();
      await _repository.saveTrackerDefinition(
        definition.copyWith(isOutcome: isOutcome, updatedAt: nowUtc),
        context: context,
      );
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] setOutcome failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to update tracker. Please try again.',
            ),
          ),
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

    final context = _newContext(
      intent: 'set_archived',
      operation: 'journal.saveTrackerDefinition',
      trackerId: definition.id,
      extraFields: <String, Object?>{'archived': archived},
    );

    try {
      final nowUtc = _nowUtc();
      await _repository.saveTrackerDefinition(
        definition.copyWith(isActive: !archived, updatedAt: nowUtc),
        context: context,
      );
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] setArchived failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to update tracker. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> deleteTrackerAndData({
    required TrackerDefinition definition,
  }) async {
    if (definition.systemKey != null) return;

    emit(state.copyWith(status: const JournalManageTrackersSaving()));

    final context = _newContext(
      intent: 'delete_tracker_and_data',
      operation: 'journal.deleteTrackerAndData',
      trackerId: definition.id,
    );

    try {
      await _repository.deleteTrackerAndData(definition.id, context: context);
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] deleteTrackerAndData failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to delete tracker. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> reorderDefinitions({
    required List<TrackerDefinition> ordered,
  }) async {
    emit(state.copyWith(status: const JournalManageTrackersSaving()));

    final context = _newContext(
      intent: 'reorder_definitions',
      operation: 'journal.saveTrackerDefinition',
      extraFields: <String, Object?>{'count': ordered.length},
    );

    try {
      final nowUtc = _nowUtc();
      var sort = 100;
      for (final d in ordered) {
        await _repository.saveTrackerDefinition(
          d.copyWith(sortOrder: sort, updatedAt: nowUtc),
          context: context,
        );
        sort += 10;
      }
      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] reorderDefinitions failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to reorder trackers. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _savePreference({
    required TrackerDefinition definition,
    required TrackerPreference? existing,
    required OperationContext context,
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
        context: context,
      );

      emit(state.copyWith(status: const JournalManageTrackersIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageTrackersCubit] savePreference failed',
      );

      emit(
        state.copyWith(
          status: JournalManageTrackersError(
            _uiMessageFor(
              error,
              fallback: 'Failed to save preference. Please try again.',
            ),
          ),
        ),
      );
    }
  }
}
