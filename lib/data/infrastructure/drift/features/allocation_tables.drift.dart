import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/infrastructure/drift/converters/date_only_string_converter.dart';

/// Daily allocation snapshot (allocated membership only).
class AllocationSnapshots extends Table {
  @override
  String get tableName => 'allocation_snapshots';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  /// Owning user. Filtered by Supabase RLS + PowerSync bucket rules.
  TextColumn get userId => text().nullable().named('user_id')();

  /// UTC day bucket for this snapshot.
  ///
  /// Stored as a date-only text value for cross-platform stability.
  TextColumn get dayUtc =>
      text().map(dateOnlyStringConverter).named('day_utc')();

  /// Monotonically increasing version for [dayUtc].
  IntColumn get version => integer().clientDefault(() => 1).named('version')();

  /// Daily cap in effect when the day's allocation was first generated.
  IntColumn get capAtGeneration => integer().named('cap_at_generation')();

  /// Eligible candidate pool size when the day's allocation was first generated.
  IntColumn get candidatePoolCountAtGeneration =>
      integer().named('candidate_pool_count_at_generation')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {dayUtc, version},
  ];
}

/// Entries for a given allocation snapshot.
class AllocationSnapshotEntries extends Table {
  @override
  String get tableName => 'allocation_snapshot_entries';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  /// Owning user. Filtered by Supabase RLS + PowerSync bucket rules.
  TextColumn get userId => text().nullable().named('user_id')();

  TextColumn get snapshotId => text()
      .named('snapshot_id')
      .references(AllocationSnapshots, #id, onDelete: KeyAction.cascade)();

  /// Entity type (start with 'task'; add 'project' later).
  TextColumn get entityType => text().named('entity_type')();

  /// Entity id (task id, etc).
  TextColumn get entityId => text().named('entity_id')();

  /// For tasks: owning project id (if any).
  TextColumn get projectId => text().nullable().named('project_id')();

  /// For debugging/analytics: which value category caused inclusion.
  TextColumn get qualifyingValueId =>
      text().nullable().named('qualifying_value_id')();

  /// For tasks: effective primary value id (task primary overrides project).
  TextColumn get effectivePrimaryValueId =>
      text().nullable().named('effective_primary_value_id')();

  /// For debugging/analytics: allocation score that led to selection.
  RealColumn get allocationScore =>
      real().nullable().named('allocation_score')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {snapshotId, entityType, entityId},
  ];
}
