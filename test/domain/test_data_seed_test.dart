@Tags(['unit'])
library;

import '../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('TestData builders are deterministic by default', () async {
    final task = TestData.task();

    expect(task.createdAt, TestConstants.referenceDate);
    expect(task.updatedAt, TestConstants.referenceDate);

    // Example: time-aware matchers require an explicit reference "now".
    expect(task.createdAt, isToday(now: TestConstants.referenceDate));
  });

  testSafe('TestData builders respect provided now', () async {
    final now = DateTime(2025, 2, 1, 9, 30);

    final task = TestData.task(now: now);
    final project = TestData.project(now: now);

    expect(task.createdAt, now);
    expect(project.updatedAt, now);

    expect(task.createdAt, isInThePast(now: now.add(const Duration(days: 1))));
    expect(
      project.updatedAt,
      isInTheFuture(now: now.subtract(const Duration(days: 1))),
    );
  });
}
