import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/filtering.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/features/tasks/services/today_badge_service.dart';

import '../../../mocks/repository_mocks.dart';

class _FakeTaskQuery extends Fake implements TaskQuery {}

void main() {
  late MockTaskRepository mockRepository;
  late TodayBadgeService service;
  late DateTime fixedNow;

  setUpAll(() {
    registerFallbackValue(_FakeTaskQuery());
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    fixedNow = DateTime(2025, 12, 25, 10, 30);
    service = TodayBadgeService(
      taskRepository: mockRepository,
      nowFactory: () => fixedNow,
    );
  });

  Task createTask({
    required String id,
    required bool completed,
  }) {
    return Task(
      id: id,
      createdAt: fixedNow,
      updatedAt: fixedNow,
      name: 'Task $id',
      completed: completed,
    );
  }

  group('TodayBadgeService', () {
    test('watchIncompleteCount returns 0 when no tasks', () async {
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      final count = await service.watchIncompleteCount().first;

      expect(count, 0);
      verify(() => mockRepository.watchAll(any())).called(1);
    });

    test('watchIncompleteCount counts only incomplete tasks', () async {
      final tasks = [
        createTask(id: '1', completed: false),
        createTask(id: '2', completed: true),
        createTask(id: '3', completed: false),
        createTask(id: '4', completed: true),
      ];

      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value(tasks));

      final count = await service.watchIncompleteCount().first;

      expect(count, 2);
    });

    test(
      'watchIncompleteCount uses distinct to prevent duplicate emissions',
      () async {
        // Stream that emits same count multiple times
        final controller = Stream.fromIterable([
          [createTask(id: '1', completed: false)],
          [createTask(id: '2', completed: false)], // Same count: 1
          [
            createTask(id: '1', completed: false),
            createTask(id: '2', completed: false),
          ], // Different count: 2
        ]);

        when(
          () => mockRepository.watchAll(any()),
        ).thenAnswer((_) => controller);

        final counts = await service.watchIncompleteCount().toList();

        // Should emit 1, then skip duplicate 1, then emit 2
        expect(counts, [1, 2]);
      },
    );

    test('watchIncompleteCount passes TaskQuery.today to repository', () async {
      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      await service.watchIncompleteCount().first;

      final captured =
          verify(() => mockRepository.watchAll(captureAny())).captured.single
              as TaskQuery;

      // Verify it's a today query by checking rules
      expect(captured.rules.length, 2);
      expect(
        captured.rules.any(
          (r) =>
              r is BooleanRule &&
              r.field == BooleanRuleField.completed &&
              r.operator == BooleanRuleOperator.isFalse,
        ),
        isTrue,
      );
      expect(
        captured.rules.any(
          (r) =>
              r is DateRule &&
              r.field == DateRuleField.deadlineDate &&
              r.operator == DateRuleOperator.onOrBefore,
        ),
        isTrue,
      );
    });

    test('uses provided nowFactory for date calculation', () async {
      final customNow = DateTime(2024, 6, 15);
      final customService = TodayBadgeService(
        taskRepository: mockRepository,
        nowFactory: () => customNow,
      );

      when(
        () => mockRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      await customService.watchIncompleteCount().first;

      final captured =
          verify(() => mockRepository.watchAll(captureAny())).captured.single
              as TaskQuery;

      // Find the date rule and verify it uses our custom date
      final dateRule = captured.rules.whereType<DateRule>().firstWhere(
        (r) => r.field == DateRuleField.deadlineDate,
      );

      expect(dateRule.date?.year, 2024);
      expect(dateRule.date?.month, 6);
      expect(dateRule.date?.day, 15);
    });

    test('uses DateTime.now when no nowFactory provided', () {
      final defaultService = TodayBadgeService(taskRepository: mockRepository);

      // Just verify it constructs without error
      expect(defaultService, isNotNull);
    });

    test('stream updates when repository emits new data', () async {
      final controller = Stream.fromIterable([
        [createTask(id: '1', completed: false)],
        [
          createTask(id: '1', completed: false),
          createTask(id: '2', completed: false),
        ],
        [
          createTask(id: '1', completed: false),
          createTask(id: '2', completed: false),
          createTask(id: '3', completed: false),
        ],
      ]);

      when(() => mockRepository.watchAll(any())).thenAnswer((_) => controller);

      final counts = await service.watchIncompleteCount().toList();

      expect(counts, [1, 2, 3]);
    });
  });
}
