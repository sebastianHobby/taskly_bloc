import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import 'package:taskly_domain/taskly_domain.dart';
class MockAllocationOrchestrator extends Mock
    implements AllocationOrchestrator {}

class MockTemporalTriggerService extends Mock
    implements TemporalTriggerService {}

void main() {
  test(
    'does not refresh when allocation is not eligible',
    () async {
      final orchestrator = MockAllocationOrchestrator();
      final temporal = MockTemporalTriggerService();

      final trigger =
          BehaviorSubject<(List<Task>, List<Project>, AllocationConfig)>.seeded(
            (
              const <Task>[],
              const <Project>[],
              const AllocationConfig(
                hasSelectedFocusMode: false,
                dailyLimit: 10,
              ),
            ),
          );
      addTearDown(trigger.close);

      when(orchestrator.combineStreams).thenAnswer(
        (_) => trigger.stream,
      );

      when(() => temporal.events).thenAnswer((_) => const Stream.empty());

      // If refresh runs, it would call watchAllocation().first.
      when(
        orchestrator.watchAllocation,
      ).thenAnswer((_) => const Stream.empty());

      final service = AllocationSnapshotCoordinator(
        allocationOrchestrator: orchestrator,
        temporalTriggerService: temporal,
        debounceWindow: const Duration(milliseconds: 1),
      );

      service.start();
      trigger.add((
        const <Task>[],
        const <Project>[],
        const AllocationConfig(hasSelectedFocusMode: false, dailyLimit: 10),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 5));

      verifyNever(orchestrator.watchAllocation);
      await service.dispose();
    },
  );

  test(
    'refreshes when allocation is eligible',
    () async {
      final orchestrator = MockAllocationOrchestrator();
      final temporal = MockTemporalTriggerService();

      final now = DateTime.utc(2026, 1, 1);
      final task = Task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        name: 't1',
        completed: false,
      );

      final trigger =
          BehaviorSubject<(List<Task>, List<Project>, AllocationConfig)>.seeded(
            (
              <Task>[task],
              const <Project>[],
              const AllocationConfig(hasSelectedFocusMode: true, dailyLimit: 3),
            ),
          );
      addTearDown(trigger.close);

      when(orchestrator.combineStreams).thenAnswer(
        (_) => trigger.stream,
      );

      when(() => temporal.events).thenAnswer((_) => const Stream.empty());

      when(orchestrator.watchAllocation).thenAnswer(
        (_) => Stream.value(
          const AllocationResult(
            allocatedTasks: [],
            reasoning: AllocationReasoning(
              strategyUsed: 'test',
              categoryAllocations: {},
              categoryWeights: {},
              explanation: 'test',
            ),
            excludedTasks: [],
          ),
        ),
      );

      final service = AllocationSnapshotCoordinator(
        allocationOrchestrator: orchestrator,
        temporalTriggerService: temporal,
        debounceWindow: const Duration(milliseconds: 1),
      );

      service.start();
      trigger.add((
        <Task>[task],
        const <Project>[],
        const AllocationConfig(hasSelectedFocusMode: true, dailyLimit: 3),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 5));

      verify(orchestrator.watchAllocation).called(1);
      await service.dispose();
    },
  );
}
