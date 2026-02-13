@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_tracker_wizard_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_tracker_wizard_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';

class FakeNowService implements NowService {
  FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

Finder _stepperPrimaryButtonFinder(WidgetTester tester) {
  final stepper = tester.widget<Stepper>(find.byType(Stepper));
  return find
      .byKey(
        ValueKey('journal_tracker_wizard_next_step_${stepper.currentStep}'),
      )
      .first;
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late AppErrorReporter errorReporter;
  late BehaviorSubject<List<TrackerGroup>> groupsSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    groupsSubject = BehaviorSubject<List<TrackerGroup>>.seeded(
      const <TrackerGroup>[],
    );

    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => groupsSubject);
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

  tearDown(() async {
    await groupsSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<JournalRepositoryContract>.value(
            value: repository,
          ),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: const JournalTrackerWizardPage(),
      ),
    );
  }

  testWidgetsSafe('shows error snack bar when groups stream fails', (
    tester,
  ) async {
    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => Stream<List<TrackerGroup>>.error('boom'));

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.textContaining('Failed to load groups'), findsOneWidget);
  });

  testWidgetsSafe('renders stepper with group options', (tester) async {
    final group = _group('group-1', 'Health');
    groupsSubject.add([group]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('New tracker'), findsOneWidget);
    expect(find.text('Name'), findsWidgets);

    await tester.tap(find.text('Ungrouped'));
    await tester.pumpForStream();

    expect(find.text('Health'), findsOneWidget);
  });

  testWidgetsSafe('requires name and scope before continuing', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    final nextButton = _nextButtonWidget(tester);
    expect(nextButton.onPressed, isNull);
    expect(find.text('Daily total').hitTestable(), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Daily check-in');
    await tester.pumpForStream();
    await _tapNext(tester);
    expect(find.text('Daily total'), findsOneWidget);

    final disabledNext = _nextButtonWidget(tester);
    expect(disabledNext.onPressed, isNull);
    expect(find.text('Toggle').hitTestable(), findsNothing);
  });

  testWidgetsSafe('validates measurement selection before create', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Tracker');

    final createButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('journal_tracker_wizard_next_step_2')),
    );
    expect(createButton.onPressed, isNull);
  });

  testWidgetsSafe('shows error for invalid rating range', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Energy');
    await _tapTextOption(tester, 'Rating');

    await tester.enterText(find.widgetWithText(TextField, 'Min'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Max'), '3');
    await tester.enterText(find.widgetWithText(TextField, 'Step'), '1');

    _wizardBloc(tester).add(const JournalTrackerWizardSaveRequested());
    await tester.pumpForStream();
    final foundSnack = await tester.pumpUntilFound(find.byType(SnackBar));
    expect(foundSnack, isTrue);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgetsSafe('shows error for invalid quantity step', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Steps');
    await _tapTextOption(tester, 'Quantity');

    await tester.enterText(find.widgetWithText(TextField, 'Step'), '0');

    _wizardBloc(tester).add(const JournalTrackerWizardSaveRequested());
    await tester.pumpForStream();
    final foundSnack = await tester.pumpUntilFound(find.byType(SnackBar));
    expect(foundSnack, isTrue);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgetsSafe('shows error when choice has no options', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Context');
    await _tapTextOption(tester, 'Choice');

    final createButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('journal_tracker_wizard_next_step_2')),
    );
    expect(createButton.onPressed, isNull);
    expect(find.textContaining('Add at least one option'), findsOneWidget);
  });

  testWidgetsSafe('choice UI adds and removes options', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Location');
    await _tapTextOption(tester, 'Choice');

    await tester.enterText(find.widgetWithText(TextField, 'Option'), 'Home');
    await _tapButton(tester, 'Add');

    expect(find.byType(TextFormField), findsOneWidget);

    final removeFinder = find.byIcon(Icons.close);
    await tester.ensureVisible(removeFinder);
    await tester.pumpUntilCondition(
      () => removeFinder.hitTestable().evaluate().isNotEmpty,
    );
    await tester.tap(removeFinder.hitTestable());
    await tester.pumpForStream();

    expect(find.textContaining('Add at least one option'), findsOneWidget);
  });

  testWidgetsSafe('creates tracker and reports saved state', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Mood');
    await _tapTextOption(tester, 'Toggle');

    final bloc = _wizardBloc(tester);
    bloc.add(const JournalTrackerWizardSaveRequested());
    await tester.pumpUntilCondition(
      () => bloc.state.status is JournalTrackerWizardSaved,
    );
    expect(bloc.state.status, isA<JournalTrackerWizardSaved>());
    verify(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testWidgetsSafe('shows error snack when save fails', (tester) async {
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenThrow(Exception('save failed'));

    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Mood');
    await _tapTextOption(tester, 'Toggle');

    final bloc = _wizardBloc(tester);
    bloc.add(const JournalTrackerWizardSaveRequested());
    await tester.pumpUntilCondition(
      () => bloc.state.status is JournalTrackerWizardError,
    );
    expect(bloc.state.status, isA<JournalTrackerWizardError>());
  });

  testWidgetsSafe('shows rating config fields when rating selected', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Energy');
    await _tapTextOption(tester, 'Rating');

    expect(find.widgetWithText(TextField, 'Min'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Max'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Step'), findsOneWidget);
  });

  testWidgetsSafe('shows quantity config fields when quantity selected', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Water');
    await _tapTextOption(tester, 'Quantity');

    expect(find.widgetWithText(TextField, 'Unit (optional)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Min (optional)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Max (optional)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Step'), findsOneWidget);
  });
}

