@Tags(['unit', 'routines'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_list_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockRoutineRepositoryContract routineRepository;
  late MockSessionDayKeyService sessionDayKeyService;
  late MockSessionSharedDataService sharedDataService;
  late MockRoutineWriteService routineWriteService;
  late MockNowService nowService;
  late AppErrorReporter errorReporter;

  late BehaviorSubject<List<Routine>> routinesSubject;
  late BehaviorSubject<List<RoutineCompletion>> completionsSubject;
  late BehaviorSubject<List<RoutineSkip>> skipsSubject;
  late BehaviorSubject<List<Value>> valuesSubject;
  late BehaviorSubject<DateTime> dayKeySubject;

  RoutineListBloc buildBloc() {
    return RoutineListBloc(
      routineRepository: routineRepository,
      sessionDayKeyService: sessionDayKeyService,
      errorReporter: errorReporter,
      sharedDataService: sharedDataService,
      routineWriteService: routineWriteService,
      nowService: nowService,
    );
  }

  setUp(() {
    routineRepository = MockRoutineRepositoryContract();
    sessionDayKeyService = MockSessionDayKeyService();
    sharedDataService = MockSessionSharedDataService();
    routineWriteService = MockRoutineWriteService();
    nowService = MockNowService();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );

    routinesSubject = BehaviorSubject<List<Routine>>();
    completionsSubject = BehaviorSubject<List<RoutineCompletion>>();
    skipsSubject = BehaviorSubject<List<RoutineSkip>>();
    valuesSubject = BehaviorSubject<List<Value>>();
    dayKeySubject = BehaviorSubject<DateTime>();

    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => _sampleRoutines());
    when(() => routineRepository.getCompletions()).thenAnswer((_) async => []);
    when(() => routineRepository.getSkips()).thenAnswer((_) async => []);

    when(
      () => routineRepository.watchAll(includeInactive: true),
    ).thenAnswer((_) => routinesSubject.stream);
    when(() => routineRepository.watchCompletions()).thenAnswer(
      (_) => completionsSubject.stream,
    );
    when(() => routineRepository.watchSkips()).thenAnswer(
      (_) => skipsSubject.stream,
    );
    when(() => sharedDataService.watchValues()).thenAnswer(
      (_) => valuesSubject.stream,
    );
    when(() => sessionDayKeyService.todayDayKeyUtc).thenReturn(
      dayKeySubject.stream,
    );

    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15, 12));

    addTearDown(routinesSubject.close);
    addTearDown(completionsSubject.close);
    addTearDown(skipsSubject.close);
    addTearDown(valuesSubject.close);
    addTearDown(dayKeySubject.close);
  });

  blocTestSafe<RoutineListBloc, RoutineListState>(
    'loads routines and emits loaded state',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const RoutineListEvent.subscriptionRequested());
      dayKeySubject.add(DateTime.utc(2025, 1, 15));
      routinesSubject.add(_sampleRoutines());
      completionsSubject.add(const []);
      skipsSubject.add(const []);
      valuesSubject.add([TestData.value(id: 'value-1', name: 'Health')]);
    },
    expect: () => [
      const RoutineListLoading(),
      isA<RoutineListLoaded>().having((s) => s.routines.length, 'count', 1),
      isA<RoutineListLoaded>().having((s) => s.routines.length, 'count', 1),
    ],
  );
}

List<Routine> _sampleRoutines() {
  return [
    Routine(
      id: 'routine-1',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      name: 'Hydrate',
      valueId: 'value-1',
      routineType: RoutineType.weeklyFlexible,
      targetCount: 3,
      scheduleDays: const [1, 3, 5],
      value: TestData.value(id: 'value-1', name: 'Health'),
    ),
  ];
}
