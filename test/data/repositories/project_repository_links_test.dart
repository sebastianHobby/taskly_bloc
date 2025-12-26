import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide LabelType;
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../../helpers/test_db.dart';
import '../../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    projectRepository = ProjectRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('update does not rewrite link rows when ids unchanged', () async {
    await labelRepository.create(
      name: 'L1',
      color: '#000000',
      type: LabelType.label,
    );
    await labelRepository.create(
      name: 'L2',
      color: '#000000',
      type: LabelType.label,
    );
    final label1Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L1')
        .id;
    final label2Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L2')
        .id;

    await projectRepository.create(
      name: 'P',
      labelIds: <String>[label1Id, label2Id],
    );

    final projectId = (await projectRepository.getAll()).single.id;

    final beforeLabelLinks = await (db.select(
      db.projectLabelsTable,
    )..where((t) => t.projectId.equals(projectId))).get();

    await projectRepository.update(
      id: projectId,
      name: 'P',
      completed: false,
      labelIds: <String>[label1Id, label2Id],
    );
    final afterLabelLinks = await (db.select(
      db.projectLabelsTable,
    )..where((t) => t.projectId.equals(projectId))).get();
    expect(
      afterLabelLinks.map((r) => r.id).toSet(),
      beforeLabelLinks.map((r) => r.id).toSet(),
    );
  });
}
