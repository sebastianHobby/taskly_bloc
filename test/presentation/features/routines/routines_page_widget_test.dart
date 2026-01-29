@Tags(['widget', 'routines'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routines_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';

class MockRoutineRepository extends Mock implements RoutineRepositoryContract {}

class MockSessionDayKeyService extends Mock implements SessionDayKeyService {}

class MockErrorReporter extends Mock implements AppErrorReporter {}

class MockSharedDataService extends Mock implements SessionSharedDataService {}

class MockRoutineWriteService extends Mock implements RoutineWriteService {}

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

  late MockRoutineRepository routineRepository;
  late MockSessionDayKeyService sessionDayKeyService;
  late MockErrorReporter errorReporter;
  late MockSharedDataService sharedDataService;
  late MockRoutineWriteService routineWriteService;

  late BehaviorSubject<DateTime> dayKeySubject;
  late BehaviorSubject<List<Routine>> routinesSubject;
  late BehaviorSubject<List<RoutineCompletion>> completionsSubject;
  late BehaviorSubject<List<RoutineSkip>> skipsSubject;
  late BehaviorSubject<List<Value>> valuesSubject;

  setUp(() {
    routineRepository = MockRoutineRepository();
    sessionDayKeyService = MockSessionDayKeyService();
    errorReporter = MockErrorReporter();
    sharedDataService = MockSharedDataService();
    routineWriteService = MockRoutineWriteService();

    dayKeySubject = BehaviorSubject<DateTime>.seeded(DateTime.utc(2025, 1, 15));
    routinesSubject = BehaviorSubject<List<Routine>>.seeded(const <Routine>[]);
    completionsSubject = BehaviorSubject<List<RoutineCompletion>>.seeded(
      const <RoutineCompletion>[],
    );
    skipsSubject = BehaviorSubject<List<RoutineSkip>>.seeded(
      const <RoutineSkip>[],
    );
    valuesSubject = BehaviorSubject<List<Value>>.seeded(const <Value>[]);

    when(() => sessionDayKeyService.todayDayKeyUtc).thenReturn(dayKeySubject);

    when(
      () => routineRepository.watchAll(includeInactive: true),
    ).thenAnswer((_) => routinesSubject.stream);
    when(
      () => routineRepository.watchCompletions(),
    ).thenAnswer((_) => completionsSubject.stream);
    when(
      () => routineRepository.watchSkips(),
    ).thenAnswer((_) => skipsSubject.stream);

    when(
      () => sharedDataService.watchValues(),
    ).thenAnswer((_) => valuesSubject);
  });

  tearDown(() async {
    await dayKeySubject.close();
    await routinesSubject.close();
    await completionsSubject.close();
    await skipsSubject.close();
    await valuesSubject.close();
  });

  Routine buildRoutine({
    required String id,
    required String name,
    required Value value,
  }) {
    return Routine(
      id: id,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      name: name,
      valueId: value.id,
      routineType: RoutineType.weeklyFixed,
      targetCount: 1,
      scheduleDays: const [1],
      value: value,
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RoutineRepositoryContract>.value(
            value: routineRepository,
          ),
          RepositoryProvider<SessionDayKeyService>.value(
            value: sessionDayKeyService,
          ),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
          RepositoryProvider<SessionSharedDataService>.value(
            value: sharedDataService,
          ),
          RepositoryProvider<RoutineWriteService>.value(
            value: routineWriteService,
          ),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: const RoutinesPage(),
      ),
    );
  }

  testWidgetsSafe('shows loading state while routines load', (tester) async {
    final completer = Completer<List<Routine>>();
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) => completer.future);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);

    expect(find.byKey(const ValueKey('feed-loading')), findsOneWidget);

    completer.complete(const <Routine>[]);
  });

  testWidgetsSafe('shows error state when repository throws', (tester) async {
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenThrow(Exception('routine load failed'));
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.textContaining('routine load failed'), findsOneWidget);
  });

  testWidgetsSafe('renders routine list content when loaded', (tester) async {
    final value = TestData.value(name: 'Health');
    final routine = buildRoutine(
      id: 'routine-1',
      name: 'Morning Walk',
      value: value,
    );

    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => [routine]);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);
    routinesSubject.add([routine]);
    valuesSubject.add([value]);
    await tester.pumpForStream();

    expect(find.text('Morning Walk'), findsOneWidget);
  });

  testWidgetsSafe('updates list when routines change', (tester) async {
    final value = TestData.value(name: 'Focus');
    final routineA = buildRoutine(
      id: 'routine-a',
      name: 'Stretch',
      value: value,
    );
    final routineB = buildRoutine(id: 'routine-b', name: 'Read', value: value);

    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => [routineA]);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);
    routinesSubject.add([routineA]);
    valuesSubject.add([value]);
    await tester.pumpForStream();

    expect(find.text('Stretch'), findsOneWidget);

    routinesSubject.add([routineA, routineB]);
    await tester.pumpForStream();

    expect(find.text('Read'), findsOneWidget);
  });
}
