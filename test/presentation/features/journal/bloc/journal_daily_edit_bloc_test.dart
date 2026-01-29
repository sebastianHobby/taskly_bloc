@Tags(['unit', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_daily_edit_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart' show OperationContext;

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      TrackerDefinition(
        id: 't-1',
        name: 'Daily',
        scope: 'daily',
        valueType: 'int',
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
      TrackerEvent(
        id: 'e-1',
        trackerId: 't-1',
        anchorType: 'day',
        anchorDate: TestConstants.referenceDate,
        op: 'set',
        value: 1,
        occurredAt: TestConstants.referenceDate,
        recordedAt: TestConstants.referenceDate,
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
    registerFallbackValue(
      DateRange(
        start: TestConstants.referenceDate,
        end: TestConstants.referenceDate,
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late AppErrorReporter errorReporter;
  late TestStreamController<List<TrackerDefinition>> defsController;
  late TestStreamController<List<TrackerGroup>> groupsController;
  late TestStreamController<List<TrackerStateDay>> dayStateController;

  final nowUtc = DateTime.utc(2025, 1, 15, 12);

  JournalDailyEditBloc buildBloc() {
    return JournalDailyEditBloc(
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
    defsController = TestStreamController.seeded(const []);
    groupsController = TestStreamController.seeded(const []);
    dayStateController = TestStreamController.seeded(const []);

    when(() => repository.watchTrackerDefinitions()).thenAnswer(
      (_) => defsController.stream,
    );
    when(() => repository.watchTrackerGroups()).thenAnswer(
      (_) => groupsController.stream,
    );
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStateController.stream);
    when(
      () => repository.appendTrackerEvent(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    addTearDown(defsController.close);
    addTearDown(groupsController.close);
    addTearDown(dayStateController.close);
  });

  testSafe('initial state is loading', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    expect(bloc.state.status, isA<JournalDailyEditLoading>());
  });

  blocTestSafe<JournalDailyEditBloc, JournalDailyEditState>(
    'started loads daily trackers and groups',
    build: buildBloc,
    act: (bloc) {
      bloc.add(
        JournalDailyEditStarted(selectedDayLocal: DateTime(2025, 1, 14)),
      );

      defsController.emit([
        TrackerDefinition(
          id: 'daily',
          name: 'Sleep',
          scope: 'daily',
          valueType: 'int',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        TrackerDefinition(
          id: 'entry',
          name: 'Gratitude',
          scope: 'entry',
          valueType: 'bool',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      ]);
      groupsController.emit([
        TrackerGroup(
          id: 'g-1',
          name: 'Group',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          isActive: true,
        ),
      ]);
    },
    expect: () => [
      isA<JournalDailyEditState>().having(
        (s) => s.selectedDayLocal.day,
        'day',
        14,
      ),
      isA<JournalDailyEditState>().having(
        (s) => s.status,
        'status',
        isA<JournalDailyEditIdle>(),
      ),
      isA<JournalDailyEditState>().having(
        (s) => s.dailyTrackers.length,
        'dailyTrackers',
        1,
      ),
    ],
  );

  blocTestSafe<JournalDailyEditBloc, JournalDailyEditState>(
    'value change persists tracker event with context',
    build: buildBloc,
    seed: () => JournalDailyEditState.initial().copyWith(
      status: const JournalDailyEditIdle(),
      selectedDayLocal: DateTime(2025, 1, 14),
      definitionById: const {
        'daily': TrackerDefinition(
          id: 'daily',
          name: 'Sleep',
          scope: 'daily',
          valueType: 'int',
          createdAt: TestConstants.referenceDate,
          updatedAt: TestConstants.referenceDate,
          opKind: 'set',
        ),
      },
    ),
    act: (bloc) => bloc.add(
      const JournalDailyEditValueChanged(trackerId: 'daily', value: 5),
    ),
    expect: () => [
      isA<JournalDailyEditState>().having(
        (s) => s.status,
        'status',
        isA<JournalDailyEditSaving>(),
      ),
      isA<JournalDailyEditState>().having(
        (s) => s.status,
        'status',
        isA<JournalDailyEditIdle>(),
      ),
    ],
    verify: (_) {
      final captured = verify(
        () => repository.appendTrackerEvent(
          any(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.feature, 'journal');
      expect(ctx.screen, 'journal_daily_edit');
      expect(ctx.intent, 'set_daily_value');
      expect(ctx.operation, 'journal.daily_edit.set');
      expect(ctx.entityId, 'daily');
    },
  );

  blocTestSafe<JournalDailyEditBloc, JournalDailyEditState>(
    'delta add persists tracker event with context',
    build: buildBloc,
    seed: () => JournalDailyEditState.initial().copyWith(
      status: const JournalDailyEditIdle(),
      selectedDayLocal: DateTime(2025, 1, 14),
      definitionById: const {
        'daily': TrackerDefinition(
          id: 'daily',
          name: 'Steps',
          scope: 'daily',
          valueType: 'int',
          createdAt: TestConstants.referenceDate,
          updatedAt: TestConstants.referenceDate,
        ),
      },
    ),
    act: (bloc) => bloc.add(
      const JournalDailyEditDeltaAdded(trackerId: 'daily', delta: 2),
    ),
    expect: () => [
      isA<JournalDailyEditState>().having(
        (s) => s.status,
        'status',
        isA<JournalDailyEditSaving>(),
      ),
      isA<JournalDailyEditState>().having(
        (s) => s.status,
        'status',
        isA<JournalDailyEditIdle>(),
      ),
    ],
    verify: (_) {
      final captured = verify(
        () => repository.appendTrackerEvent(
          any(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.intent, 'add_daily_delta');
      expect(ctx.operation, 'journal.daily_edit.add');
      expect(ctx.entityId, 'daily');
    },
  );

  blocTestSafe<JournalDailyEditBloc, JournalDailyEditState>(
    'value change emits error when repository fails',
    build: () {
      when(
        () => repository.appendTrackerEvent(
          any(),
          context: any(named: 'context'),
        ),
      ).thenThrow(StateError('boom'));
      return buildBloc();
    },
    seed: () => JournalDailyEditState.initial().copyWith(
      status: const JournalDailyEditIdle(),
      selectedDayLocal: DateTime(2025, 1, 14),
      definitionById: const {
        'daily': TrackerDefinition(
          id: 'daily',
          name: 'Sleep',
          scope: 'daily',
          valueType: 'int',
          createdAt: TestConstants.referenceDate,
          updatedAt: TestConstants.referenceDate,
        ),
      },
    ),
    act: (bloc) => bloc.add(
      const JournalDailyEditValueChanged(trackerId: 'daily', value: 1),
    ),
    expect: () => [
      isA<JournalDailyEditState>().having(
        (s) => s.status,
        'status',
        isA<JournalDailyEditSaving>(),
      ),
      isA<JournalDailyEditState>().having(
        (s) => s.status,
        'status',
        isA<JournalDailyEditError>(),
      ),
    ],
  );
}
