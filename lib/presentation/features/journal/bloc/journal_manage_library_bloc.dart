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

sealed class JournalManageLibraryEvent {
  const JournalManageLibraryEvent();
}

final class JournalManageLibraryStarted extends JournalManageLibraryEvent {
  const JournalManageLibraryStarted();
}

final class JournalManageLibraryCreateGroupRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibraryCreateGroupRequested({
    required this.name,
    required this.completer,
  });

  final String name;
  final Completer<void> completer;
}

final class JournalManageLibraryRenameGroupRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibraryRenameGroupRequested({
    required this.group,
    required this.name,
    required this.completer,
  });

  final TrackerGroup group;
  final String name;
  final Completer<void> completer;
}

final class JournalManageLibraryDeleteGroupRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibraryDeleteGroupRequested({
    required this.group,
    required this.completer,
  });

  final TrackerGroup group;
  final Completer<void> completer;
}

final class JournalManageLibraryRenameTrackerRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibraryRenameTrackerRequested({
    required this.def,
    required this.name,
    required this.completer,
  });

  final TrackerDefinition def;
  final String name;
  final Completer<void> completer;
}

final class JournalManageLibrarySetTrackerActiveRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibrarySetTrackerActiveRequested({
    required this.def,
    required this.isActive,
    required this.completer,
  });

  final TrackerDefinition def;
  final bool isActive;
  final Completer<void> completer;
}

final class JournalManageLibraryMoveTrackerToGroupRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibraryMoveTrackerToGroupRequested({
    required this.def,
    required this.groupId,
    required this.completer,
  });

  final TrackerDefinition def;
  final String? groupId;
  final Completer<void> completer;
}

final class JournalManageLibraryReorderGroupsRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibraryReorderGroupsRequested({
    required this.groupId,
    required this.direction,
    required this.completer,
  });

  final String groupId;
  final int direction;
  final Completer<void> completer;
}

final class JournalManageLibraryReorderTrackersRequested
    extends JournalManageLibraryEvent {
  const JournalManageLibraryReorderTrackersRequested({
    required this.trackerId,
    required this.groupId,
    required this.direction,
    required this.completer,
  });

  final String trackerId;
  final String? groupId;
  final int direction;
  final Completer<void> completer;
}

