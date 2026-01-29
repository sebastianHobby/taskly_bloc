@Tags(['unit', 'scheduled'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_timeline_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/services.dart';

class MockScheduledOccurrencesService extends Mock
    implements ScheduledOccurrencesService {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockScheduledOccurrencesService occurrencesService;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockNowService nowService;
  late TestStreamController<TemporalTriggerEvent> temporalController;
  late TestStreamController<ScheduledOccurrencesResult> resultController;

  ScheduledTimelineBloc buildBloc() {
    return ScheduledTimelineBloc(
      occurrencesService: occurrencesService,
      sessionDayKeyService: sessionDayKeyService,
      nowService: nowService,
    );
  }

  setUp(() {
    occurrencesService = MockScheduledOccurrencesService();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    nowService = MockNowService();
    temporalController = TestStreamController.seeded(const AppResumed());
    resultController = TestStreamController.seeded(
      ScheduledOccurrencesResult(
        rangeStartDay: DateTime.utc(2025, 1, 15),
        rangeEndDay: DateTime.utc(2025, 3, 31),
        overdue: const [],
        occurrences: const [],
      ),
    );

    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );
    sessionDayKeyService.start();
    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15));
    when(
      () => occurrencesService.watchScheduledOccurrences(
        rangeStartDay: any(named: 'rangeStartDay'),
        rangeEndDay: any(named: 'rangeEndDay'),
        todayDayKeyUtc: any(named: 'todayDayKeyUtc'),
        scope: any(named: 'scope'),
      ),
    ).thenAnswer((_) => resultController.stream);

    addTearDown(temporalController.close);
    addTearDown(sessionDayKeyService.dispose);
    addTearDown(resultController.close);
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
        () => occurrencesService.watchScheduledOccurrences(
          rangeStartDay: any(named: 'rangeStartDay'),
          rangeEndDay: any(named: 'rangeEndDay'),
          todayDayKeyUtc: any(named: 'todayDayKeyUtc'),
          scope: any(named: 'scope'),
        ),
      ).thenAnswer((_) => Stream.error(StateError('boom')));
      return buildBloc();
    },
    expect: () => [
      isA<ScheduledTimelineError>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
    ],
  );

  blocTestSafe<ScheduledTimelineBloc, ScheduledTimelineState>(
    'toggles overdue collapsed',
    build: buildBloc,
    act: (bloc) => bloc.add(const ScheduledTimelineOverdueCollapsedToggled()),
    expect: () => [
      isA<ScheduledTimelineLoaded>(),
      isA<ScheduledTimelineLoaded>().having(
        (s) => s.overdueCollapsed,
        'overdueCollapsed',
        true,
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
