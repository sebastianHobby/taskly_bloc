# Test Directory

This directory contains all tests for the Taskly application, organized by the
testing architecture directory contract.

## Directory Structure

```
test/
â”œâ”€â”€ core/               # Tests for core utilities and services
â”œâ”€â”€ data/               # Repository and data layer tests
â”œâ”€â”€ domain/             # Domain models, queries, and business logic tests
â”œâ”€â”€ presentation/       # BLoC and UI tests
â”œâ”€â”€ integration/        # Integration tests with real database
â”œâ”€â”€ integration_test/   # Local-stack pipeline tests (Supabase + PowerSync)
â”œâ”€â”€ contracts/          # Shared contract tests across implementations
â”œâ”€â”€ diagnosis/          # Debugging and investigation tests
â”œâ”€â”€ helpers/            # Shared test utilities and helpers
â”œâ”€â”€ mocks/              # Mock implementations
â””â”€â”€ fixtures/           # Test data builders
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

### Pipeline Tests (local Supabase + PowerSync)
Pipeline tests require a real local stack and run via the integration test
entrypoint to allow plugins + real HTTP.
- **Integration-only behavior:** these tests self-skip when not running under
  `IntegrationTestWidgetsFlutterBinding`, so `flutter test -t pipeline` will
  not execute them. Always use the entrypoint below.
- **Run (Windows):** `powershell -File tool/e2e/Run-LocalPipelineIntegrationTests.ps1 -ResetDb`
- **Entrypoint:** `integration_test/powersync_pipeline_entrypoint_test.dart`

### Widget Tests
Flutter widget tests. Located in `test/presentation/**`.
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

Note: `flutter test` does not currently support `--preset` in this repo's
Flutter SDK. Use tag filters (or the VS Code tasks) instead.

- Fast loop: `flutter test -x integration -x slow -x repository -x flaky -x pipeline -x diagnosis`
- Broader: `flutter test -x slow -x flaky -x pipeline -x diagnosis`
- DB confidence: `flutter test -t integration -t repository`
- Exclude local-stack pipeline: `flutter test -x pipeline -x diagnosis`
  - Note: pipeline tests are integration-test-only and will not execute under
    plain `flutter test`. Use the pipeline script/entrypoint.

### All Tests
```bash
flutter test
```

### With Coverage
```bash
flutter test --coverage \
  --coverage-package="^(taskly_bloc|taskly_core|taskly_data|taskly_domain|taskly_ui)$"
```

Official coverage metric in this repo:

1) `flutter test --coverage --coverage-package="^(taskly_bloc|taskly_core|taskly_data|taskly_domain|taskly_ui)$"`
2) `dart run tool/coverage_filter.dart`
3) `dart run tool/coverage_summary.dart`

Convenience script (runs root + package tests, merges coverage, and generates
HTML if `genhtml` is available):

```bash
tool/Run-Coverage.ps1
```

The script defaults to `-CoveragePackage taskly` to avoid Windows shell
escaping issues. Override if you need a stricter regex:

```bash
tool/Run-Coverage.ps1 -CoveragePackage "^(taskly_bloc|taskly_core|taskly_data|taskly_domain|taskly_ui)$"
```

### Fast Tests Only
```bash
flutter test -x integration -x slow -x repository -x flaky -x pipeline -x diagnosis
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

### Canonical templates (seed tests)

When adding a new test, start from one of the seed templates and adapt it:

- `test/domain/test_data_seed_test.dart` â€” deterministic fixtures + `testSafe`.
- `test/core/operation_context_seed_test.dart` â€” OperationContext propagation
  helpers + `testSafe`.
- `test/presentation/ui/priority_flag_widget_test.dart` â€” widget test template
- `packages/taskly_data/test/unit/errors/failure_guard_seed_test.dart` — data failure mapping template using `FailureGuard` + `testSafe`.
  using `testWidgetsSafe`.

### Mandatory tags (directory-driven)

Tests must declare their primary tag via a file-level `@Tags([...])` annotation
so presets and policies are enforceable.

Examples:

```dart
@Tags(['unit'])
library;
```

```dart
@Tags(['widget'])
library;
```

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

### VS Code tasks (recommended)

These tasks are defined in the workspace and are preferred over ad-hoc command
variants:

- `flutter_test_report` â€” runs tests and snapshots `test/last_run.json`
- `flutter_test_machine` â€” raw `flutter test --machine`
- `flutter_test_expanded` â€” human-readable failures
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
- âœ… `'updates task name when valid input provided'`
- âœ… `'throws ValidationError when name is empty'`
- âœ… `'emits [loading, success] when data loads successfully'`
- âŒ `'test update'`
- âŒ `'it works'`

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

## Typical Developer Loop

```text
1) flutter analyze
2) small loop: flutter test -x integration -x slow -x repository -x flaky -x pipeline -x diagnosis
3) broader loop (before merging): flutter test -x slow -x flaky -x pipeline -x diagnosis or -t integration -t repository
4) when touching sync/persistence pipelines: run tag=pipeline intentionally
5) when failures happen: inspect test/last_run.json artifacts
```
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

New tests must use the repoâ€™s safe wrappers (see the target-state testing
architecture in `doc/architecture/TESTING_ARCHITECTURE.md`). The intent is to
avoid hung tests and ensure consistent timeouts/diagnostics.
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
- âœ… Write descriptive test names
- âœ… Use TestData builders for test objects
- âœ… Follow Arrange-Act-Assert pattern
- âœ… Test both success and error scenarios
- âœ… Use custom matchers for readability
- âœ… Clean up resources in tearDown
- âœ… Register fallback values for mocktail

### DON'T
- âŒ Share mutable state between tests
- âŒ Use real network/file system in unit tests
- âŒ Test implementation details
- âŒ Write tests without clear assertions
- âŒ Ignore flaky tests (fix them!)
- âŒ Skip tearDown cleanup

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
- Seed stream sources used by widget tests (`TestStreamController.seeded(...)`
  or `BehaviorSubject.seeded(...)`). If an unseeded stream is required to
  assert loading, add `// ignore-unseeded-subject` on that line.

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
