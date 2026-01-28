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

    addTearDown(groupsController.close);
    addTearDown(defsController.close);
  });

  blocTestSafe<JournalManageLibraryBloc, JournalManageLibraryState>(
    'loads tracker groups and definitions',
    build: buildBloc,
    act: (_) {
      groupsController.emit([
        TrackerGroup(
          id: 'g-1',
          name: 'Group',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          isActive: true,
          sortOrder: 2,
        ),
      ]);
      defsController.emit([
        TrackerDefinition(
          id: 't-1',
          name: 'Tracker',
          scope: 'entry',
          valueType: 'bool',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      ]);
    },
    expect: () => [
      isA<JournalManageLibraryLoaded>()
          .having((s) => s.groups, 'groups', isEmpty)
          .having((s) => s.trackers, 'trackers', isEmpty),
      isA<JournalManageLibraryLoaded>()
          .having((s) => s.groups.length, 'groups', 1)
          .having((s) => s.trackers.length, 'trackers', 1)
          .having((s) => s.status, 'status', isA<JournalManageLibraryIdle>()),
    ],
  );

  blocTestSafe<JournalManageLibraryBloc, JournalManageLibraryState>(
    'createGroup saves group and updates status',
    build: buildBloc,
    act: (bloc) async {
      groupsController.emit([
        TrackerGroup(
          id: 'g-1',
          name: 'Group',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          isActive: true,
        ),
      ]);
      defsController.emit(const []);
      await bloc.createGroup('New Group');
    },
    expect: () => [
      isA<JournalManageLibraryLoaded>(),
      isA<JournalManageLibraryLoaded>()
          .having((s) => s.status, 'status', isA<JournalManageLibrarySaving>()),
      isA<JournalManageLibraryLoaded>()
          .having((s) => s.status, 'status', isA<JournalManageLibrarySaved>()),
    ],
    verify: (_) {
      final captured = verify(
        () => repository.saveTrackerGroup(
          any(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.feature, 'journal');
      expect(ctx.screen, 'journal_manage_library');
      expect(ctx.intent, 'create_group');
      expect(ctx.operation, 'journal.saveTrackerGroup');
    },
  );

  blocTestSafe<JournalManageLibraryBloc, JournalManageLibraryState>(
    'deleteGroup clears trackers and deletes group',
    build: buildBloc,
    act: (bloc) async {
      groupsController.emit([
        TrackerGroup(
          id: 'g-1',
          name: 'Group',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          isActive: true,
        ),
      ]);
      defsController.emit([
        TrackerDefinition(
          id: 't-1',
          name: 'Tracker',
          scope: 'entry',
          valueType: 'bool',
          groupId: 'g-1',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      ]);

      await bloc.deleteGroup(
        TrackerGroup(
          id: 'g-1',
          name: 'Group',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      );
    },
    expect: () => [
      isA<JournalManageLibraryLoaded>(),
      isA<JournalManageLibraryLoaded>()
          .having((s) => s.status, 'status', isA<JournalManageLibrarySaving>()),
      isA<JournalManageLibraryLoaded>()
          .having((s) => s.status, 'status', isA<JournalManageLibrarySaved>()),
    ],
    verify: (_) {
      verify(
        () => repository.saveTrackerDefinition(
          any(),
          context: any(named: 'context'),
        ),
      ).called(1);
      verify(
        () => repository.deleteTrackerGroup(
          'g-1',
          context: any(named: 'context'),
        ),
      ).called(1);
    },
  );
}