Future<void> _goToMeasurementStep(
  WidgetTester tester, {
  required String name,
}) async {
  await tester.enterText(find.byType(TextField).first, name);
  await tester.pumpForStream();
  await _tapNext(tester);

  await _tapTextOption(tester, 'Daily total');
  await tester.pumpForStream();

  await _tapNext(tester);
}

Future<void> _tapNext(WidgetTester tester) async {
  final stepper = tester.widget<Stepper>(find.byType(Stepper));
  final currentStep = stepper.currentStep;
  final nextFinder = _stepperPrimaryButtonFinder(tester);
  final button = tester.widget<FilledButton>(nextFinder);
  expect(button.onPressed, isNotNull);
  await tester.ensureVisible(nextFinder);
  await tester.pumpUntilCondition(
    () => nextFinder.hitTestable().evaluate().isNotEmpty,
  );
  final hitTestable = nextFinder.hitTestable();
  await tester.tap(
    hitTestable.evaluate().isNotEmpty ? hitTestable : nextFinder,
    warnIfMissed: false,
  );
  await tester.pumpForStream();
  if (currentStep < 2) {
    await tester.pumpUntilFound(
      find.byKey(
        ValueKey('journal_tracker_wizard_next_step_${currentStep + 1}'),
      ),
    );
  }
}

FilledButton _nextButtonWidget(WidgetTester tester) {
  return tester
      .widgetList<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      )
      .first;
}

Future<void> _tapTextOption(WidgetTester tester, String text) async {
  Finder optionFinder = find.text(text);
  final radioFinder = find.widgetWithText(RadioListTile, text);
  if (radioFinder.evaluate().isNotEmpty) {
    optionFinder = radioFinder;
  } else {
    final tileFinder = find.widgetWithText(ListTile, text);
    if (tileFinder.evaluate().isNotEmpty) {
      optionFinder = tileFinder;
    }
  }
  final hitTestable = optionFinder.hitTestable();
  optionFinder = hitTestable.evaluate().isNotEmpty
      ? hitTestable.first
      : optionFinder.first;
  await tester.ensureVisible(optionFinder);
  await tester.pumpUntilCondition(
    () => optionFinder.hitTestable().evaluate().isNotEmpty,
  );
  await tester.tap(optionFinder.hitTestable());
  await tester.pumpForStream();
}

Future<void> _tapButton(WidgetTester tester, String text) async {
  if (text == 'Create' || text == 'Next') {
    final stepperFinder = _stepperPrimaryButtonFinder(tester);
    final stepper = tester.widget<Stepper>(find.byType(Stepper));
    final currentStep = stepper.currentStep;
    final button = tester.widget<FilledButton>(stepperFinder);
    expect(button.onPressed, isNotNull);
    await tester.ensureVisible(stepperFinder);
    await tester.pumpUntilCondition(
      () => stepperFinder.hitTestable().evaluate().isNotEmpty,
    );
    final hitTestable = stepperFinder.hitTestable();
    await tester.tap(
      hitTestable.evaluate().isNotEmpty ? hitTestable : stepperFinder,
      warnIfMissed: false,
    );
    await tester.pumpForStream();
    if (text == 'Next' && currentStep < 2) {
      await tester.pumpUntilFound(
        find.byKey(
          ValueKey('journal_tracker_wizard_next_step_${currentStep + 1}'),
        ),
      );
    }
    return;
  }
  final buttonFinder = find.widgetWithText(TextButton, text);
  final filledFinder = find.widgetWithText(FilledButton, text);
  final finder = filledFinder.evaluate().isNotEmpty
      ? filledFinder
      : buttonFinder;
  await tester.ensureVisible(finder.first);
  await tester.pumpUntilCondition(
    () => finder.first.hitTestable().evaluate().isNotEmpty,
  );
  await tester.tap(finder.first.hitTestable());
  await tester.pumpForStream();
}

TrackerGroup _group(String id, String name) {
  final now = DateTime(2025, 1, 15);
  return TrackerGroup(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
    isActive: true,
    sortOrder: 0,
    userId: null,
  );
}

JournalTrackerWizardBloc _wizardBloc(WidgetTester tester) {
  return tester.element(find.byType(Stepper)).read<JournalTrackerWizardBloc>();
}
