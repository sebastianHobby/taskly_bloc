import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;

sealed class JournalManageLibraryState {
  const JournalManageLibraryState();
}

final class JournalManageLibraryLoading extends JournalManageLibraryState {
  const JournalManageLibraryLoading();
}

final class JournalManageLibraryLoaded extends JournalManageLibraryState {
  const JournalManageLibraryLoaded({
    required this.groups,
    required this.trackers,
    required this.status,
  });

  final List<TrackerGroup> groups;
  final List<TrackerDefinition> trackers;
  final JournalManageLibraryStatus status;
}

final class JournalManageLibraryError extends JournalManageLibraryState {
  const JournalManageLibraryError(this.message);

  final String message;
}

sealed class JournalManageLibraryStatus {
  const JournalManageLibraryStatus();
}

final class JournalManageLibraryIdle extends JournalManageLibraryStatus {
  const JournalManageLibraryIdle();
}

final class JournalManageLibrarySaving extends JournalManageLibraryStatus {
  const JournalManageLibrarySaving();
}

final class JournalManageLibrarySaved extends JournalManageLibraryStatus {
  const JournalManageLibrarySaved();
}

final class JournalManageLibraryActionError extends JournalManageLibraryStatus {
  const JournalManageLibraryActionError(this.message);

  final String message;
}

