import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';

import '../helpers/base_repository_helpers.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/repository_mocks.dart';

void main() {
  group('ProjectDetailBloc (integration)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late MockOccurrenceStreamExpanderContract occurrenceExpander;
    late MockOccurrenceWriteHelperContract occurrenceWriteHelper;

    late ValueRepository valueRepository;
    late ProjectRepository projectRepository;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();
      occurrenceExpander = MockOccurrenceStreamExpanderContract();
      occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

      valueRepository = ValueRepository(
        driftDb: ctx.db,
        idGenerator: idGenerator,
      );
      projectRepository = ProjectRepository(
        driftDb: ctx.db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
    });

    tearDown(() async {
      await ctx.dispose();
    });

    blocTest<ProjectDetailBloc, ProjectDetailState>(
      'loadById loads project plus available values from Drift',
      tags: 'integration',
      setUp: () async {
        await valueRepository.create(
          name: 'Health',
          color: '#00FF00',
          priority: ValuePriority.medium,
        );

        await projectRepository.create(
          name: 'My Project',
          valueIds: const ['value-health'],
        );
      },
      build: () => ProjectDetailBloc(
        projectRepository: projectRepository,
        valueRepository: valueRepository,
      ),
      act: (bloc) =>
          bloc.add(const ProjectDetailEvent.loadById(projectId: 'project-0')),
      expect: () => [
        const ProjectDetailLoadInProgress(),
        isA<ProjectDetailLoadSuccess>()
            .having((s) => s.project.id, 'project.id', 'project-0')
            .having((s) => s.project.name, 'project.name', 'My Project')
            .having(
              (s) => s.project.values.map((v) => v.id).toList(),
              'project.valueIds',
              ['value-health'],
            )
            .having((s) => s.availableValues.length, 'values', 1),
      ],
    );
  });
}
