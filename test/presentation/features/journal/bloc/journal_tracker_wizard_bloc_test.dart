@Tags(['unit', 'journal'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_tracker_wizard_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart' show OperationContext;
import 'package:flutter/material.dart';

class MockJournalRepository extends Mock implements JournalRepositoryContract {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUpAll(() {
    registerAllFallbackValues();
    registerFallbackValue(
      OperationContext(
        correlationId: 'fallback-correlation-id',
        feature: 'journal',
        intent: 'fallback',
        operation: 'fallback',
      ),
    );
    registerFallbackValue(
      TrackerDefinition(
        id: 'id',
        name: 'Name',
        scope: 'entry',
        valueType: 'yes_no',
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );
    registerFallbackValue(
      TrackerDefinitionChoice(
        id: 'id',
        trackerId: 'tracker',
        choiceKey: 'choice',
        label: 'Choice',
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepository repository;
  late AppErrorReporter errorReporter;

  setUp(() {
    repository = MockJournalRepository();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );

    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => Stream.value(const <TrackerGroup>[]));
    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => Stream.value(const <TrackerDefinition>[]));
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.saveTrackerDefinitionChoice(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  JournalTrackerWizardBloc buildBloc({JournalTrackerScopeOption? forcedScope}) {
    return JournalTrackerWizardBloc(
      repository: repository,
      errorReporter: errorReporter,
      nowUtc: () => DateTime.utc(2026, 1, 1),
      forcedScope: forcedScope,
    );
  }

  testSafe('validation: name is required', () async {
    final bloc = buildBloc(forcedScope: JournalTrackerScopeOption.entry);
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bloc.state.status,
      isA<JournalTrackerWizardError>().having(
        (e) => e.message,
        'message',
        'Name is required.',
      ),
    );
  });

  testSafe('validation: scope is required when not forced', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardNameChanged('Energy'));
    bloc.add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.toggle,
      ),
    );
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bloc.state.status,
      isA<JournalTrackerWizardError>().having(
        (e) => e.message,
        'message',
        'Choose a scope.',
      ),
    );
  });

  testSafe('validation: measurement is required', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardNameChanged('Energy'));
    bloc.add(
      const JournalTrackerWizardScopeChanged(JournalTrackerScopeOption.day),
    );
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bloc.state.status,
      isA<JournalTrackerWizardError>().having(
        (e) => e.message,
        'message',
        'Choose a measurement type.',
      ),
    );
  });

  testSafe('validation: entry trackers require group', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardNameChanged('Energy'));
    bloc.add(
      const JournalTrackerWizardScopeChanged(JournalTrackerScopeOption.entry),
    );
    bloc.add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.toggle,
      ),
    );
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bloc.state.status,
      isA<JournalTrackerWizardError>().having(
        (e) => e.message,
        'message',
        'Choose a group.',
      ),
    );
  });

  testSafe('validation: invalid rating range is rejected', () async {
    final bloc = buildBloc(forcedScope: JournalTrackerScopeOption.day);
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardNameChanged('Stress'));
    bloc.add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.rating,
      ),
    );
    bloc.add(
      const JournalTrackerWizardRatingConfigChanged(min: 5, max: 5, step: 1),
    );
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bloc.state.status,
      isA<JournalTrackerWizardError>().having(
        (e) => e.message,
        'message',
        'Check rating range.',
      ),
    );
  });

  testSafe('validation: invalid quantity step is rejected', () async {
    final bloc = buildBloc(forcedScope: JournalTrackerScopeOption.day);
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardNameChanged('Water'));
    bloc.add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.quantity,
      ),
    );
    bloc.add(
      const JournalTrackerWizardQuantityConfigChanged(
        unit: 'ml',
        min: 0,
        max: 100,
        step: 0,
      ),
    );
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bloc.state.status,
      isA<JournalTrackerWizardError>().having(
        (e) => e.message,
        'message',
        'Step must be > 0.',
      ),
    );
  });

  testSafe('validation: choice measurement requires options', () async {
    final bloc = buildBloc(forcedScope: JournalTrackerScopeOption.day);
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardNameChanged('Context'));
    bloc.add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.choice,
      ),
    );
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      bloc.state.status,
      isA<JournalTrackerWizardError>().having(
        (e) => e.message,
        'message',
        'Add at least one option.',
      ),
    );
  });

  blocTestSafe<JournalTrackerWizardBloc, JournalTrackerWizardState>(
    'saves tracker with forced entry scope',
    build: () {
      when(
        () => repository.watchTrackerGroups(),
      ).thenAnswer(
        (_) => Stream.value(
          [
            TrackerGroup(
              id: 'group-1',
              name: 'Health',
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
              isActive: true,
              sortOrder: 0,
              userId: null,
            ),
          ],
        ),
      );
      return buildBloc(forcedScope: JournalTrackerScopeOption.entry);
    },
    act: (bloc) {
      bloc.add(const JournalTrackerWizardStarted());
      bloc.add(const JournalTrackerWizardNameChanged('Mood'));
      bloc.add(
        const JournalTrackerWizardMeasurementChanged(
          JournalTrackerMeasurementType.toggle,
        ),
      );
      bloc.add(const JournalTrackerWizardSaveRequested());
    },
    verify: (bloc) {
      expect(bloc.state.status, isA<JournalTrackerWizardSaved>());
      final captured =
          verify(
                () => repository.saveTrackerDefinition(
                  captureAny(),
                  context: any(named: 'context'),
                ),
              ).captured.single
              as TrackerDefinition;
      expect(captured.scope, 'entry');
    },
  );

  blocTestSafe<JournalTrackerWizardBloc, JournalTrackerWizardState>(
    'saves daily check-in quantity tracker with add op',
    build: () => buildBloc(forcedScope: JournalTrackerScopeOption.day),
    act: (bloc) {
      bloc.add(const JournalTrackerWizardStarted());
      bloc.add(const JournalTrackerWizardNameChanged('Water'));
      bloc.add(
        const JournalTrackerWizardMeasurementChanged(
          JournalTrackerMeasurementType.quantity,
        ),
      );
      bloc.add(
        const JournalTrackerWizardQuantityConfigChanged(
          unit: 'ml',
          min: 0,
          max: 5000,
          step: 250,
        ),
      );
      bloc.add(const JournalTrackerWizardSaveRequested());
    },
    verify: (bloc) {
      expect(bloc.state.status, isA<JournalTrackerWizardSaved>());
      final captured =
          verify(
                () => repository.saveTrackerDefinition(
                  captureAny(),
                  context: any(named: 'context'),
                ),
              ).captured.single
              as TrackerDefinition;
      expect(captured.scope, 'day');
      expect(captured.opKind, 'add');
    },
  );

  testSafe('choice keys are normalized and made unique', () async {
    final defsController = TestStreamController.seeded(<TrackerDefinition>[]);
    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsController.stream);

    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((invocation) async {
      final requested =
          invocation.positionalArguments.first as TrackerDefinition;
      defsController.emit([
        TrackerDefinition(
          id: 'saved-1',
          name: requested.name,
          scope: requested.scope,
          valueType: requested.valueType,
          valueKind: requested.valueKind,
          createdAt: requested.createdAt,
          updatedAt: requested.updatedAt,
        ),
      ]);
    });

    final bloc = buildBloc(forcedScope: JournalTrackerScopeOption.day);
    addTearDown(() async {
      await defsController.close();
      await bloc.close();
    });

    bloc.add(const JournalTrackerWizardNameChanged('Social'));
    bloc.add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.choice,
      ),
    );
    bloc.add(const JournalTrackerWizardChoiceAdded('Home'));
    bloc.add(const JournalTrackerWizardChoiceAdded('Home'));
    bloc.add(const JournalTrackerWizardChoiceAdded('Home!'));
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final captured = verify(
      () => repository.saveTrackerDefinitionChoice(
        captureAny(),
        context: any(named: 'context'),
      ),
    ).captured.whereType<TrackerDefinitionChoice>().toList(growable: false);

    expect(captured.map((c) => c.choiceKey).toList(), [
      'home',
      'home_2',
      'home_3',
    ]);
  });

  testSafe('group stream error maps to wizard error state', () async {
    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => Stream.error(StateError('boom')));

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.status, isA<JournalTrackerWizardError>());
  });

  testSafe('save failure maps to wizard error state', () async {
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenThrow(StateError('boom'));

    final bloc = buildBloc(forcedScope: JournalTrackerScopeOption.day);
    addTearDown(bloc.close);

    bloc.add(const JournalTrackerWizardNameChanged('Water'));
    bloc.add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.toggle,
      ),
    );
    bloc.add(const JournalTrackerWizardSaveRequested());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.status, isA<JournalTrackerWizardError>());
  });
}
