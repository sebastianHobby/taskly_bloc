@Tags(['unit', 'scheduled'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_timeline_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late ScheduledOccurrencesService occurrencesService;
  late OccurrenceReadService occurrenceReadService;
  late OccurrenceStreamExpanderContract occurrenceExpander;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockNowService nowService;
  late TestStreamController<TemporalTriggerEvent> temporalController;

  ScheduledTimelineBloc buildBloc() {
    return ScheduledTimelineBloc(
      occurrencesService: occurrencesService,
      sessionDayKeyService: sessionDayKeyService,
      nowService: nowService,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
  }

  setUp(() {
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    occurrenceExpander = _NoopOccurrenceExpander();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    nowService = MockNowService();
    temporalController = TestStreamController.seeded(const AppResumed());
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();

    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));
    occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      dayKeyService: dayKeyService,
      occurrenceExpander: occurrenceExpander,
    );
    occurrencesService = ScheduledOccurrencesService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceReadService: occurrenceReadService,
    );
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );
    sessionDayKeyService.start();
    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15));
    when(() => taskRepository.watchAll(any())).thenAnswer(
      (_) => Stream.value(const <Task>[]),
    );
    when(() => projectRepository.watchAll(any())).thenAnswer(
      (_) => Stream.value(const <Project>[]),
    );
    when(() => taskRepository.watchCompletionHistory()).thenAnswer(
      (_) => Stream.value(const <CompletionHistoryData>[]),
    );
    when(() => taskRepository.watchRecurrenceExceptions()).thenAnswer(
      (_) => Stream.value(const <RecurrenceExceptionData>[]),
    );
    when(() => projectRepository.watchCompletionHistory()).thenAnswer(
      (_) => Stream.value(const <CompletionHistoryData>[]),
    );
    when(() => projectRepository.watchRecurrenceExceptions()).thenAnswer(
      (_) => Stream.value(const <RecurrenceExceptionData>[]),
    );
    addTearDown(temporalController.close);
    addTearDown(sessionDayKeyService.dispose);
    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<ScheduledTimelineBloc, ScheduledTimelineState>(
    'emits loaded state when occurrences arrive',
    build: buildBloc,
    expect: () => [
      isA<ScheduledTimelineLoaded>()
          .having((s) => s.today, 'today', DateTime(2025, 1, 15))
          .having((s) => s.occurrences.length, 'occurrences', 0),
    ],
  );

  blocTestSafe<ScheduledTimelineBloc, ScheduledTimelineState>(
    'emits error when occurrences stream fails',
    build: () {
      when(
        () => taskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.error(StateError('boom')));
      return buildBloc();
    },
    expect: () => [
      isA<ScheduledTimelineError>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
      isA<ScheduledTimelineError>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
      isA<ScheduledTimelineError>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
    ],
  );

  blocTestSafe<ScheduledTimelineBloc, ScheduledTimelineState>(
    'day jump sets scroll target',
    build: buildBloc,
    act: (bloc) => bloc.add(
      ScheduledTimelineDayJumpRequested(day: DateTime(2025, 1, 10)),
    ),
    expect: () => [
      isA<ScheduledTimelineLoaded>(),
      isA<ScheduledTimelineLoaded>()
          .having(
            (s) => s.scrollTargetDay,
            'scrollTargetDay',
            DateTime(2025, 1, 15),
          )
          .having((s) => s.scrollToDaySignal, 'scrollToDaySignal', 1),
    ],
  );
}

class _NoopOccurrenceExpander implements OccurrenceStreamExpanderContract {
  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    return tasksStream;
  }

  @override
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    return projectsStream;
  }

  @override
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    return tasks;
  }

  @override
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    return projects;
  }
}
