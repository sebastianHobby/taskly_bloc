# Test Directory

This directory contains all tests for the Taskly application, organized by test type and feature.

## Directory Structure

```
test/
├── core/               # Tests for core utilities and services
├── data/               # Repository and data layer tests
├── domain/             # Domain models, queries, and business logic tests
├── presentation/       # BLoC and UI tests
├── integration/        # Integration tests with real database
├── diagnosis/          # Debugging and investigation tests
├── helpers/            # Shared test utilities and helpers
├── mocks/              # Mock implementations
└── fixtures/           # Test data builders
```

## Test Types

### Unit Tests
Fast, isolated tests using mocks. Located throughout the directory structure.
- **Run:** `flutter test --tags=unit`
- **Coverage:** Core logic, blocs, repositories, models

### Integration Tests
Tests using real in-memory database. Located in `integration/`.
- **Run:** `flutter test --tags=integration`
- **Coverage:** End-to-end CRUD operations, cross-feature workflows

### Widget Tests
Flutter widget tests. Located in `presentation/features/*/widgets/`.
- **Run:** `flutter test --tags=widget`
- **Coverage:** UI components, form validation, user interactions

### Diagnosis Tests
Investigation and debugging tests. Located in `diagnosis/`.
- **Run:** `flutter test test/diagnosis/`
- **Purpose:** Reproduce bugs, test specific scenarios

## Running Tests

### All Tests
```bash
flutter test
```

### With Coverage
```bash
flutter test --coverage
```

### Fast Tests Only (exclude integration/slow)
```bash
flutter test --tags=fast
# or
flutter test --exclude-tags=integration,slow
```

### Specific Feature
```bash
flutter test test/presentation/features/tasks/
flutter test test/domain/models/
```

### Single File
```bash
flutter test test/presentation/features/tasks/bloc/task_detail_bloc_test.dart
```

### Watch Mode (re-run on changes)
```bash
flutter test --watch
```

## Recording Test Runs (results + timings)

For a single command that:
- runs tests
- writes one folder per run (raw machine output + summary)
- keeps only the latest few runs

Use the recorder:

```bash
dart run tool/test_run_recorder.dart
```

Artifacts are written to `build_out/test_runs/<timestamp>/`:
- `machine.jsonl`: raw `flutter test --machine` output (line-delimited JSON)
- `stderr.txt`: anything emitted to stderr
- `summary.json`: structured summary (totals, failures, slowest tests)
- `summary.md`: human-readable summary

If the run fails, the recorder also reruns once with `-r expanded` (by default)
to capture full human-readable failure details:
- `expanded_stdout.txt`
- `expanded_stderr.txt`

### Keeping the latest N runs

```bash
dart run tool/test_run_recorder.dart --keep 5
```

### Passing through flutter test args

Everything after `--` is passed to `flutter test`:

```bash
dart run tool/test_run_recorder.dart -- --tags=unit
dart run tool/test_run_recorder.dart -- --exclude-tags=integration,slow
dart run tool/test_run_recorder.dart -- test/presentation/features/tasks/
```

### Performance metrics captured

The machine protocol includes a monotonic `time` (ms since run start) for each
`testStart`/`testDone` event. The recorder computes per-test duration as:

$$durationMs = testDone.time - testStart.time$$

The summary includes:
- total wall-clock duration for the run
- per-test durations
- top slowest tests (by duration)

### Controlling expanded output capture

```bash
dart run tool/test_run_recorder.dart --expanded failure
dart run tool/test_run_recorder.dart --expanded never
dart run tool/test_run_recorder.dart --expanded always
```

## Writing Tests

### Test Structure
Follow the Arrange-Act-Assert (AAA) pattern:

```dart
test('should update task name when valid input provided', () {
  // Arrange - Set up test data and mocks
  final task = TestData.task(name: 'Original');
  when(() => mockRepo.update(any())).thenAnswer((_) async {});
  
  // Act - Execute the operation
  await repository.update(id: task.id, name: 'Updated');
  
  // Assert - Verify the outcome
  verify(() => mockRepo.update(
    id: task.id,
    name: 'Updated',
    completed: any(named: 'completed'),
  )).called(1);
});
```

### Test Naming
Use descriptive names that explain the test scenario:
- ✅ `'updates task name when valid input provided'`
- ✅ `'throws ValidationError when name is empty'`
- ✅ `'emits [loading, success] when data loads successfully'`
- ❌ `'test update'`
- ❌ `'it works'`

### Using Test Helpers

#### TestData (Object Mother Pattern)
```dart
final task = TestData.task(
  name: 'My Task',
  completed: true,
  deadlineDate: DateTime.now(),
);

final project = TestData.project(name: 'My Project');
final label = TestData.label(name: 'Urgent', type: LabelType.label);
```

#### BlocTestContext
```dart
void main() {
  late BlocTestContext ctx;
  
  setUp(() {
    ctx = BlocTestContext();
    ctx.stubAllEmpty(); // Stub all repos to return empty lists
  });
  
  test('example', () {
    ctx.stubTasksReturn([TestData.task()]);
    // Test logic...
  });
}
```

