import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as drift;
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';

class LabelRepository implements LabelRepositoryContract {
  LabelRepository({
    required this.driftDb,
    required this.idGenerator,
  });
  final drift.AppDatabase driftDb;
  final IdGenerator idGenerator;

  Stream<List<drift.LabelTableData>> get _labelStream =>
      (driftDb.select(
            driftDb.labelTable,
          )..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
          .watch();

  Stream<List<drift.LabelTableData>> _labelStreamByType(LabelType type) {
    return (driftDb.select(driftDb.labelTable)
          ..where((l) => l.type.equals(type.name))
          ..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
        .watch();
  }

  Future<List<drift.LabelTableData>> get _labelList =>
      (driftDb.select(
            driftDb.labelTable,
          )..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
          .get();

  Future<List<drift.LabelTableData>> _labelListByType(LabelType type) {
    return (driftDb.select(driftDb.labelTable)
          ..where((l) => l.type.equals(type.name))
          ..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
        .get();
  }

  Future<drift.LabelTableData?> _getLabelById(String id) {
    return (driftDb.select(
      driftDb.labelTable,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  // Domain-aware read methods
  @override
  Stream<List<Label>> watchAll() =>
      _labelStream.map((rows) => rows.map(labelFromTable).toList());

  @override
  Future<List<Label>> getAll() async =>
      (await _labelList).map(labelFromTable).toList();

  @override
  Stream<List<Label>> watchByType(LabelType type) =>
      _labelStreamByType(type).map((rows) => rows.map(labelFromTable).toList());

  @override
  Future<List<Label>> getAllByType(
    LabelType type,
  ) async => (await _labelListByType(type)).map(labelFromTable).toList();

  @override
  Stream<Label?> watchById(String id) =>
      (driftDb.select(driftDb.labelTable)..where((l) => l.id.equals(id)))
          .watch()
          .map((rows) => rows.isEmpty ? null : labelFromTable(rows.first));

  @override
  Future<Label?> getById(String id) async {
    final data = await _getLabelById(id);
    return data == null ? null : labelFromTable(data);
  }

  @override
  Future<Label?> getSystemLabel(SystemLabelType type) async {
    final result =
        await (driftDb.select(driftDb.labelTable)
              ..where((l) => l.isSystemLabel.equals(true))
              ..where((l) => l.systemLabelType.equals(type.name)))
            .getSingleOrNull();
    return result == null ? null : labelFromTable(result);
  }

  @override
  Future<Label> getOrCreateSystemLabel(SystemLabelType type) async {
    final existing = await getSystemLabel(type);
    if (existing != null) return existing;

    // Create system label
    // Note: user_id is set automatically by Supabase/PowerSync based on session
    final now = DateTime.now();
    final labelData = switch (type) {
      SystemLabelType.pinned => (
        name: 'Pinned',
        color: '#9C27B0', // Purple
        icon: 'push_pin',
      ),
    };

    // System labels use v5 ID with their system name
    final id = idGenerator.labelId(
      name: labelData.name,
      type: LabelType.label,
    );
    await driftDb
        .into(driftDb.labelTable)
        .insert(
          drift.LabelTableCompanion(
            id: Value(id),
            name: Value(labelData.name),
            color: Value(labelData.color),
            type: Value(drift.LabelType.label),
            iconName: Value(labelData.icon),
            isSystemLabel: Value(true),
            systemLabelType: Value(type.name),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final created = await _getLabelById(id);
    return labelFromTable(created!);
  }

  Future<void> _updateLabel(drift.LabelTableCompanion updateCompanion) async {
    await driftDb.update(driftDb.labelTable).replace(updateCompanion);
  }

  Future<int> _deleteLabel(drift.LabelTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.labelTable).delete(deleteCompanion);
  }

  Future<int> _createLabel(drift.LabelTableCompanion createCompanion) {
    return driftDb.into(driftDb.labelTable).insert(createCompanion);
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    required LabelType type,
    String? iconName,
  }) async {
    talker.debug('[LabelRepository] create: name="$name", type=${type.name}');
    final now = DateTime.now();
    final driftLabel = switch (type) {
      LabelType.label => drift.LabelType.label,
      LabelType.value => drift.LabelType.value,
    };

    // Generate deterministic v5 ID
    final id = idGenerator.labelId(name: name, type: type);

    await _createLabel(
      drift.LabelTableCompanion(
        id: Value(id),
        name: Value(name),
        color: Value(color),
        type: Value(driftLabel),
        iconName: Value(iconName),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    required LabelType type,
    String? iconName,
  }) async {
    talker.debug('[LabelRepository] update: id=$id, name="$name"');
    final existing = await _getLabelById(id);
    if (existing == null) {
      talker.warning('[LabelRepository] update failed: label not found id=$id');
      throw RepositoryNotFoundException('No label found to update');
    }

    final now = DateTime.now();
    await _updateLabel(
      drift.LabelTableCompanion(
        id: Value(id),
        name: Value(name),
        color: Value(color),
        type: Value(drift.LabelType.values.byName(type.name)),
        iconName: Value(iconName),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    talker.debug('[LabelRepository] delete: id=$id');
    await _deleteLabel(drift.LabelTableCompanion(id: Value(id)));
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    talker.debug('[LabelRepository] updateLastReviewedAt: id=$id');
    final existing = await _getLabelById(id);
    if (existing == null) {
      talker.warning(
        '[LabelRepository] updateLastReviewedAt failed: label not found id=$id',
      );
      throw RepositoryNotFoundException('No label found to update');
    }

    await (driftDb.update(
      driftDb.labelTable,
    )..where((l) => l.id.equals(id))).write(
      drift.LabelTableCompanion(
        lastReviewedAt: Value(reviewedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> addLabelToTask({
    required String taskId,
    required String labelId,
  }) async {
    // Check if label association already exists
    final existing =
        await (driftDb.select(driftDb.taskLabelsTable)..where(
              (tl) => tl.taskId.equals(taskId) & tl.labelId.equals(labelId),
            ))
            .getSingleOrNull();

    if (existing != null) return; // Already exists

    // Generate deterministic v5 ID for junction
    final junctionId = idGenerator.taskLabelId(
      taskId: taskId,
      labelId: labelId,
    );

    // Add new label association
    await driftDb
        .into(driftDb.taskLabelsTable)
        .insert(
          drift.TaskLabelsTableCompanion(
            id: Value(junctionId),
            taskId: Value(taskId),
            labelId: Value(labelId),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> removeLabelFromTask({
    required String taskId,
    required String labelId,
  }) async {
    await (driftDb.delete(
          driftDb.taskLabelsTable,
        )..where((tl) => tl.taskId.equals(taskId) & tl.labelId.equals(labelId)))
        .go();
  }
}
