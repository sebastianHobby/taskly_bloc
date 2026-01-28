@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockMyDaySessionQueryService queryService;
  late MockRoutineWriteService routineWriteService;
  late MockNowService nowService;
  late BehaviorSubject<MyDayViewModel> subject;

  MyDayViewModel buildViewModel() {
    final dayKey = DateTime(2025, 1, 15);
    final ritual = MyDayRitualStatus.fromDayPicks(
      MyDayDayPicks(
        dayKeyUtc: dayKey,
        ritualCompletedAtUtc: null,
        picks: const <MyDayPick>[],
      ),
    );
    return MyDayViewModel(
      tasks: const <Task>[],
      plannedItems: const <MyDayPlannedItem>[],
      ritualStatus: ritual,
      summary: const MyDaySummary(doneCount: 0, totalCount: 0),
      mix: MyDayMixVm.empty,
      pinnedTasks: const <Task>[],
      completedPicks: const <Task>[],
      selectedTotalCount: 0,
      todaySelectedTaskIds: const <String>{},
      todaySelectedRoutineIds: const <String>{},
    );
  }

  setUp(() {
    queryService = MockMyDaySessionQueryService();
    routineWriteService = MockRoutineWriteService();
    nowService = MockNowService();
    subject = BehaviorSubject<MyDayViewModel>.seeded(buildViewModel());
    when(() => queryService.viewModel).thenReturn(subject);
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15, 12));
    addTearDown(subject.close);
  });

  blocTestSafe<MyDayBloc, MyDayState>(
    'maps view model into loaded state',
    build: () => MyDayBloc(
      queryService: queryService,
      routineWriteService: routineWriteService,
      nowService: nowService,
    ),
    expect: () => [isA<MyDayLoaded>()],
  );

  blocTestSafe<MyDayBloc, MyDayState>(
    'records routine completion when toggled to complete',
    build: () {
      when(
        () => routineWriteService.recordCompletion(
          routineId: any(named: 'routineId'),
          completedAtUtc: any(named: 'completedAtUtc'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
      return MyDayBloc(
        queryService: queryService,
        routineWriteService: routineWriteService,
        nowService: nowService,
      );
    },
    act: (bloc) => bloc.add(
      MyDayRoutineCompletionToggled(
        routineId: 'routine-1',
        completedToday: false,
        dayKeyUtc: DateTime.utc(2025, 1, 15),
      ),
    ),
    verify: (_) {
      verify(
        () => routineWriteService.recordCompletion(
          routineId: 'routine-1',
          completedAtUtc: DateTime.utc(2025, 1, 15, 12),
          context: any(named: 'context'),
        ),
      ).called(1);
    },
  );
}
