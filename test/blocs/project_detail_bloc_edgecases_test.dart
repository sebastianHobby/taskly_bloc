import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  late MockProjectRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(ProjectTableCompanion(id: const Value('f')));
  });

  setUp(() {
    mockRepository = MockProjectRepository();
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'delete emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.deleteProject(any()),
      ).thenThrow(Exception('oh no'));
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(const ProjectDetailEvent.delete(id: 'p1')),
    expect: () => <dynamic>[
      isA<ProjectDetailOperationFailure>(),
    ],
  );
}