class JournalManageLibraryBloc
    extends Bloc<JournalManageLibraryEvent, JournalManageLibraryState> {
  JournalManageLibraryBloc({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       super(const JournalManageLibraryLoading()) {
    on<JournalManageLibraryStarted>(_onStarted);
    on<JournalManageLibraryCreateGroupRequested>(_onCreateGroupRequested);
    on<JournalManageLibraryRenameGroupRequested>(_onRenameGroupRequested);
    on<JournalManageLibraryDeleteGroupRequested>(_onDeleteGroupRequested);
    on<JournalManageLibraryRenameTrackerRequested>(_onRenameTrackerRequested);
    on<JournalManageLibrarySetTrackerActiveRequested>(
      _onSetTrackerActiveRequested,
    );
    on<JournalManageLibraryMoveTrackerToGroupRequested>(
      _onMoveTrackerToGroupRequested,
    );
    on<JournalManageLibraryReorderGroupsRequested>(
      _onReorderGroupsRequested,
    );
    on<JournalManageLibraryReorderTrackersRequested>(
      _onReorderTrackersRequested,
    );

    add(const JournalManageLibraryStarted());
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;

  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

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

  void _setStatus(
    Emitter<JournalManageLibraryState> emit,
    JournalManageLibraryStatus status,
  ) {
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

  void _complete(Completer<void> completer) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _onStarted(
    JournalManageLibraryStarted event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
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

    await emit.forEach<({List<TrackerGroup> groups, List<TrackerDefinition> defs})>(
      combined$,
      onData: (data) {
        final groups =
            data.groups.where((g) => g.isActive).toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final defs =
            data.defs.where((d) => d.deletedAt == null).toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final prevStatus = state is JournalManageLibraryLoaded
            ? (state as JournalManageLibraryLoaded).status
            : const JournalManageLibraryIdle();

        return JournalManageLibraryLoaded(
          groups: groups,
          trackers: defs,
          status: prevStatus,
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
          message: '[JournalManageLibraryBloc] stream error',
        );

        return JournalManageLibraryError(
          _uiMessageFor(
            e,
            fallback: 'Failed to load trackers. Please try again.',
          ),
        );
      },
    );
  }

  Future<void> _onCreateGroupRequested(
    JournalManageLibraryCreateGroupRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    final trimmed = event.name.trim();
    if (trimmed.isEmpty) {
      _complete(event.completer);
      return;
    }

    _setStatus(emit, const JournalManageLibrarySaving());

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

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] createGroup failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to create group. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> _onRenameGroupRequested(
    JournalManageLibraryRenameGroupRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    final trimmed = event.name.trim();
    if (trimmed.isEmpty) {
      _complete(event.completer);
      return;
    }

    _setStatus(emit, const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'rename_group',
      operation: 'journal.saveTrackerGroup',
      entityId: event.group.id,
    );

    try {
      await _repository.saveTrackerGroup(
        event.group.copyWith(name: trimmed, updatedAt: _nowUtc()),
        context: context,
      );

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] renameGroup failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to rename group. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> _onDeleteGroupRequested(
    JournalManageLibraryDeleteGroupRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    if (event.group.id.trim().isEmpty) {
      _complete(event.completer);
      return;
    }

    _setStatus(emit, const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'delete_group',
      operation: 'journal.deleteTrackerGroup',
      entityId: event.group.id,
    );

    try {
      final defs =
          _defsOrEmpty().where((d) => d.groupId == event.group.id).toList();
      for (final d in defs) {
        await _repository.saveTrackerDefinition(
          d.copyWith(groupId: null, updatedAt: _nowUtc()),
          context: context,
        );
      }

      await _repository.deleteTrackerGroup(event.group.id, context: context);

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] deleteGroup failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to delete group. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> _onRenameTrackerRequested(
    JournalManageLibraryRenameTrackerRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    final trimmed = event.name.trim();
    if (trimmed.isEmpty) {
      _complete(event.completer);
      return;
    }

    _setStatus(emit, const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'rename_tracker',
      operation: 'journal.saveTrackerDefinition',
      entityId: event.def.id,
    );

    try {
      await _repository.saveTrackerDefinition(
        event.def.copyWith(name: trimmed, updatedAt: _nowUtc()),
        context: context,
      );

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] renameTracker failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to rename tracker. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> _onSetTrackerActiveRequested(
    JournalManageLibrarySetTrackerActiveRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    if (event.def.id.trim().isEmpty) {
      _complete(event.completer);
      return;
    }

    _setStatus(emit, const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'set_tracker_active',
      operation: 'journal.saveTrackerDefinition',
      entityId: event.def.id,
      extraFields: <String, Object?>{'isActive': event.isActive},
    );

    try {
      await _repository.saveTrackerDefinition(
        event.def.copyWith(isActive: event.isActive, updatedAt: _nowUtc()),
        context: context,
      );

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] setTrackerActive failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to save tracker. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> _onMoveTrackerToGroupRequested(
    JournalManageLibraryMoveTrackerToGroupRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    if (event.def.id.trim().isEmpty) {
      _complete(event.completer);
      return;
    }

    _setStatus(emit, const JournalManageLibrarySaving());

    final context = _newContext(
      intent: 'move_tracker_group',
      operation: 'journal.saveTrackerDefinition',
      entityId: event.def.id,
      extraFields: <String, Object?>{'groupId': event.groupId},
    );

    try {
      final defs = _defsOrEmpty();
      final groupDefs = defs
          .where((d) => (d.groupId ?? '') == (event.groupId ?? ''))
          .toList();
      groupDefs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      await _repository.saveTrackerDefinition(
        event.def.copyWith(
          groupId: event.groupId,
          sortOrder: groupDefs.length * 10 + 100,
          updatedAt: _nowUtc(),
        ),
        context: context,
      );

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] moveTrackerToGroup failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to move tracker. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> _onReorderGroupsRequested(
    JournalManageLibraryReorderGroupsRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    final groups = [..._groupsOrEmpty()];
    final idx = groups.indexWhere((g) => g.id == event.groupId);
    if (idx == -1) {
      _complete(event.completer);
      return;
    }

    final next = idx + event.direction;
    if (next < 0 || next >= groups.length) {
      _complete(event.completer);
      return;
    }

    final context = _newContext(
      intent: 'reorder_groups',
      operation: 'journal.reorderTrackerGroups',
      entityId: event.groupId,
      extraFields: <String, Object?>{'direction': event.direction},
    );

    _setStatus(emit, const JournalManageLibrarySaving());

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

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] reorderGroups failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to reorder groups. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> _onReorderTrackersRequested(
    JournalManageLibraryReorderTrackersRequested event,
    Emitter<JournalManageLibraryState> emit,
  ) async {
    final defs =
        _defsOrEmpty()
            .where((d) => (d.groupId ?? '') == (event.groupId ?? ''))
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final idx = defs.indexWhere((d) => d.id == event.trackerId);
    if (idx == -1) {
      _complete(event.completer);
      return;
    }

    final next = idx + event.direction;
    if (next < 0 || next >= defs.length) {
      _complete(event.completer);
      return;
    }

    final context = _newContext(
      intent: 'reorder_trackers',
      operation: 'journal.reorderTrackerDefinitions',
      entityId: event.trackerId,
      extraFields: <String, Object?>{
        'groupId': event.groupId,
        'direction': event.direction,
      },
    );

    _setStatus(emit, const JournalManageLibrarySaving());

    try {
      final moved = defs.removeAt(idx);
      defs.insert(next, moved);

      for (var i = 0; i < defs.length; i++) {
        final d = defs[i];
        final desired = d.copyWith(sortOrder: i * 10, updatedAt: _nowUtc());
        if (desired.sortOrder == d.sortOrder) continue;
        await _repository.saveTrackerDefinition(desired, context: context);
      }

      if (emit.isDone) return;
      _setStatus(emit, const JournalManageLibrarySaved());
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalManageLibraryBloc] reorderTrackersWithinGroup failed',
      );

      if (emit.isDone) return;
      _setStatus(
        emit,
        JournalManageLibraryActionError(
          _uiMessageFor(
            error,
            fallback: 'Failed to reorder trackers. Please try again.',
          ),
        ),
      );
    } finally {
      _complete(event.completer);
    }
  }

  Future<void> createGroup(String name) {
    final completer = Completer<void>();
    add(
      JournalManageLibraryCreateGroupRequested(
        name: name,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> renameGroup({required TrackerGroup group, required String name}) {
    final completer = Completer<void>();
    add(
      JournalManageLibraryRenameGroupRequested(
        group: group,
        name: name,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> deleteGroup(TrackerGroup group) {
    final completer = Completer<void>();
    add(
      JournalManageLibraryDeleteGroupRequested(
        group: group,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> renameTracker({
    required TrackerDefinition def,
    required String name,
  }) {
    final completer = Completer<void>();
    add(
      JournalManageLibraryRenameTrackerRequested(
        def: def,
        name: name,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> setTrackerActive({
    required TrackerDefinition def,
    required bool isActive,
  }) {
    final completer = Completer<void>();
    add(
      JournalManageLibrarySetTrackerActiveRequested(
        def: def,
        isActive: isActive,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> moveTrackerToGroup({
    required TrackerDefinition def,
    String? groupId,
  }) {
    final completer = Completer<void>();
    add(
      JournalManageLibraryMoveTrackerToGroupRequested(
        def: def,
        groupId: groupId,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> reorderGroups({required String groupId, required int direction}) {
    final completer = Completer<void>();
    add(
      JournalManageLibraryReorderGroupsRequested(
        groupId: groupId,
        direction: direction,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> reorderTrackersWithinGroup({
    required String trackerId,
    required String? groupId,
    required int direction,
  }) {
    final completer = Completer<void>();
    add(
      JournalManageLibraryReorderTrackersRequested(
        trackerId: trackerId,
        groupId: groupId,
        direction: direction,
        completer: completer,
      ),
    );
    return completer.future;
  }
}
