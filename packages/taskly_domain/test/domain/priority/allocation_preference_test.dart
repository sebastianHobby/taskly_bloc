@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/priority/model/allocation_preference.dart';

void main() {
  testSafe('AllocationPreference defaults are applied', () async {
    final pref = AllocationPreference(
      id: 'a1',
      userId: 'u1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    expect(pref.strategyType, AllocationStrategyType.proportional);
    expect(pref.urgencyInfluence, 0.4);
    expect(pref.minimumTasksPerCategory, 1);
    expect(pref.topNCategories, 3);
    expect(pref.dailyTaskLimit, 10);
    expect(pref.showExcludedUrgentWarning, isTrue);
    expect(pref.urgencyThresholdDays, 3);
  });

  testSafe('AllocationPreference JSON roundtrip', () async {
    final pref = AllocationPreference(
      id: 'a1',
      userId: 'u1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      strategyType: AllocationStrategyType.roundRobin,
    );

    final decoded = AllocationPreference.fromJson(pref.toJson());
    expect(decoded, equals(pref));
  });
}
