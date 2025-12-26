import 'package:drift/drift.dart';

@DataClassName('ReviewEntity')
class Reviews extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get query => text()(); // JSON-encoded ReviewQuery
  TextColumn get rrule => text()();
  DateTimeColumn get nextDueDate => dateTime()();
  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReviewCompletionHistoryEntity')
class ReviewCompletionHistory extends Table {
  TextColumn get id => text()();
  TextColumn get reviewId => text().customConstraint(
    'NOT NULL REFERENCES reviews(id) ON DELETE CASCADE',
  )();
  DateTimeColumn get completedAt => dateTime().clientDefault(DateTime.now)();
  IntColumn get entitiesReviewed => integer()();
  IntColumn get actionsCount => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReviewEntityHistoryEntity')
class ReviewEntityHistory extends Table {
  TextColumn get id => text()();
  TextColumn get reviewId => text().customConstraint(
    'NOT NULL REFERENCES reviews(id) ON DELETE CASCADE',
  )();
  TextColumn get completionId => text().customConstraint(
    'NOT NULL REFERENCES review_completion_history(id) ON DELETE CASCADE',
  )();
  TextColumn get entityId => text()();
  TextColumn get entityType => text()();
  TextColumn get actionType => text()();
  TextColumn get updateData => text().nullable()(); // JSON-encoded
  TextColumn get notes => text().nullable()();
  DateTimeColumn get actionedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
