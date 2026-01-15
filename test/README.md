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

Prefer presets over ad-hoc tag combinations. Presets are defined in
`dart_test.yaml` and are the canonical way to run consistent suites.

Common presets:

- Fast loop: `flutter test --preset=fast`
- Broader: `flutter test --preset=quick`
- DB confidence: `flutter test --preset=database`
- Exclude local-stack pipeline: `flutter test --preset=no_pipeline`

### All Tests
```bash
flutter test
```

### With Coverage
```bash
flutter test --coverage
```

Official coverage metric in this repo:

1) `flutter test --coverage`
2) `dart run tool/coverage_filter.dart`
3) `dart run tool/coverage_summary.dart`

### Fast Tests Only
```bash
flutter test --preset=fast
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

## Test output files (file_reporters)

This repo configures `file_reporters` in `dart_test.yaml` to write a JSON report
to:

- `test/last_run.json`

For convenience, use the VS Code task `flutter_test_report` which runs the test
suite and copies `test/last_run.json` to a dated file under `test/`.

## Writing Tests

### Recommended imports + environment setup

Prefer using the shared imports and standardized setup hooks:

```dart
import '../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);
}
```

Why:
- `setUpAllTestEnvironment` ensures the test binding is initialized, talker is
  ready, and mocktail fallback values are registered.
- `setUpTestEnvironment` keeps per-test setup small and consistent.

### Cleanup and teardown (best practice)

Prefer `addTearDown` for any resource created during a test, so cleanup is
registered immediately and still runs if the test fails early.

This repo provides `autoTearDown(...)` for convenience:

```dart
final controller = autoTearDown(
  StreamController<int>.broadcast(),
  (c) => c.close(),
);
```

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
  deadlineDate: TestConstants.referenceDate,
);

final project = TestData.project(name: 'My Project');
final label = TestData.label(name: 'Urgent', type: LabelType.label);
```

Tip: Most `TestData` builders accept an optional `now:` so you can make
time-based defaults deterministic:

```dart
final clock = TestClock(TestConstants.referenceDate);
final task = TestData.task(now: clock.now);
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
  registerAllFallbackValues();
});
```

### Assertions

`flutter_test` matchers are fine. When it improves readability, prefer
`checks` (available via `test_imports.dart`):

```dart
check(value).isGreaterThan(0);
check(list).length.equals(3);
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
- `analytics`, `auth`, `journal`, `tasks` - Feature-specific tags

More configuration options:
- Repo config: `../dart_test.yaml`
- Official docs: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md

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

### Safe defaults (required)

Prefer the repo's safe wrappers from `test/helpers/test_imports.dart`:

- `testSafe(...)` for async unit tests (hard timeout)
- `testWidgetsSafe(...)` for widget tests (hard timeout)
- `blocTestSafe(...)` for BLoC tests (hard timeout around `act`)

Policy:

- Avoid raw `testWidgets()` unless you add a justification comment like
  `// safe:` and you are confident the test cannot hang.
- Avoid `pumpAndSettle()` for stream/BLoC-driven widgets; prefer
  `tester.pumpForStream()` or `tester.pumpUntilFound(...)`.

### Testing Bloc State Transitions
```dart
blocTestSafe<MyBloc, MyState>(
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
testSafe('repository emits updated data', () async {
  final controller = TestStreamController<List<Task>>();
  when(() => mockRepo.watchAll()).thenAnswer((_) => controller.stream);
  
  final subscription = repo.watchAll().listen(expectAsync1((tasks) {
    expect(tasks, hasLength(1));
  }));
  
  controller.emit([TestData.task()]);
  
  await subscription.cancel();
  await controller.dispose();
});
```

### Testing Error Handling
```dart
testSafe('handles repository error gracefully', () async {
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
4. Avoid `pumpAndSettle()` for stream/BLoC-driven widgets
  (prefer `pumpForStream()` / `pumpUntilFound(...)`)

### Mock Issues
1. Register fallback values in `setUpAll()`
2. Use `any(named: 'paramName')` for named parameters
3. Reset mocks between tests with `reset(mockRepo)`

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [bloc_test Package](https://pub.dev/packages/bloc_test)
- [mocktail Package](https://pub.dev/packages/mocktail)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/usage#testing)
