import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/repositories/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

void main() {
  late MockProjectRepository mockRepository;

  setUp(() {
    mockRepository = MockProjectRepository();
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'delete emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.delete(any()),
      ).thenThrow(Exception('oh no'));
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(const ProjectDetailEvent.delete(id: 'p1')),
    expect: () => <dynamic>[
      isA<ProjectDetailOperationFailure>(),
    ],
  );
}
