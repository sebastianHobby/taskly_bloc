import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(TaskTableCompanion(id: const Value('f')));
  });

  setUp(() {
    mockRepository = MockTaskRepository();
  });

  blocTest<TaskDetailBloc, TaskDetailState>(
    'create emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.createTask(any()),
      ).thenThrow(Exception('oh no'));
    },
    build: () => TaskDetailBloc(taskRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const TaskDetailEvent.create(name: 'n', description: null)),
    expect: () => <dynamic>[
      isA<TaskDetailOperationFailure>(),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'update emits operationFailure when repository throws',
    setUp: () {
      when(() => mockRepository.updateTask(any())).thenThrow(Exception('bad'));
    },
    build: () => TaskDetailBloc(taskRepository: mockRepository),
    act: (bloc) => bloc.add(
      const TaskDetailEvent.update(
        id: 't1',
        name: 'n',
        description: null,
        completed: false,
      ),
    ),
    expect: () => <dynamic>[
      isA<TaskDetailOperationFailure>(),
    ],
  );
}
