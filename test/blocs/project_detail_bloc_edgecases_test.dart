import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

import '../mocks/repository_mocks.dart';

void main() {
  late MockProjectRepository mockRepository;
  late MockLabelRepository mockLabelRepository;

  setUp(() {
    mockRepository = MockProjectRepository();
    mockLabelRepository = MockLabelRepository();
    when(() => mockLabelRepository.getAll()).thenAnswer((_) async => <Label>[]);
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'delete emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.delete(any()),
      ).thenThrow(Exception('oh no'));
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(const ProjectDetailEvent.delete(id: 'p1')),
    expect: () => <dynamic>[
      isA<ProjectDetailOperationFailure>(),
    ],
  );
}
