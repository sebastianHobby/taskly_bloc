@Tags(['unit', 'routines'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_detail_support_bloc.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';

class MockAttentionRepositoryContract extends Mock
    implements AttentionRepositoryContract {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(const AttentionQuery());
  });
  setUp(setUpTestEnvironment);

  late MockRoutineRepositoryContract routineRepository;
  late MockAttentionEngineContract attentionEngine;
  late MockAttentionRepositoryContract attentionRepository;
  late AttentionResolutionService attentionResolutionService;
  late MockNowService nowService;

  final nowUtc = DateTime.utc(2026, 2, 18, 12);
  final targetRoutine = Routine(
    id: 'routine-target',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    name: 'Target routine',
    projectId: 'project-1',
    periodType: RoutinePeriodType.week,
    scheduleMode: RoutineScheduleMode.flexible,
    targetCount: 1,
  );

  setUp(() {
    routineRepository = MockRoutineRepositoryContract();
    attentionEngine = MockAttentionEngineContract();
    attentionRepository = MockAttentionRepositoryContract();
    nowService = MockNowService();
    attentionResolutionService = AttentionResolutionService(
      repository: attentionRepository,
      newResolutionId: () => 'resolution-1',
    );

    when(() => nowService.nowUtc()).thenReturn(nowUtc);
    when(() => routineRepository.watchById('routine-target')).thenAnswer(
      (_) => Stream.value(targetRoutine),
    );
    when(() => routineRepository.watchSkips()).thenAnswer(
      (_) => Stream.value(const <RoutineSkip>[]),
    );
    when(() => attentionEngine.watch(any())).thenAnswer(
      (_) => Stream.value(const <AttentionItem>[]),
    );
    when(
      () => attentionRepository.watchResolutionsForEntity(
        'routine-target',
        AttentionEntityType.routine,
      ),
    ).thenAnswer((_) => Stream.value(const <AttentionResolution>[]));
  });

  blocTestSafe<RoutineDetailSupportBloc, RoutineDetailSupportState>(
    'weekly adherence ignores completions from other routines',
    build: () {
      when(() => routineRepository.watchCompletions()).thenAnswer(
        (_) => Stream.value([
          RoutineCompletion(
            id: 'completion-target',
            routineId: 'routine-target',
            completedAtUtc: DateTime.utc(2026, 2, 17, 8),
            createdAtUtc: DateTime.utc(2026, 2, 17, 8),
            completedDayLocal: DateTime.utc(2026, 2, 17),
            completedTimeLocalMinutes: 8 * 60,
          ),
          RoutineCompletion(
            id: 'completion-other',
            routineId: 'routine-other',
            completedAtUtc: DateTime.utc(2026, 2, 17, 9),
            createdAtUtc: DateTime.utc(2026, 2, 17, 9),
            completedDayLocal: DateTime.utc(2026, 2, 17),
            completedTimeLocalMinutes: 9 * 60,
          ),
        ]),
      );

      return RoutineDetailSupportBloc(
        routineId: 'routine-target',
        routineRepository: routineRepository,
        attentionEngine: attentionEngine,
        attentionRepository: attentionRepository,
        attentionResolutionService: attentionResolutionService,
        nowService: nowService,
      )..add(const RoutineDetailSupportStarted());
    },
    expect: () => [
      const RoutineDetailSupportState(
        status: RoutineDetailSupportStatus.loading,
      ),
      isA<RoutineDetailSupportState>()
          .having((s) => s.status, 'status', RoutineDetailSupportStatus.ready)
          .having((s) => s.weeklyAdherence.length, 'series length', 8)
          .having((s) => s.weeklyAdherence.last, 'current week adherence', 100),
    ],
  );
}
