@Tags(['unit', 'scheduled'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_timeline_bloc.dart';
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
  late MockSessionDayKeyService sessionDayKeyService;
  late MockNowService nowService;
  late BehaviorSubject<DateTime> dayKeySubject;
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
    sessionDayKeyService = MockSessionDayKeyService();
    nowService = MockNowService();
    dayKeySubject = BehaviorSubject<DateTime>.seeded(DateTime.utc(2025, 1, 15));
    resultController = TestStreamController.seeded(
      ScheduledOccurrencesResult(
        rangeStartDay: DateTime.utc(2025, 1, 15),
        rangeEndDay: DateTime.utc(2025, 3, 31),
        overdue: const [],
        occurrences: const [],
      ),
    );

    when(() => sessionDayKeyService.todayDayKeyUtc).thenReturn(dayKeySubject);
    when(() => sessionDayKeyService.start()).thenAnswer((_) {});
    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15));
    when(
      () => occurrencesService.watchScheduledOccurrences(
        rangeStartDay: any(named: 'rangeStartDay'),
        rangeEndDay: any(named: 'rangeEndDay'),
        todayDayKeyUtc: any(named: 'todayDayKeyUtc'),
        scope: any(named: 'scope'),
      ),
    ).thenAnswer((_) => resultController.stream);

    addTearDown(dayKeySubject.close);
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
      isA<ScheduledTimelineError>()
          .having((s) => s.message, 'message', contains('boom')),
    ],
  );

  blocTestSafe<ScheduledTimelineBloc, ScheduledTimelineState>(
    'toggles overdue collapsed',
    build: buildBloc,
    act: (bloc) => bloc.add(const ScheduledTimelineOverdueCollapsedToggled()),
    expect: () => [
      isA<ScheduledTimelineLoaded>(),
      isA<ScheduledTimelineLoaded>()
          .having((s) => s.overdueCollapsed, 'overdueCollapsed', true),
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
          .having((s) => s.scrollTargetDay, 'scrollTargetDay', DateTime(2025, 1, 15))
          .having((s) => s.scrollToDaySignal, 'scrollToDaySignal', 1),
    ],
  );
}

