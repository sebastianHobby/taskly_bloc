@Tags(['unit', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_bloc.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart' show OperationContext;

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      TrackerDefinition(
        id: 't-1',
        name: 'Tracker',
        scope: 'entry',
        valueType: 'bool',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(
      TrackerGroup(
        id: 'g-1',
        name: 'Group',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(
      const OperationContext(
        correlationId: 'corr-1',
        feature: 'journal',
        intent: 'test',
        operation: 'test',
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late AppErrorReporter errorReporter;
  late TestStreamController<List<TrackerGroup>> groupsController;
  late TestStreamController<List<TrackerDefinition>> defsController;

  final nowUtc = DateTime.utc(2025, 1, 15, 12);

  JournalManageLibraryBloc buildBloc() {
    return JournalManageLibraryBloc(
      repository: repository,
      errorReporter: errorReporter,
      nowUtc: () => nowUtc,
    );
  }

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    groupsController = TestStreamController.seeded(const []);
    defsController = TestStreamController.seeded(const []);

    when(() => repository.watchTrackerGroups()).thenAnswer(
      (_) => groupsController.stream,
    );
    when(() => repository.watchTrackerDefinitions()).thenAnswer(
      (_) => defsController.stream,
    );
    when(
      () => repository.saveTrackerGroup(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.deleteTrackerGroup(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.deleteTrackerAndData(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    addTearDown(groupsController.close);
    addTearDown(defsController.close);
  });

  Future<JournalManageLibraryBloc> pumpLoaded({
    List<TrackerGroup> groups = const <TrackerGroup>[],
    List<TrackerDefinition> defs = const <TrackerDefinition>[],
  }) async {
    final bloc = buildBloc();
    groupsController.emit(groups);
    defsController.emit(defs);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return bloc;
  }

  testSafe('renameGroup saves updated name', () async {
    final group = _group('g-1', 'Old');
    final bloc = await pumpLoaded(groups: [group]);
    addTearDown(bloc.close);

    await bloc.renameGroup(group: group, name: 'Renamed');

    verify(
      () => repository.saveTrackerGroup(
        any(
          that: isA<TrackerGroup>().having((g) => g.name, 'name', 'Renamed'),
        ),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testSafe('renameTracker saves updated name', () async {
    final def = _tracker('t-1', 'Old', groupId: 'g-1');
    final bloc = await pumpLoaded(defs: [def], groups: [_group('g-1', 'G')]);
    addTearDown(bloc.close);

    await bloc.renameTracker(def: def, name: 'New');

    verify(
      () => repository.saveTrackerDefinition(
        any(
          that: isA<TrackerDefinition>()
              .having((d) => d.id, 'id', 't-1')
              .having((d) => d.name, 'name', 'New'),
        ),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testSafe('setTrackerActive saves active state', () async {
    final def = _tracker('t-1', 'Habit');
    final bloc = await pumpLoaded(defs: [def]);
    addTearDown(bloc.close);

    await bloc.setTrackerActive(def: def, isActive: false);

    verify(
      () => repository.saveTrackerDefinition(
        any(
          that: isA<TrackerDefinition>().having(
            (d) => d.isActive,
            'isActive',
            false,
          ),
        ),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testSafe('setTrackerIcon updates config iconName', () async {
    final def = _tracker('t-1', 'Habit');
    final bloc = await pumpLoaded(defs: [def]);
    addTearDown(bloc.close);

    await bloc.setTrackerIcon(def: def, iconName: 'bolt');

    verify(
      () => repository.saveTrackerDefinition(
        any(
          that: isA<TrackerDefinition>().having(
            (d) => d.config['iconName'],
            'iconName',
            'bolt',
          ),
        ),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testSafe('moveTrackerToGroup updates group and sort order', () async {
    final g1 = _group('g-1', 'One', sort: 0);
    final g2 = _group('g-2', 'Two', sort: 10);
    final inTarget = _tracker('t-2', 'Existing', groupId: g2.id, sort: 100);
    final moving = _tracker('t-1', 'Move me', groupId: g1.id, sort: 0);

    final bloc = await pumpLoaded(groups: [g1, g2], defs: [moving, inTarget]);
    addTearDown(bloc.close);

    await bloc.moveTrackerToGroup(def: moving, groupId: g2.id);

    verify(
      () => repository.saveTrackerDefinition(
        any(
          that: isA<TrackerDefinition>()
              .having((d) => d.groupId, 'groupId', g2.id)
              .having((d) => d.sortOrder, 'sortOrder', 110),
        ),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testSafe('reorderGroups persists new ordering', () async {
    final g1 = _group('g-1', 'One', sort: 0);
    final g2 = _group('g-2', 'Two', sort: 10);

    final bloc = await pumpLoaded(groups: [g1, g2]);
    addTearDown(bloc.close);

    await bloc.reorderGroups(groupId: 'g-1', direction: 1);

    verify(
      () => repository.saveTrackerGroup(
        any(),
        context: any(named: 'context'),
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  testSafe('reorderTrackersWithinGroup failure maps to action error', () async {
    final defs = [
      _tracker('t-1', 'A', groupId: 'g-1', sort: 0),
      _tracker('t-2', 'B', groupId: 'g-1', sort: 10),
    ];

    final bloc = await pumpLoaded(groups: [_group('g-1', 'G')], defs: defs);
    addTearDown(bloc.close);

    await bloc.reorderTrackersWithinGroup(
      trackerId: 't-1',
      groupId: 'g-1',
      direction: 1,
    );

    final state = bloc.state as JournalManageLibraryLoaded;
    expect(state.status, isA<JournalManageLibraryActionError>());
  });

  testSafe('createGroup failure emits action error status', () async {
    when(
      () => repository.saveTrackerGroup(any(), context: any(named: 'context')),
    ).thenThrow(StateError('boom'));

    final bloc = await pumpLoaded();
    addTearDown(bloc.close);

    await bloc.createGroup('Group');

    final state = bloc.state as JournalManageLibraryLoaded;
    expect(state.status, isA<JournalManageLibraryActionError>());
  });

  testSafe('renameTracker failure emits action error status', () async {
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenThrow(StateError('boom'));

    final def = _tracker('t-1', 'A');
    final bloc = await pumpLoaded(defs: [def]);
    addTearDown(bloc.close);

    await bloc.renameTracker(def: def, name: 'B');

    final state = bloc.state as JournalManageLibraryLoaded;
    expect(state.status, isA<JournalManageLibraryActionError>());
  });

  testSafe('deleteGroup failure emits action error status', () async {
    when(
      () => repository.deleteTrackerGroup(
        any(),
        context: any(named: 'context'),
      ),
    ).thenThrow(StateError('boom'));

    final group = _group('g-1', 'A');
    final def = _tracker('t-1', 'T', groupId: 'g-1');
    final bloc = await pumpLoaded(groups: [group], defs: [def]);
    addTearDown(bloc.close);

    await bloc.deleteGroup(group);

    final state = bloc.state as JournalManageLibraryLoaded;
    expect(state.status, isA<JournalManageLibraryActionError>());
  });

  testSafe('deleteTracker failure emits action error status', () async {
    when(
      () => repository.deleteTrackerAndData(
        any(),
        context: any(named: 'context'),
      ),
    ).thenThrow(StateError('boom'));

    final def = _tracker('t-1', 'T');
    final bloc = await pumpLoaded(defs: [def]);
    addTearDown(bloc.close);

    await bloc.deleteTracker(def: def);

    final state = bloc.state as JournalManageLibraryLoaded;
    expect(state.status, isA<JournalManageLibraryActionError>());
  });

  testSafe('reorderGroups out-of-bounds is a no-op', () async {
    final bloc = await pumpLoaded(groups: [_group('g-1', 'Solo', sort: 0)]);
    addTearDown(bloc.close);

    await bloc.reorderGroups(groupId: 'g-1', direction: 1);

    verifyNever(
      () => repository.saveTrackerGroup(any(), context: any(named: 'context')),
    );
  });
}

TrackerGroup _group(String id, String name, {int sort = 0}) {
  final now = DateTime.utc(2025, 1, 15);
  return TrackerGroup(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
    isActive: true,
    sortOrder: sort,
    userId: null,
  );
}

TrackerDefinition _tracker(
  String id,
  String name, {
  String? groupId,
  int sort = 0,
}) {
  final now = DateTime.utc(2025, 1, 15);
  return TrackerDefinition(
    id: id,
    name: name,
    scope: 'entry',
    valueType: 'bool',
    createdAt: now,
    updatedAt: now,
    isActive: true,
    sortOrder: sort,
    groupId: groupId,
  );
}
