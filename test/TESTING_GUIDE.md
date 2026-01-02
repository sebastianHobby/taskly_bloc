# Testing Guide

A comprehensive guide to writing and maintaining tests in the Taskly project.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Test Structure](#test-structure)
3. [Testing Patterns](#testing-patterns)
4. [Best Practices](#best-practices)
5. [Common Scenarios](#common-scenarios)
6. [Troubleshooting](#troubleshooting)

## Quick Start

### Running Tests
```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/path/to/test.dart

# Watch mode
flutter test --watch

# Fast tests only (exclude slow integration tests)
flutter test --exclude-tags=integration,slow
```

### Writing Your First Test
```dart
import 'package:flutter_test/flutter_test.dart';
import '../../fixtures/test_data.dart';

void main() {
  test('should create task with name', () {
    // Arrange - Set up test data
    final task = TestData.task(name: 'Buy groceries');
    
    // Act - Execute the operation
    final result = task.name;
    
    // Assert - Verify the outcome
    expect(result, 'Buy groceries');
  });
}
```

## Test Structure

### File Organization
```
test/
├── core/               # Core utilities tests
├── data/               # Repository tests
├── domain/             # Business logic tests
├── presentation/       # Bloc and UI tests
├── integration/        # End-to-end tests
├── helpers/            # Test utilities
│   ├── base_bloc_test.dart
│   ├── bloc_test_helpers.dart
│   ├── custom_matchers.dart
│   ├── drift_test_helper.dart
│   └── pump_app.dart
├── mocks/              # Mock implementations
└── fixtures/           # Test data builders
```

### Standard Test Structure
```dart
void main() {
  // Group related tests
  group('FeatureName', () {
    // Declare dependencies
    late MockRepository mockRepo;
    late ServiceUnderTest service;
    
    // One-time setup (expensive operations)
    setUpAll(() {
      registerFallbackValues();
    });
    
    // Setup before each test
    setUp(() {
      mockRepo = MockRepository();
      service = ServiceUnderTest(repository: mockRepo);
    });
    
    // Cleanup after each test
    tearDown(() {
      // Close streams, reset mocks, etc.
    });
    
    // Nested groups for specific methods/features
    group('methodName', () {
      test('should do X when Y happens', () {
        // Test implementation
      });
      
      test('should throw error when Z is invalid', () {
        // Test implementation
      });
    });
  });
}
```

## Testing Patterns

### 1. Using TestData (Object Mother)
Create test objects with sensible defaults:
```dart
// Simple usage
final task = TestData.task();

// With overrides
final urgentTask = TestData.task(
  name: 'Critical Bug',
  deadlineDate: DateTime.now().add(Duration(hours: 2)),
  completed: false,
);

// Complex objects
final project = TestData.project(
  name: 'Q4 Launch',
  labels: [
    TestData.label(name: 'High Priority'),
    TestData.label(name: 'Marketing'),
  ],
);
```

### 2. BLoC Testing with bloc_test
```dart
blocTest<TaskDetailBloc, TaskDetailState>(
  'emits [loading, success] when task loads',
  build: () {
    // Setup mocks
    when(() => mockTaskRepo.getById('task-1'))
        .thenAnswer((_) async => TestData.task(id: 'task-1'));
    return TaskDetailBloc(taskRepository: mockTaskRepo);
  },
  act: (bloc) => bloc.add(const TaskDetailGet('task-1')),
  expect: () => [
    isA<TaskDetailLoadInProgress>(),
    isA<TaskDetailLoadSuccess>()
        .having((s) => s.task.id, 'task.id', 'task-1'),
  ],
  verify: (_) {
    verify(() => mockTaskRepo.getById('task-1')).called(1);
  },
);
```

### 3. Using BaseBlocTest
Extend BaseBlocTest to reduce boilerplate:
```dart
class TaskDetailBlocTest extends BaseBlocTest<TaskDetailBloc, TaskDetailState> {
  late MockTaskRepository mockTaskRepo;
  late MockProjectRepository mockProjectRepo;
  
  @override
  void setUp() {
    mockTaskRepo = MockTaskRepository();
    mockProjectRepo = MockProjectRepository();
    // Stub default behaviors
    when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
    super.setUp(); // Creates bloc
  }
  
  @override
  TaskDetailBloc createBloc() {
    return TaskDetailBloc(
      taskRepository: mockTaskRepo,
      projectRepository: mockProjectRepo,
      labelRepository: mockLabelRepo,
    );
  }
}

void main() {
  final test = TaskDetailBlocTest();
  
  setUp(test.setUp);
  tearDown(test.tearDown);
  
  test('loads task successfully', () async {
    // bloc is available via test.bloc
    final state = await test.waitForState((s) => s is SuccessState);
    expect(state, isSuccessState());
  });
}
```

### 4. Using BlocTestContext
Manage multiple mocks easily:
```dart
void main() {
  late BlocTestContext ctx;
  
  setUp(() {
    ctx = BlocTestContext();
    ctx.stubAllEmpty(); // All repos return empty lists
  });
  
  test('handles empty state', () {
    final bloc = MyBloc(
      taskRepository: ctx.taskRepo,
      projectRepository: ctx.projectRepo,
    );
    
    expect(bloc.state, isEmpty);
  });
  
  test('loads tasks', () {
    ctx.stubTasksReturn([TestData.task()]);
    // Test with tasks...
  });
}
```

### 5. Custom Matchers
Make assertions more readable:
```dart
// State matchers
expect(state, isLoadingState());
expect(state, isSuccessState());
expect(state, isErrorState());
expect(state, isErrorState(errorMessage: 'Network error'));

// Collection matchers
expect(tasks, hasLength(3));
expect(tasks, containsWhere((t) => t.name == 'Important'));

// Date matchers
expect(task.createdAt, isToday());
expect(task.deadlineDate, isInTheFuture());

// String matchers
expect(task.name, isNotEmptyString());
expect(task.description, isNullOrEmpty());

// Stream matchers
expect(
  bloc.stream,
  emitsStatesInOrder([isLoadingState(), isSuccessState()]),
);
```

### 6. Stream Testing
```dart
// Wait for specific emission
final state = await expectStreamEmits(
  bloc.stream,
  isSuccessState(),
);

// Wait for multiple emissions in order
await expectStreamEmitsInOrder(
  bloc.stream,
  [isLoadingState(), isSuccessState()],
);

// Verify stream is empty
await expectStreamEmpty(emptyStream);

// Using bloc extensions
await bloc.waitForAnyEmission();
final hasEmitted = await bloc.hasEmitted();
```

### 7. Integration Testing
Test with real database:
```dart
void main() {
  late AppDatabase db;
  late TaskRepository repo;
  
  setUp(() async {
    db = await createTestDatabase();
    repo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
  });
  
  tearDown(() async {
    await closeTestDatabase(db);
  });
  
  test('creates task and retrieves it', () async {
    await repo.create(name: 'Test Task');
    
    final tasks = await repo.watchAll().first;
    expect(tasks, hasLength(1));
    expect(tasks.first.name, 'Test Task');
  });
}
```

## Best Practices

### DO ✅

1. **Write descriptive test names**
   ```dart
   // Good
   test('updates task completion status when checkbox is tapped', () {});
   
   // Bad
   test('test update', () {});
   ```

2. **Follow Arrange-Act-Assert**
   ```dart
   test('example', () {
     // Arrange - Set up test data and mocks
     final task = TestData.task();
     when(() => mockRepo.save(task)).thenAnswer((_) async {});
     
     // Act - Execute the operation
     await service.saveTask(task);
     
     // Assert - Verify the outcome
     verify(() => mockRepo.save(task)).called(1);
   });
   ```

3. **Test both success and error paths**
   ```dart
   test('succeeds when input is valid', () {});
   test('throws ValidationError when input is empty', () {});
   test('handles network timeout gracefully', () {});
   ```

4. **Use TestData for all test objects**
   ```dart
   // Good
   final task = TestData.task(name: 'Test');
   
   // Bad - hardcoded test data
   final task = Task(
     id: 'id-1',
     createdAt: DateTime.now(),
     updatedAt: DateTime.now(),
     name: 'Test',
     completed: false,
   );
   ```

5. **Clean up in tearDown**
   ```dart
   tearDown(() async {
     await bloc.close();
     await db.close();
     controller.close();
   });
   ```

### DON'T ❌

1. **Share mutable state between tests**
   ```dart
   // Bad - shared state
   final task = TestData.task();
   
   test('test 1', () {
     task.name = 'Modified'; // Affects other tests!
   });
   ```

2. **Test implementation details**
   ```dart
   // Bad - testing private methods/fields
   test('should call _privateMethod', () {});
   
   // Good - test public behavior
   test('should return formatted date', () {});
   ```

3. **Use real external dependencies**
   ```dart
   // Bad
   final apiClient = RealApiClient(); // Makes network calls
   
   // Good
   final mockClient = MockApiClient(); // Controlled behavior
   ```

4. **Write tests without assertions**
   ```dart
   // Bad - no verification
   test('updates task', () {
     service.update(task);
   });
   
   // Good
   test('updates task', () {
     service.update(task);
     verify(() => mockRepo.update(task)).called(1);
   });
   ```

## Common Scenarios

### Testing Error Handling
```dart
test('handles repository error gracefully', () async {
  when(() => mockRepo.load())
      .thenThrow(Exception('Network error'));
  
  expect(
    () => service.load(),
    throwsA(isA<Exception>()),
  );
});

blocTest<MyBloc, MyState>(
  'emits error state on failure',
  build: () {
    when(() => mockRepo.load())
        .thenThrow(Exception('Failed'));
    return MyBloc(repository: mockRepo);
  },
  act: (bloc) => bloc.add(const LoadRequested()),
  expect: () => [
    isLoadingState(),
    isErrorState(errorMessage: 'Failed'),
  ],
);
```

### Testing Async Operations
```dart
test('waits for async operation', () async {
  final completer = Completer<String>();
  when(() => mockRepo.load()).thenAnswer((_) => completer.future);
  
  final future = service.load();
  
  // Operation hasn't completed yet
  expect(service.isLoading, isTrue);
  
  // Complete the operation
  completer.complete('result');
  await future;
  
  expect(service.isLoading, isFalse);
});
```

### Testing Streams
```dart
test('emits updated values', () async {
  final controller = StreamController<List<Task>>();
  when(() => mockRepo.watchAll())
      .thenAnswer((_) => controller.stream);
  
  final stream = service.watchTasks();
  
  // Collect emissions
  final emissions = <List<Task>>[];
  final subscription = stream.listen(emissions.add);
  
  // Emit test data
  controller.add([TestData.task(name: 'Task 1')]);
  await Future.delayed(Duration.zero);
  
  controller.add([TestData.task(name: 'Task 2')]);
  await Future.delayed(Duration.zero);
  
  expect(emissions, hasLength(2));
  expect(emissions[0].first.name, 'Task 1');
  expect(emissions[1].first.name, 'Task 2');
  
  await subscription.cancel();
  await controller.close();
});
```

### Testing Widget Interaction
```dart
testWidgets('updates task when form is submitted', (tester) async {
  await pumpLocalizedApp(
    tester,
    home: TaskForm(onSubmit: mockOnSubmit),
  );
  
  // Enter text
  await tester.enterText(
    find.byType(TextField),
    'New Task',
  );
  
  // Tap submit button
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  
  // Verify callback
  verify(() => mockOnSubmit('New Task')).called(1);
});
```

## Troubleshooting

### Test Timeouts & Infinite Loops

**Critical:** Tests can run indefinitely or hang for 10+ minutes if not properly
protected. This section covers how to prevent and debug timeout issues.

#### Understanding Timeout Types

1. **Inactivity Timeout** (`@Timeout` annotation)
   - Only triggers when test is **completely idle**
   - Does NOT protect against infinite loops or continuous activity
   - Example: `@Timeout(Duration(seconds: 60))` in `dart_test.yaml`

2. **Total Duration Timeout** (Recommended)
   - Enforces **hard limit** on total test execution time
   - Protects against infinite loops, regardless of activity
   - Use `testWidgetsWithTimeout()` wrapper

#### Most Robust Timeout Strategy

```dart
import '../helpers/pump_helpers.dart';

// ✅ BEST: Total duration timeout - protects against everything
testWidgetsWithTimeout(
  'my test',
  timeout: const Duration(seconds: 30), // Hard limit
  (tester) async {
    // Test implementation
  },
);

// ❌ AVOID: Inactivity-only timeout
@Timeout(Duration(seconds: 60)) // Only protects against deadlocks
testWidgets('my test', (tester) async {
  // Can run for 10+ minutes if continuously pumping
});
```

#### Common Timeout Scenarios

**1. pumpAndSettle() with Active Streams**

```dart
// ❌ DANGEROUS: Can run for 10 minutes
await tester.pumpWidget(MyBlocWidget());
await tester.pumpAndSettle(); // Loops while frames scheduled

// ✅ SAFE: Fixed duration
await tester.pumpWidget(MyBlocWidget());
await tester.pumpForStream(); // Fixed 10 frames

// ✅ SAFE: With short timeout
await tester.pumpAndSettleSafe(
  timeout: const Duration(seconds: 2), // Throws after 2s
);
```

**2. Unclosed Stream Subscriptions**

```dart
// ❌ RISKY: May not close on test failure
final subscription = stream.listen(handler);
await Future.delayed(Duration(milliseconds: 50));
await subscription.cancel(); // May not be reached

// ✅ SAFE: Always closes via tearDown
final subscription = stream.listen(handler);
addTearDown(() async => await subscription.cancel());
await Future.delayed(Duration(milliseconds: 50));
```

**3. pump(Duration) Blocking**

```dart
// ❌ DANGEROUS: Can block indefinitely with scheduled timers
await tester.pump(const Duration(seconds: 1));

// ✅ SAFE: No duration parameter
await tester.pump(); // Process one frame
for (var i = 0; i < 10; i++) {
  await tester.pump(); // Multiple frames without blocking
}
```

#### Timeout Configuration Layers

1. **Test-Level** (Most Important) ✅
   ```dart
   testWidgetsWithTimeout(
     'test',
     timeout: const Duration(seconds: 30),
     (tester) async { ... },
   );
   ```

2. **Operation-Level**
   ```dart
   await tester.pumpAndSettleSafe(timeout: Duration(seconds: 2));
   await waitForStreamEmissions(stream, timeout: Duration(seconds: 5));
   await myAsyncOp().timeout(Duration(seconds: 10));
   ```

3. **Configuration-Level** (dart_test.yaml)
   ```yaml
   tags:
     widget:
       timeout: 30s  # Inactivity timeout
   timeout: 5m       # Process-level timeout
   ```

4. **CI/CD-Level**
   ```yaml
   # .github/workflows/test.yml
   jobs:
     test:
       timeout-minutes: 10  # Kill job after 10 minutes
   ```

#### Debugging Hanging Tests

**Step 1: Identify the pattern**
```bash
# Run with verbose output
flutter test --verbose test/my_hanging_test.dart

# Look for:
# - "pumpAndSettle" in output → Use pumpForStream() instead
# - Stream subscriptions → Add addTearDown() cleanup
# - "pump(Duration)" → Use pump() without duration
```

**Step 2: Add timeout protection**
```dart
// Wrap test with explicit timeout
testWidgetsWithTimeout(
  'potentially hanging test',
  timeout: const Duration(seconds: 5), // Short timeout to fail fast
  (tester) async {
    // Your test code
  },
);
```

**Step 3: Check for these patterns**
- [ ] Using `pumpAndSettle()` with BLoC/stream widgets?
- [ ] Stream subscriptions without `addTearDown()`?
- [ ] Using `pump(Duration)` instead of `pump()`?
- [ ] Missing `await` on async operations?
- [ ] Infinite loops in test logic?

See [TEST_TIMEOUT_ANALYSIS.md](TEST_TIMEOUT_ANALYSIS.md) for comprehensive analysis.

### Test Hangs with BLoC/Streams

**Problem:** `pumpAndSettle()` hangs indefinitely when testing widgets with BLoC
or stream subscriptions.

**Cause:** `pumpAndSettle()` waits for ALL scheduled frames to complete, but
stream subscriptions (like `watchAuthState()`, `watchAll()`) create ongoing
listeners that never "settle".

**Solution:** Use centralized pump helpers from `test/helpers/pump_helpers.dart`:

```dart
import '../helpers/pump_helpers.dart';

testWidgets('loads data from stream', (tester) async {
  await tester.pumpWidget(MyBlocWidget());
  
  // ❌ BAD: Will hang forever with stream subscriptions
  // await tester.pumpAndSettle();
  
  // ✅ GOOD: Pumps for a bounded duration
  await tester.pumpForStream();
  
  expect(find.text('Loaded'), findsOneWidget);
});
```

**Available Pump Helpers:**

| Method | Use Case | Timeout Protection |
|--------|----------|-------------------|
| `pumpForStream()` | Tests with BLoC/stream subscriptions | Fixed 10 frames |
| `pumpForAnimation(duration)` | Tests waiting for specific animations | Fixed duration |
| `pumpAndSettleSafe()` | Widget tests needing settle | 2s timeout (throws) |
| `pumpSettleOrTimeout()` | Best-effort settle | 2s timeout (no throw) |
| `pumpFrames(count)` | Fine-grained control over frame count | Fixed count |
| `pumpUntilFound(finder)` | Wait for async widget to appear | Returns false after 2s |

### Test Failures

**"Could not find a match for <method>"**
- Register fallback values in setUpAll:
  ```dart
  setUpAll(() {
    registerFallbackValue(TestData.task());
  });
  ```

**"Bad state: Stream has already been listened to"**
- Use broadcast streams or create new stream for each test
- Don't share stream instances between tests

**Flaky async tests**
- Use `pumpForStream()` for BLoC tests (NOT `pumpAndSettle()`)
- Use proper stream testing utilities
- Avoid `Future.delayed` - use explicit waits

### Mock Issues

**"Missing stub warning"**
- Stub all methods that will be called:
  ```dart
  when(() => mockRepo.method()).thenAnswer((_) async => result);
  ```

**Named parameters not matching**
- Use `any(named: 'paramName')`:
  ```dart
  when(() => mockRepo.update(
    id: any(named: 'id'),
    name: any(named: 'name'),
  )).thenAnswer((_) async {});
  ```

### Performance Issues

**Tests running slowly**
- Use `--exclude-tags=slow,integration` for fast feedback
- Check for inefficient database operations
- Reduce test database operations
- Use parallel execution: `concurrency: 8` in dart_test.yaml

## Additional Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [bloc_test Package](https://pub.dev/packages/bloc_test)
- [mocktail Package](https://pub.dev/packages/mocktail)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/usage#testing)
- [Test README](README.md)
