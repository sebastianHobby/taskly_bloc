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

  blocTestSafe<JournalTrackerWizardBloc, JournalTrackerWizardState>(
    'saves tracker with forced entry scope',
    build: () => JournalTrackerWizardBloc(
      repository: repository,
      errorReporter: errorReporter,
      nowUtc: () => DateTime.utc(2026, 1, 1),
      forcedScope: JournalTrackerScopeOption.entry,
    ),
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
    build: () => JournalTrackerWizardBloc(
      repository: repository,
      errorReporter: errorReporter,
      nowUtc: () => DateTime.utc(2026, 1, 1),
      forcedScope: JournalTrackerScopeOption.day,
    ),
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
}