class JournalManageLibraryCubit extends Cubit<JournalManageLibraryState> {
  JournalManageLibraryCubit({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       super(const JournalManageLibraryLoading()) {
    _subscribe();
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;

  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  StreamSubscription<
    ({List<TrackerGroup> groups, List<TrackerDefinition> defs})
  >?
  _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? entityId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'journal',
      screen: 'journal_manage_library',
      intent: intent,
      operation: operation,
      entityType: 'tracker_library',
      entityId: entityId,
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

  void _subscribe() {
    final groups$ = _repository.watchTrackerGroups().startWith(
      const <TrackerGroup>[],
    );
    final defs$ = _repository.watchTrackerDefinitions().startWith(
      const <TrackerDefinition>[],
    );

    final combined$ =
        Rx.combineLatest2<
          List<TrackerGroup>,
          List<TrackerDefinition>,
          ({List<TrackerGroup> groups, List<TrackerDefinition> defs})
        >(groups$, defs$, (groups, defs) => (groups: groups, defs: defs));

    _sub?.cancel();
    _sub = combined$.listen(
      (data) {
        final groups =
            data.groups.where((g) => g.isActive).toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final defs =
            data.defs.where((d) => d.deletedAt == null).toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final prevStatus = state is JournalManageLibraryLoaded
            ? (state as JournalManageLibraryLoaded).status
            : const JournalManageLibraryIdle();

        emit(
          JournalManageLibraryLoaded(
            groups: groups,
            trackers: defs,
            status: prevStatus,
          ),
        );
      },
      onError: (Object e, StackTrace st) {
        final context = _newContext(
          intent: 'stream_error',
          operation: 'journal.watchTrackerGroups+definitions',
        );

        _reportIfUnexpectedOrUnmapped(
          e,
          st,
          context: context,
          message: '[JournalManageLibraryCubit] stream error',
        );

        emit(
          JournalManageLibraryError(
            _uiMessageFor(
              e,
              fallback: 'Failed to load trackers. Please try again.',
            ),
          ),
        );
      },
    );
  }

  List<TrackerGroup> _groupsOrEmpty() {
    return switch (state) {
      JournalManageLibraryLoaded(:final groups) => groups,
      _ => const <TrackerGroup>[],
    };
  }

  List<TrackerDefinition> _defsOrEmpty() {
    return switch (state) {
      JournalManageLibraryLoaded(:final trackers) => trackers,
      _ => const <TrackerDefinition>[],
    };
  }

  void _setStatus(JournalManageLibraryStatus status) {
    final current = state;
    if (current is! JournalManageLibraryLoaded) return;
    emit(
      JournalManageLibraryLoaded(
        groups: current.groups,
        trackers: current.trackers,
        status: status,
      ),
    );
  }

  Future<void> createGroup(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    _setStatus(const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'create_group',
      operation: 'journal.saveTrackerGroup',
      extraFields: <String, Object?>{'nameLength': trimmed.length},
    );

    try {
      final now = _nowUtc();
      final groups = _groupsOrEmpty();

      await _repository.saveTrackerGroup(
        TrackerGroup(
          id: '',
          name: trimmed,
          createdAt: now,
          updatedAt: now,
          isActive: true,
          sortOrder: groups.length * 10 + 100,
          userId: null,
        ),
        context: context,
      );

      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryCubit] createGroup failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to create group. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> renameGroup({
    required TrackerGroup group,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    _setStatus(const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'rename_group',
      operation: 'journal.saveTrackerGroup',
      entityId: group.id,
    );

    try {
      await _repository.saveTrackerGroup(
        group.copyWith(name: trimmed, updatedAt: _nowUtc()),
        context: context,
      );
      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryCubit] renameGroup failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to rename group. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> deleteGroup(TrackerGroup group) async {
    if (group.id.trim().isEmpty) return;

    _setStatus(const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'delete_group',
      operation: 'journal.deleteTrackerGroup',
      entityId: group.id,
    );

    try {
      // Ungroup trackers first (keeps UI consistent even if delete doesn't
      // cascade).
      final defs = _defsOrEmpty().where((d) => d.groupId == group.id).toList();
      for (final d in defs) {
        await _repository.saveTrackerDefinition(
          d.copyWith(groupId: null, updatedAt: _nowUtc()),
          context: context,
        );
      }

      await _repository.deleteTrackerGroup(group.id, context: context);
      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryCubit] deleteGroup failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to delete group. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> createTracker({required String name, String? groupId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    _setStatus(const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'create_tracker',
      operation: 'journal.saveTrackerDefinition',
      extraFields: <String, Object?>{
        'nameLength': trimmed.length,
        'groupId': groupId,
      },
    );

    try {
      final now = _nowUtc();
      final defs = _defsOrEmpty();

      final groupDefs = defs
          .where((d) => (d.groupId ?? '') == (groupId ?? ''))
          .toList();
      groupDefs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      await _repository.saveTrackerDefinition(
        TrackerDefinition(
          id: '',
          name: trimmed,
          description: null,
          scope: 'entry',
          valueType: 'yes_no',
          valueKind: 'boolean',
          opKind: 'set',
          createdAt: now,
          updatedAt: now,
          roles: const <String>[],
          config: const <String, dynamic>{},
          goal: const <String, dynamic>{},
          isActive: true,
          sortOrder: groupDefs.length * 10 + 100,
          groupId: groupId,
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

      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryCubit] createTracker failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to create tracker. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> setTrackerActive({
    required TrackerDefinition def,
    required bool isActive,
  }) async {
    if (def.id.trim().isEmpty) return;

    _setStatus(const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'set_tracker_active',
      operation: 'journal.saveTrackerDefinition',
      entityId: def.id,
      extraFields: <String, Object?>{'isActive': isActive},
    );

    try {
      await _repository.saveTrackerDefinition(
        def.copyWith(isActive: isActive, updatedAt: _nowUtc()),
        context: context,
      );
      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryCubit] setTrackerActive failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to save tracker. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> moveTrackerToGroup({
    required TrackerDefinition def,
    String? groupId,
  }) async {
    if (def.id.trim().isEmpty) return;

    _setStatus(const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'move_tracker_group',
      operation: 'journal.saveTrackerDefinition',
      entityId: def.id,
      extraFields: <String, Object?>{'groupId': groupId},
    );

    try {
      final defs = _defsOrEmpty();
      final groupDefs = defs
          .where((d) => (d.groupId ?? '') == (groupId ?? ''))
          .toList();
      groupDefs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      await _repository.saveTrackerDefinition(
        def.copyWith(
          groupId: groupId,
          sortOrder: groupDefs.length * 10 + 100,
          updatedAt: _nowUtc(),
        ),
        context: context,
      );

      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryCubit] moveTrackerToGroup failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to move tracker. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> reorderGroups({
    required String groupId,
    required int direction,
  }) async {
    final groups = [..._groupsOrEmpty()];
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final next = idx + direction;
    if (next < 0 || next >= groups.length) return;

    final context = _newContext(
      intent: 'reorder_groups',
      operation: 'journal.reorderTrackerGroups',
      entityId: groupId,
      extraFields: <String, Object?>{'direction': direction},
    );

    _setStatus(const JournalManageLibrarySaving());

    try {
      final moved = groups.removeAt(idx);
      groups.insert(next, moved);

      for (var i = 0; i < groups.length; i++) {
        final desired = groups[i].copyWith(
          sortOrder: i * 10,
          updatedAt: _nowUtc(),
        );
        if (desired.sortOrder == groups[i].sortOrder) continue;
        await _repository.saveTrackerGroup(desired, context: context);
      }

      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryCubit] reorderGroups failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to reorder groups. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> reorderTrackersWithinGroup({
    required String trackerId,
    required String? groupId,
    required int direction,
  }) async {
    final defs =
        _defsOrEmpty()
            .where((d) => (d.groupId ?? '') == (groupId ?? ''))
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final idx = defs.indexWhere((d) => d.id == trackerId);
    if (idx == -1) return;

    final next = idx + direction;
    if (next < 0 || next >= defs.length) return;

    final context = _newContext(
      intent: 'reorder_trackers',
      operation: 'journal.reorderTrackerDefinitions',
      entityId: trackerId,
      extraFields: <String, Object?>{
        'groupId': groupId,
        'direction': direction,
      },
    );

    _setStatus(const JournalManageLibrarySaving());

    try {
      final moved = defs.removeAt(idx);
      defs.insert(next, moved);

      for (var i = 0; i < defs.length; i++) {
        final d = defs[i];
        final desired = d.copyWith(sortOrder: i * 10, updatedAt: _nowUtc());
        if (desired.sortOrder == d.sortOrder) continue;
        await _repository.saveTrackerDefinition(desired, context: context);
      }

      _setStatus(const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message:
            '[JournalManageLibraryCubit] reorderTrackersWithinGroup failed',
      );

      _setStatus(
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to reorder trackers. Please try again.',
          ),
        ),
      );
    }
  }
}
