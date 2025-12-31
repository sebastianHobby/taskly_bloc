import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;

/// Ranking types for priority system
enum RankingType { value, project, context, goal }

/// Entity types for ranked items
enum RankedEntityType { label, project }

/// Allocation strategy types
enum AllocationStrategy {
  proportional,
  urgencyWeighted,
  roundRobin,
  minimumViable,
  dynamic,
  topCategories,
}

/// User's explicit priority rankings for values, projects, contexts, and goals
@DataClassName('PriorityRankingEntity')
class PriorityRankings extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get rankingType => textEnum<RankingType>()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual ranked items within a priority ranking with weights
@DataClassName('RankedItemEntity')
class RankedItems extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get rankingId => text().customConstraint(
    'NOT NULL REFERENCES priority_rankings(id) ON DELETE CASCADE',
  )();
  TextColumn get entityId => text()(); // References label or project
  TextColumn get entityType => textEnum<RankedEntityType>()();
  IntColumn get weight => integer()(); // 1-10
  IntColumn get sortOrder => integer()(); // Display order
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User's preferred allocation strategy and parameters
@DataClassName('AllocationPreferenceEntity')
class AllocationPreferences extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get strategyType => textEnum<AllocationStrategy>().withDefault(
    const Constant('proportional'),
  )();
  RealColumn get urgencyInfluence => real().withDefault(
    const Constant(0.4),
  )(); // For urgency_weighted strategy
  IntColumn get minimumTasksPerCategory =>
      integer().withDefault(const Constant(1))(); // For minimum_viable strategy
  IntColumn get topNCategories =>
      integer().withDefault(const Constant(3))(); // For top_categories strategy
  IntColumn get dailyTaskLimit => integer().withDefault(
    const Constant(10),
  )(); // Maximum focus tasks per day
  IntColumn get showExcludedUrgentWarning => integer().withDefault(
    const Constant(1),
  )(); // Show urgent task warnings (bool as int)
  IntColumn get urgencyThresholdDays => integer().withDefault(
    const Constant(3),
  )(); // Days before deadline = urgent
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
