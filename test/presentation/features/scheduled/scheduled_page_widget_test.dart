@Tags(['widget', 'scheduled'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_page.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

class MockScheduledOccurrencesService extends Mock
    implements ScheduledOccurrencesService {}

class MockTaskWriteService extends Mock implements TaskWriteService {}

class MockEditorLauncher extends Mock implements EditorLauncher {}

class MockSessionDayKeyService extends Mock implements SessionDayKeyService {}

class FakeNowService implements NowService {
  FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockScheduledOccurrencesService occurrencesService;
  late MockTaskWriteService taskWriteService;
  late MockProjectRepositoryContract projectRepository;
  late MockAllocationOrchestrator allocationOrchestrator;
  late MockOccurrenceCommandService occurrenceCommandService;
  late ProjectWriteService projectWriteService;
  late MockEditorLauncher editorLauncher;
  late MockSessionDayKeyService sessionDayKeyService;
  late BehaviorSubject<DateTime> dayKeySubject;
  late BehaviorSubject<ScheduledOccurrencesResult> occurrencesSubject;

  setUp(() {
    occurrencesService = MockScheduledOccurrencesService();
    taskWriteService = MockTaskWriteService();
    projectRepository = MockProjectRepositoryContract();
    allocationOrchestrator = MockAllocationOrchestrator();
    occurrenceCommandService = MockOccurrenceCommandService();
    projectWriteService = ProjectWriteService(
      projectRepository: projectRepository,
      allocationOrchestrator: allocationOrchestrator,
      occurrenceCommandService: occurrenceCommandService,
    );
    editorLauncher = MockEditorLauncher();
    sessionDayKeyService = MockSessionDayKeyService();

    dayKeySubject = BehaviorSubject<DateTime>.seeded(
      DateTime.utc(2025, 1, 15),
    );
    occurrencesSubject = BehaviorSubject<ScheduledOccurrencesResult>();

    when(() => sessionDayKeyService.todayDayKeyUtc).thenReturn(dayKeySubject);
    when(() => sessionDayKeyService.start()).thenReturn(null);

    when(
      () => occurrencesService.watchScheduledOccurrences(
        rangeStartDay: any(named: 'rangeStartDay'),
        rangeEndDay: any(named: 'rangeEndDay'),
        todayDayKeyUtc: any(named: 'todayDayKeyUtc'),
        scope: any(named: 'scope'),
      ),
    ).thenAnswer((_) => occurrencesSubject.stream);
  });

  tearDown(() async {
    await dayKeySubject.close();
    await occurrencesSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ScheduledOccurrencesService>.value(
            value: occurrencesService,
          ),
          RepositoryProvider<TaskWriteService>.value(value: taskWriteService),
          RepositoryProvider<ProjectWriteService>.value(
            value: projectWriteService,
          ),
          RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
          RepositoryProvider<SessionDayKeyService>.value(
            value: sessionDayKeyService,
          ),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: const ScheduledPage(),
      ),
    );
  }

  ScheduledOccurrencesResult buildResult({
    required DateTime today,
    required List<ScheduledOccurrence> occurrences,
  }) {
    final rangeStart = DateTime(today.year, today.month, today.day);
    final rangeEnd = DateTime(today.year, today.month + 1, 0);
    return ScheduledOccurrencesResult(
      rangeStartDay: rangeStart,
      rangeEndDay: rangeEnd,
      overdue: const <ScheduledOccurrence>[],
      occurrences: occurrences,
    );
  }

  ScheduledOccurrence taskOccurrence({
    required Task task,
    required DateTime day,
  }) {
    return ScheduledOccurrence.forTask(
      ref: ScheduledOccurrenceRef(
        entityType: EntityType.task,
        entityId: task.id,
        localDay: day,
        tag: ScheduledDateTag.due,
      ),
      name: task.name,
      task: task,
    );
  }

  testWidgetsSafe('shows loading state before occurrences emit', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byKey(const ValueKey('feed-loading')), findsOneWidget);
  });

  testWidgetsSafe('shows error state when occurrence stream errors', (
    tester,
  ) async {
    await pumpPage(tester);

    occurrencesSubject.addError(Exception('timeline failed'));
    await tester.pumpForStream();

    expect(find.textContaining('timeline failed'), findsOneWidget);
  });

  testWidgetsSafe('renders scheduled occurrences when loaded', (tester) async {
    await pumpPage(tester);

    final task = TestData.task(name: 'Scheduled Task');
    final today = DateTime(2025, 1, 15);
    occurrencesSubject.add(
      buildResult(
        today: today,
        occurrences: [taskOccurrence(task: task, day: today)],
      ),
    );
    await tester.pumpForStream();

    expect(find.text('Scheduled Task'), findsOneWidget);
  });

  testWidgetsSafe('updates list when occurrences change', (tester) async {
    await pumpPage(tester);

    final taskA = TestData.task(name: 'Task A');
    final taskB = TestData.task(name: 'Task B');
    final today = DateTime(2025, 1, 15);

    occurrencesSubject.add(
      buildResult(
        today: today,
        occurrences: [taskOccurrence(task: taskA, day: today)],
      ),
    );
    await tester.pumpForStream();
    expect(find.text('Task A'), findsOneWidget);

    occurrencesSubject.add(
      buildResult(
        today: today,
        occurrences: [
          taskOccurrence(task: taskA, day: today),
          taskOccurrence(task: taskB, day: today),
        ],
      ),
    );
    await tester.pumpForStream();

    expect(find.text('Task B'), findsOneWidget);
  });
}
