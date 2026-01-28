@Tags(['unit', 'journal'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_tracker_wizard_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart' show OperationContext;

class MockJournalRepository extends Mock implements JournalRepositoryContract {}

class MockAppErrorReporter extends Mock implements AppErrorReporter {}

class FakeOperationContext extends Fake implements OperationContext {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUpAll(() {
    registerFallbackValue(FakeOperationContext());
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
  late MockAppErrorReporter errorReporter;

  setUp(() {
    repository = MockJournalRepository();
    errorReporter = MockAppErrorReporter();

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
    'saves daily quantity tracker with add op',
    build: () => JournalTrackerWizardBloc(
      repository: repository,
      errorReporter: errorReporter,
      nowUtc: () => DateTime.utc(2026, 1, 1),
    ),
    act: (bloc) {
      bloc.add(const JournalTrackerWizardStarted());
      bloc.add(const JournalTrackerWizardNameChanged('Water'));
      bloc.add(
        const JournalTrackerWizardScopeChanged(
          JournalTrackerScopeOption.day,
        ),
      );
      bloc.add(
        const JournalTrackerWizardMeasurementChanged(
          JournalTrackerMeasurementType.quantity,
        ),
      );
      bloc.add(
        const JournalTrackerWizardQuantityConfigChanged(
          unit: 'cups',
          min: 0,
          max: 20,
          step: 1,
        ),
      );
      bloc.add(const JournalTrackerWizardSaveRequested());
    },
    verify: (_) {
      expect(
        _.state,
        isA<JournalTrackerWizardSaved>(),
      );
      final captured =
          verify(
                () => repository.saveTrackerDefinition(
                  captureAny(),
                  context: any(named: 'context'),
                ),
              ).captured.single
              as TrackerDefinition;
      expect(captured.scope, 'day');
      expect(captured.valueType, 'quantity');
      expect(captured.valueKind, 'number');
      expect(captured.opKind, 'add');
      expect(captured.unitKind, 'cups');
      expect(captured.minInt, 0);
      expect(captured.maxInt, 20);
      expect(captured.stepInt, 1);
    },
  );

  blocTestSafe<JournalTrackerWizardBloc, JournalTrackerWizardState>(
    'saves choice tracker and choices',
    build: () {
      final existing = TrackerDefinition(
        id: 'def-1',
        name: 'Places',
        scope: 'entry',
        valueType: 'choice',
        valueKind: 'single_choice',
        opKind: 'set',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      when(
        () => repository.watchTrackerDefinitions(),
      ).thenAnswer((_) => Stream.value([existing]));
      return JournalTrackerWizardBloc(
        repository: repository,
        errorReporter: errorReporter,
        nowUtc: () => DateTime.utc(2026, 1, 1),
      );
    },
    act: (bloc) {
      bloc.add(const JournalTrackerWizardStarted());
      bloc.add(const JournalTrackerWizardNameChanged('Places'));
      bloc.add(
        const JournalTrackerWizardScopeChanged(
          JournalTrackerScopeOption.entry,
        ),
      );
      bloc.add(
        const JournalTrackerWizardMeasurementChanged(
          JournalTrackerMeasurementType.choice,
        ),
      );
      bloc.add(const JournalTrackerWizardChoiceAdded('Home'));
      bloc.add(const JournalTrackerWizardChoiceAdded('Work'));
      bloc.add(const JournalTrackerWizardSaveRequested());
    },
    verify: (_) {
      expect(
        _.state,
        isA<JournalTrackerWizardSaved>(),
      );
      verify(
        () => repository.saveTrackerDefinition(
          any(),
          context: any(named: 'context'),
        ),
      ).called(1);
      verify(
        () => repository.saveTrackerDefinitionChoice(
          any(),
          context: any(named: 'context'),
        ),
      ).called(2);
    },
  );
}
