import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/filtering/filtering.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/tasks/services/today_badge_service.dart';

import '../../../../mocks/repository_mocks.dart';

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

  group('TodayBadgeService', () {
    test('watchIncompleteCount returns 0 when no tasks', () async {
      when(
        () => mockRepository.watchCount(any()),
      ).thenAnswer((_) => Stream.value(0));

      final count = await service.watchIncompleteCount().first;

      expect(count, 0);
      verify(() => mockRepository.watchCount(any())).called(1);
    });

    test('watchIncompleteCount returns count from settingsRepo', () async {
      when(
        () => mockRepository.watchCount(any()),
      ).thenAnswer((_) => Stream.value(5));

      final count = await service.watchIncompleteCount().first;

      expect(count, 5);
    });

    test('watchIncompleteCount passes TaskQuery.today to settingsRepo', () async {
      when(
        () => mockRepository.watchCount(any()),
      ).thenAnswer((_) => Stream.value(0));

      await service.watchIncompleteCount().first;

      final captured =
          verify(() => mockRepository.watchCount(captureAny())).captured.single
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
        () => mockRepository.watchCount(any()),
      ).thenAnswer((_) => Stream.value(0));

      await customService.watchIncompleteCount().first;

      final captured =
          verify(() => mockRepository.watchCount(captureAny())).captured.single
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

    test('stream updates when settingsRepo emits new data', () async {
      final controller = Stream.fromIterable([1, 2, 3]);

      when(
        () => mockRepository.watchCount(any()),
      ).thenAnswer((_) => controller);

      final counts = await service.watchIncompleteCount().toList();

      expect(counts, [1, 2, 3]);
    });
  });
}