#### Custom Matchers
```dart
expect(state, isLoadingState());
expect(state, isSuccessState());
expect(state, isErrorState(errorMessage: 'Network error'));
expect(bloc.stream, emitsStatesInOrder([isLoadingState(), isSuccessState()]));
```

#### Base Bloc Test
```dart
class MyBlocTest extends BaseBlocTest<MyBloc, MyState> {
  late MockRepository mockRepo;
  
  @override
  void setUp() {
    mockRepo = MockRepository();
    super.setUp(); // Creates bloc
  }
  
  @override
  MyBloc createBloc() => MyBloc(repository: mockRepo);
  
  // Tests automatically close bloc in tearDown
}
```

### Mock Setup

#### Using Mocktail
```dart
// Create mocks
final mockRepo = MockTaskRepository();

// Stub methods
when(() => mockRepo.getAll()).thenAnswer((_) async => []);
when(() => mockRepo.getById('task-1')).thenAnswer((_) async => task);
when(() => mockRepo.create(any())).thenAnswer((_) async {});

// Verify calls
verify(() => mockRepo.getAll()).called(1);
verifyNever(() => mockRepo.delete(any()));
```

#### Fallback Values
Register fallback values for `any()` matcher:
```dart
setUpAll(() {
  registerFallbackValue(TestData.task());
  registerFallbackValue(TestData.project());
  registerFallbackValue(TaskQuery.all());
});
```

### Integration Tests

Integration tests use real in-memory database:

```dart
void main() {
  late AppDatabase db;
  late TaskRepository repo;
  
  setUp(() {
    db = createTestDb();
    repo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
  });
  
  tearDown(() async {
    await closeTestDb(db);
  });
  
  test('creates and retrieves task', () async {
    await repo.create(name: 'Test Task');
    final tasks = await repo.watchAll().first;
    expect(tasks, hasLength(1));
    expect(tasks.first.name, 'Test Task');
  });
}
```

## Test Tags

Use tags to organize and selectively run tests:

```dart
@Tags(['unit', 'tasks'])
void main() {
  // Fast unit tests for task feature
}

@Tags(['integration', 'slow'])
void main() {
  // Slower integration tests
}
```

Available tags (defined in `dart_test.yaml`):
- `unit` - Fast unit tests with mocks
- `integration` - Tests with real database
- `widget` - Flutter widget tests
- `slow` - Tests that take longer to run
- `analytics`, `auth`, `wellbeing`, `tasks` - Feature-specific tags

## Best Practices

### DO
- ✅ Write descriptive test names
- ✅ Use TestData builders for test objects
- ✅ Follow Arrange-Act-Assert pattern
- ✅ Test both success and error scenarios
- ✅ Use custom matchers for readability
- ✅ Clean up resources in tearDown
- ✅ Register fallback values for mocktail

### DON'T
- ❌ Share mutable state between tests
- ❌ Use real network/file system in unit tests
- ❌ Test implementation details
- ❌ Write tests without clear assertions
- ❌ Ignore flaky tests (fix them!)
- ❌ Skip tearDown cleanup

## Coverage

View coverage report after running with `--coverage`:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
```

Target coverage: **80%+ overall**, **90%+ for critical paths**

## Common Patterns

### Testing Bloc State Transitions
```dart
blocTest<MyBloc, MyState>(
  'emits [loading, success] when data loads',
  build: () {
    when(() => mockRepo.load()).thenAnswer((_) async => data);
    return MyBloc(repository: mockRepo);
  },
  act: (bloc) => bloc.add(const MyEvent.load()),
  expect: () => [
    const MyState.loading(),
    MyState.success(data),
  ],
  verify: (_) {
    verify(() => mockRepo.load()).called(1);
  },
);
```

### Testing Stream Emissions
```dart
test('repository emits updated data', () async {
  final controller = StreamController<List<Task>>();
  when(() => mockRepo.watchAll()).thenAnswer((_) => controller.stream);
  
  final subscription = repo.watchAll().listen(expectAsync1((tasks) {
    expect(tasks, hasLength(1));
  }));
  
  controller.add([TestData.task()]);
  
  await subscription.cancel();
  await controller.close();
});
```

### Testing Error Handling
```dart
test('handles repository error gracefully', () async {
  when(() => mockRepo.load()).thenThrow(Exception('Network error'));
  
  expect(
    () => service.load(),
    throwsA(isA<Exception>()),
  );
});
```

## Troubleshooting

### Test Failures
1. Run with `--reporter=expanded` for detailed output
2. Check mock setup - ensure all required methods are stubbed
3. Verify async operations with `await` or `expectLater`
4. Check for proper cleanup in tearDown

### Flaky Tests
1. Add explicit timeouts for async operations
2. Avoid `Future.delayed` - use proper stream/bloc testing
3. Ensure tests don't depend on execution order
4. Use `pump()` and `pumpAndSettle()` in widget tests

### Mock Issues
1. Register fallback values in `setUpAll()`
2. Use `any(named: 'paramName')` for named parameters
3. Reset mocks between tests with `reset(mockRepo)`

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [bloc_test Package](https://pub.dev/packages/bloc_test)
- [mocktail Package](https://pub.dev/packages/mocktail)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/usage#testing)
