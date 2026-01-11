import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/infrastructure/drift/converters/json_converters.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_step.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_step_state.dart';

/// Workflow status for runtime instances
enum WorkflowInstanceStatus { inProgress, completed, abandoned }

/// Type converter for `List<WorkflowStep>` JSON serialization
class WorkflowStepsConverter
    extends TypeConverter<List<WorkflowStep>, String?> {
  const WorkflowStepsConverter();

  @override
  List<WorkflowStep> fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) return [];
    final list = jsonDecode(fromDb) as List<dynamic>;
    return list
        .map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  String? toSql(List<WorkflowStep> value) {
    if (value.isEmpty) return null;
    return jsonEncode(value.map((e) => e.toJson()).toList());
  }
}

/// Type converter for `List<WorkflowStepState>` JSON serialization
class WorkflowStepStatesConverter
    extends TypeConverter<List<WorkflowStepState>, String?> {
  const WorkflowStepStatesConverter();

  @override
  List<WorkflowStepState> fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) return [];
    final list = jsonDecode(fromDb) as List<dynamic>;
    return list
        .map((e) => WorkflowStepState.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  String? toSql(List<WorkflowStepState> value) {
    if (value.isEmpty) return null;
    return jsonEncode(value.map((e) => e.toJson()).toList());
  }
}

const workflowStepsConverter = WorkflowStepsConverter();
const workflowStepStatesConverter = WorkflowStepStatesConverter();

/// Workflow definition templates
@DataClassName('WorkflowDefinitionEntity')
class WorkflowDefinitions extends Table {
  @override
  String get tableName => 'workflow_definitions';

  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get workflowKey => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get iconName => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get steps => text().map(workflowStepsConverter)();
  TextColumn get triggerConfig =>
      text().map(triggerConfigConverter).nullable()();
  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, workflowKey},
  ];
}

/// Runtime workflow instances
@DataClassName('WorkflowEntity')
class Workflows extends Table {
  @override
  String get tableName => 'workflows';

  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get workflowDefinitionId => text()();
  TextColumn get status => textEnum<WorkflowInstanceStatus>().withDefault(
    const Constant('inProgress'),
  )();
  DateTimeColumn get startedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get currentStepIndex => integer().withDefault(const Constant(0))();
  TextColumn get stepStates => text().map(workflowStepStatesConverter)();
  TextColumn get sessionNotes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
