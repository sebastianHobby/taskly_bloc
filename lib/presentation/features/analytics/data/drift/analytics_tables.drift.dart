import 'dart:convert';
import 'package:drift/drift.dart';

class AnalyticsJsonTypeConverter
    extends TypeConverter<Map<String, dynamic>, String> {
  const AnalyticsJsonTypeConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    try {
      return jsonDecode(fromDb) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}

@DataClassName('AnalyticsSnapshotEntity')
class AnalyticsSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get entityType => text().withLength(min: 1, max: 50)();
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get snapshotDate => dateTime()();
  TextColumn get metrics => text()
      .map(const AnalyticsJsonTypeConverter())
      .clientDefault(() => '{}')();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, entityType, entityId, snapshotDate},
  ];
}

@DataClassName('AnalyticsCorrelationEntity')
class AnalyticsCorrelations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get correlationType => text().withLength(min: 1, max: 50)();
  TextColumn get sourceType => text().withLength(min: 1, max: 50)();
  TextColumn get sourceId => text()();
  TextColumn get targetType => text().withLength(min: 1, max: 50)();
  TextColumn get targetId => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  RealColumn get coefficient => real().nullable()();
  IntColumn get sampleSize => integer()();
  TextColumn get strength => text().withLength(min: 1, max: 50)();
  TextColumn get insight => text().nullable()();
  RealColumn get valueWithSource => real().nullable()();
  RealColumn get valueWithoutSource => real().nullable()();
  DateTimeColumn get computedAt => dateTime().clientDefault(DateTime.now)();
  // Enhanced analytics fields
  TextColumn get statisticalSignificance =>
      text().map(const AnalyticsJsonTypeConverter()).nullable()();
  TextColumn get performanceMetrics =>
      text().map(const AnalyticsJsonTypeConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, correlationType, sourceId, targetId, periodStart},
  ];
}

@DataClassName('AnalyticsInsightEntity')
class AnalyticsInsights extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get insightType => text().withLength(min: 1, max: 50)();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get metadata => text()
      .map(const AnalyticsJsonTypeConverter())
      .clientDefault(() => '{}')();
  RealColumn get score => real().nullable()();
  RealColumn get confidence => real().nullable()();
  BoolColumn get isPositive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get generatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
