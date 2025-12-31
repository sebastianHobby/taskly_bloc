// DOCUMENTATION FILE - NOT MEANT TO BE RUN
// This file provides examples of how to use the testing infrastructure.
// To run these examples, copy them into a real test file with actual blocs.

// ignore_for_file: unused_import

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import '../helpers/fallback_values.dart';

// Commented out imports that reference files with compilation issues
// import '../fixtures/test_data.dart';
// import '../helpers/base_bloc_test.dart';
// import '../helpers/bloc_test_helpers.dart';
// import '../helpers/custom_matchers.dart';
// import '../mocks/repository_mocks.dart';

/// Example test file demonstrating the new testing infrastructure.
///
/// This shows how to use:
/// - BaseBlocTest for automatic setup/teardown
/// - BlocTestContext for managing multiple mocks
/// - Custom matchers for readable assertions
/// - TestData for consistent test objects
/// - Stream testing helpers

void main() {
  setUpAll(registerAllFallbackValues);

  // This file contains example code only - not meant to be executed
  test('placeholder', () {
    expect(true, isTrue);
  });
}

/*
  Example documentation below - copy into actual test files as needed

// ═══════════════════════════════════════════════════════════════════════════
// Example 1: Using BaseBlocTest (Recommended for single-bloc tests)
// ═══════════════════════════════════════════════════════════════════════════

class MyBlocTest extends BaseBlocTest<MyBloc, MyState> {
  late MockTaskRepositoryContract mockTaskRepo;

  @override
  void setUp() {
    mockTaskRepo = MockTaskRepositoryContract();
    // Stub default behaviors
    when(() => mockTaskRepo.getAll()).thenAnswer((_) async => []);
    super.setUp(); // Creates bloc via createBloc()
  }

  @override
  MyBloc createBloc() {
    return MyBloc(taskRepository: mockTaskRepo);
  }
}

// void main() {
//   group('MyBloc using BaseBlocTest', () {
//     final test = MyBlocTest();
//
//     setUp(test.setUp);
//     tearDown(test.tearDown);
//
//     test('loads tasks successfully', () async {
      // Arrange
      final tasks = [TestData.task(name: 'Task 1')];
      when(() => test.mockTaskRepo.getAll()).thenAnswer((_) async => tasks);

      // Act
      test.bloc.add(const ExampleLoad());

      // Assert using custom matchers
      final state = await test.waitForState((s) => s is ExampleSuccess);
      expect(state, isSuccessState());
      expect((state as ExampleSuccess).tasks, hasLength(1));
      expect(state.tasks.first.name, 'Task 1');
    });

    test('handles error gracefully', () async {
      // Arrange
      when(
        () => test.mockTaskRepo.getAll(),
      ).thenThrow(Exception('Network error'));

      // Act
      test.bloc.add(const ExampleLoad());

      // Assert using custom matchers
      final state = await test.waitForState((s) => s is ExampleError);
      expect(state, isErrorState(errorMessage: 'Network error'));
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Example 2: Using BlocTestContext (Recommended for multi-repo tests)
  // ═════════════════════════════════════════════════════════════════════════

  group('ExampleBloc using BlocTestContext', () {
    late BlocTestContext ctx;
    late ExampleBloc bloc;

    setUp(() {
      ctx = BlocTestContext();
      ctx.stubAllEmpty(); // Stub all repositories with empty responses
      bloc = ExampleBloc(
        taskRepository: ctx.taskRepo,
        projectRepository: ctx.projectRepo,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('creates task successfully', () async {
      // Arrange
      ctx.stubTaskCreateSuccess(); // Use helper method

      // Act
      bloc.add(ExampleCreate(TestData.task(name: 'New Task')));

      // Assert
      await expectStreamEmits(
        bloc.stream,
        isSuccessState(),
        timeout: const Duration(seconds: 2),
      );

      verify(() => ctx.taskRepo.create(name: 'New Task')).called(1);
    });

    test('handles validation error', () async {
      // Arrange - Stub to throw on create
      when(
        () => ctx.taskRepo.create(name: any(named: 'name')),
      ).thenThrow(Exception('Name required'));

      // Act
      bloc.add(ExampleCreate(TestData.task(name: '')));

      // Assert using stream helper
      await expectStreamEmits(
        bloc.stream,
        isErrorState(),
      );
    });

    test('loads tasks and projects together', () async {
      // Arrange
      ctx.stubTasksReturn([TestData.task()]);
      ctx.stubProjectsReturn([TestData.project()]);

      // Act
      bloc.add(const ExampleLoadAll());

      // Assert multiple emissions
      await expectStreamEmitsInOrder(
        bloc.stream,
        [
          isLoadingState(),
          isSuccessState(),
        ],
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Example 3: Using bloc_test package with new matchers
  // ═════════════════════════════════════════════════════════════════════════

  group('ExampleBloc using bloc_test', () {
    late MockTaskRepositoryContract mockTaskRepo;

    setUp(() {
      mockTaskRepo = MockTaskRepositoryContract();
    });

    blocTest<ExampleBloc, ExampleState>(
      'emits [loading, success] when tasks load',
      build: () {
        when(() => mockTaskRepo.getAll()).thenAnswer(
          (_) async => [TestData.task()],
        );
        return ExampleBloc(taskRepository: mockTaskRepo);
      },
      act: (bloc) => bloc.add(const ExampleLoad()),
      expect: () => [
        isLoadingState(), // Custom matcher!
        isSuccessState(), // Custom matcher!
      ],
      verify: (_) {
        verify(() => mockTaskRepo.getAll()).called(1);
      },
    );

    blocTest<ExampleBloc, ExampleState>(
      'filters completed tasks',
      build: () {
        final tasks = [
          TestData.task(name: 'Task 1', completed: true),
          TestData.task(name: 'Task 2', completed: false),
        ];
        when(() => mockTaskRepo.getAll()).thenAnswer((_) async => tasks);
        return ExampleBloc(taskRepository: mockTaskRepo);
      },
      act: (bloc) => bloc.add(const ExampleLoadCompleted()),
      expect: () => [
        isLoadingState(),
        // Using predicate matcher with helper
        predicate<ExampleSuccess>(
          (state) => state.tasks.every((t) => t.completed),
        ),
      ],
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Example 4: Testing streams with helpers
  // ═════════════════════════════════════════════════════════════════════════

  group('Stream testing examples', () {
    late MockTaskRepositoryContract mockTaskRepo;
    late ExampleBloc bloc;

    setUp(() {
      mockTaskRepo = MockTaskRepositoryContract();
      bloc = ExampleBloc(taskRepository: mockTaskRepo);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('emits states in correct order', () async {
      // Arrange
      when(() => mockTaskRepo.getAll()).thenAnswer(
        (_) async => [TestData.task()],
      );

      // Act
      bloc.add(const ExampleLoad());

      // Assert using stream helper
      await expectStreamEmitsInOrder(
        bloc.stream,
        [
          isLoadingState(),
          isSuccessState(),
        ],
      );
    });

    test('stream is initially empty', () async {
      // Assert stream has no emissions
      await expectStreamEmpty(
        bloc.stream,
        timeout: const Duration(milliseconds: 100),
      );
    });

    test('waits for specific state', () async {
      // Arrange
      when(() => mockTaskRepo.getAll()).thenAnswer(
        (_) async => [TestData.task()],
      );

      // Act
      bloc.add(const ExampleLoad());

      // Wait for specific state
      final state = await waitForStreamMatch(
        bloc.stream,
        (s) => s is ExampleSuccess,
      );

      expect(state, isNotNull);
      expect(state, isSuccessState());
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Example 5: Using TestData effectively
  // ═════════════════════════════════════════════════════════════════════════

  group('TestData examples', () {
    test('creates task with defaults', () {
      final task = TestData.task();
      expect(task.name, isNotEmptyString());
      expect(task.completed, isFalse);
    });

    test('overrides specific properties', () {
      final task = TestData.task(
        name: 'Important Task',
        completed: true,
        deadlineDate: DateTime(2025, 12, 31),
      );

      expect(task.name, 'Important Task');
      expect(task.completed, isTrue);
      expect(task.deadlineDate, isNotNull);
    });

    test('creates related objects', () {
      final project = TestData.project(name: 'My Project');
      final task = TestData.task(
        name: 'Project Task',
        projectId: project.id,
      );

      expect(task.projectId, project.id);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // Example 6: Custom matcher examples
  // ═════════════════════════════════════════════════════════════════════════

  group('Custom matcher examples', () {
    test('date matchers', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      expect(today, isToday());
      expect(yesterday, isInThePast());
      expect(tomorrow, isInTheFuture());
    });

    test('collection matchers', () {
      final tasks = [
        TestData.task(name: 'Task 1'),
        TestData.task(name: 'Task 2'),
        TestData.task(name: 'Important', completed: true),
      ];

      expect(tasks, hasLength(3));
      expect(tasks, containsWhere((t) => t.name.contains('Important')));
      expect(tasks, containsWhere((t) => t.completed));
    });

    test('string matchers', () {
      final task = TestData.task(name: 'Valid Task');

      expect(task.name, isNotEmptyString());
      expect(task.description, isNullOrEmpty());
    });

    test('exception matchers', () {
      void throwsError() {
        throw Exception('Something went wrong');
      }

      expect(
        throwsError,
        throwsExceptionWith('went wrong'),
      );
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Dummy classes for example (would be actual implementation in real code)
// ═══════════════════════════════════════════════════════════════════════════

class ExampleBloc extends Bloc<ExampleEvent, ExampleState> {
  ExampleBloc({
    required this.taskRepository,
    this.projectRepository,
  }) : super(const ExampleInitial());

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract? projectRepository;
}

abstract class ExampleEvent {
  const ExampleEvent();
}

class ExampleLoad extends ExampleEvent {
  const ExampleLoad();
}

class ExampleLoadAll extends ExampleEvent {
  const ExampleLoadAll();
}

class ExampleLoadCompleted extends ExampleEvent {
  const ExampleLoadCompleted();
}

class ExampleCreate extends ExampleEvent {
  const ExampleCreate(this.task);
  final Task task;
}

// End of examples - All code above is documentation only
*/
