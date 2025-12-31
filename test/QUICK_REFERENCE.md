# Test Infrastructure Quick Reference

> **TL;DR**: Copy-paste solutions for common testing patterns

## 🚀 Quick Wins (30 Seconds Each)

### 1. Add Fallback Registration

**When**: Any test file using `mocktail` (has `when()` or `verify()` calls)  
**Why**: Prevents `Bad state: Missing Fallback` errors  
**Time**: 30 seconds

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/fallback_values.dart'; // Adjust path as needed

void main() {
  setUpAll(registerAllFallbackValues); // ← Add this line

  group('Your tests', () {
    // ... your tests
  });
}
```

### 2. Use TestData for Tasks

**When**: Creating tasks in tests  
**Why**: Reduces boilerplate, consistent defaults  
**Time**: 1 minute per test

```dart
// ❌ OLD: Verbose and error-prone
final task = Task(
  id: 't1',
  name: 'My Task',
  description: 'Do something',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  completed: false,
  projectId: null,
  labelIds: const [],
  startDate: null,
  deadlineDate: null,
  // ... 10 more fields
);

// ✅ NEW: Concise and clear
final task = TestData.task(
  id: 't1',
  name: 'My Task',
  description: 'Do something',
);
```

### 3. Use Custom Matchers for States

**When**: Testing BLoC states  
**Why**: More readable, less brittle  
**Time**: 1 minute per assertion

```dart
import '../helpers/custom_matchers.dart';

// ❌ OLD: String matching, easy to break
expect(bloc.state, isA<LoadingState>());
expect(bloc.state.runtimeType.toString(), contains('Loading'));

// ✅ NEW: Semantic and maintainable
expect(bloc.state, isLoadingState());
expect(bloc.state, isErrorState());
expect(bloc.state, isSuccessState());
expect(bloc.state, isInitialState());
```

---

## 📋 Complete Patterns

### TestData Object Mother

#### Available Methods

```dart
// Tasks
TestData.task(
  id: 't1',
  name: 'Task Name',
  description: 'Optional description',
  completed: false,
  projectId: 'p1',
  labelIds: const ['l1', 'l2'],
  startDate: DateTime(2025, 1, 1),
  deadlineDate: DateTime(2025, 1, 31),
  isNextAction: true,
  nextActionPriority: 1,
);

// Projects
TestData.project(
  id: 'p1',
  name: 'Project Name',
  completed: false,
);

// Labels
TestData.label(
  id: 'l1',
  name: 'Label Name',
  colorHex: '#FF5722',
  labelType: LabelType.tag,
);

// Journal Entries
TestData.journalEntry(
  id: 'j1',
  entryDate: DateTime(2025, 1, 1),
  moodRating: MoodRating.good,
  journalText: 'Today was productive',
);

// Trackers
TestData.tracker(
  id: 'tr1',
  name: 'Tracker Name',
  responseType: TrackerResponseType.numeric,
  responseConfig: NumericResponseConfig(min: 0, max: 10),
);

// Tracker Responses
TestData.trackerResponse(
  id: 'r1',
  trackerId: 'tr1',
  responseDate: DateTime(2025, 1, 1),
  numericValue: 7.5,
);

// Label Types
TestData.labelType(
  name: 'priority',
  iconCodePoint: Icons.star.codePoint,
);

// Screen Definitions
TestData.screenDefinition(
  name: 'mobile',
  minDip: 0,
  maxDip: 599,
);
```

### Custom Matchers

#### BLoC State Matchers

```dart
// Generic state matchers
expect(state, isInitialState());
expect(state, isLoadingState());
expect(state, isSuccessState());
expect(state, isErrorState());

// Auth-specific matchers
expect(state, isAuthenticatedState());
expect(state, isUnauthenticatedState());
```

#### Creating New Matchers

```dart
// In test/helpers/custom_matchers.dart
Matcher isYourCustomState() => const TypeMatcher<YourCustomState>();

// With predicate
Matcher hasProperty(dynamic value) {
  return predicate<YourState>(
    (state) => state.property == value,
    'has property $value',
  );
}
```

### BlocTestContext (Multi-Repository Tests)

**When**: Testing BLoCs with 2+ repository dependencies  
**Why**: Reduces mock setup boilerplate  
**Time**: 5 minutes first time, 30 seconds after

```dart
import '../helpers/bloc_test_context.dart';

void main() {
  late BlocTestContext ctx;
  late YourBloc bloc;

  setUp(() {
    ctx = BlocTestContext(); // Creates all mocks
    bloc = YourBloc(
      taskRepository: ctx.taskRepo,
      projectRepository: ctx.projectRepo,
      labelRepository: ctx.labelRepo,
    );
  });

  test('your test', () {
    // Setup mocks
    when(() => ctx.taskRepo.getById('t1'))
        .thenAnswer((_) async => TestData.task(id: 't1'));
    
    // Test logic
    // ...
  });
}
```

### Repository Mocks (Shared Implementations)

```dart
import '../mocks/repository_mocks.dart';

void main() {
  late MockTaskRepository mockTaskRepo;
  late MockProjectRepository mockProjectRepo;
  late MockLabelRepository mockLabelRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockWellbeingRepository mockWellbeingRepo;

  setUp(() {
    mockTaskRepo = MockTaskRepository();
    mockProjectRepo = MockProjectRepository();
    // ... etc
  });
}
```

---

## 🎯 When to Use What

### Use TestData When...
- ✅ Creating domain objects for test setup
- ✅ Need consistent test fixtures
- ✅ Want to focus test on behavior, not construction
- ✅ Testing service layer or widget layer

### Don't Use TestData When...
- ❌ Testing model constructors themselves
- ❌ Testing validation logic
- ❌ Need to test specific invalid field combinations
- ❌ Testing database layer directly

### Use Custom Matchers When...
- ✅ Same state assertion pattern used 3+ times
- ✅ Testing BLoC state transitions
- ✅ Complex state validation logic

### Use BlocTestContext When...
- ✅ BLoC has 3+ repository dependencies
- ✅ Complex multi-repository setup
- ✅ Want to reduce test boilerplate

### Use Fallback Registration When...
- ✅ ANY test file uses mocktail
- ✅ Getting "Missing Fallback" errors
- ✅ Always (it's nearly zero cost)

---

## 🔧 Common Patterns

### Widget Testing Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import '../fixtures/test_data.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('widget displays task', (tester) async {
    final task = TestData.task(name: 'My Task');
    
    await pumpLocalizedApp(
      tester,
      home: Scaffold(body: YourWidget(task: task)),
    );
    
    expect(find.text('My Task'), findsOneWidget);
  });
}
```

### BLoC Testing Pattern

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/test_data.dart';
import '../helpers/custom_matchers.dart';
import '../helpers/fallback_values.dart';
import '../mocks/repository_mocks.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  late MockTaskRepository mockRepo;
  late YourBloc bloc;

  setUp(() {
    mockRepo = MockTaskRepository();
    bloc = YourBloc(repository: mockRepo);
  });

  blocTest<YourBloc, YourState>(
    'emits loading then success when data fetched',
    build: () {
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => [TestData.task()]);
      return bloc;
    },
    act: (bloc) => bloc.add(const YourEvent()),
    expect: () => [
      isLoadingState(),
      isSuccessState(),
    ],
  );
}
```

### Integration Testing Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

import '../fixtures/test_data.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late YourRepository repository;

  setUp(() {
    db = createTestDb();
    repository = YourRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('end-to-end: create and retrieve entity', () async {
    final task = TestData.task(id: 't1', name: 'Integration Test');
    
    await repository.save(task);
    final retrieved = await repository.getById('t1');
    
    expect(retrieved, isNotNull);
    expect(retrieved!.name, 'Integration Test');
  });
}
```

### Service Testing Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/test_data.dart';
import '../helpers/fallback_values.dart';
import '../mocks/repository_mocks.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  late MockTaskRepository mockRepo;
  late YourService service;

  setUp(() {
    mockRepo = MockTaskRepository();
    service = YourService(repository: mockRepo);
  });

  test('service processes data correctly', () async {
    final tasks = [
      TestData.task(id: 't1', completed: true),
      TestData.task(id: 't2', completed: false),
    ];
    
    when(() => mockRepo.getAll()).thenAnswer((_) async => tasks);
    
    final result = await service.processTask();
    
    expect(result.completedCount, 1);
    expect(result.pendingCount, 1);
  });
}
```

---

## 📚 Import Paths

```dart
// Test Infrastructure
import '../helpers/fallback_values.dart';
import '../helpers/custom_matchers.dart';
import '../helpers/bloc_test_context.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_db.dart';

// Test Fixtures
import '../fixtures/test_data.dart';

// Mocks
import '../mocks/repository_mocks.dart';

// Adjust `../` depth based on your test file location:
// - test/*.dart → '../'
// - test/domain/*.dart → '../'
// - test/data/repositories/*.dart → '../../'
// - test/presentation/features/tasks/bloc/*.dart → '../../../../'
```

---

## 🐛 Troubleshooting

### "Bad state: Missing Fallback"
```dart
// Add to top of test file
setUpAll(registerAllFallbackValues);
```

### "TestData not found"
```dart
// Check import path - adjust ../ depth
import '../fixtures/test_data.dart';
```

### "Custom matcher not working"
```dart
// Import matchers
import '../helpers/custom_matchers.dart';

// Use parentheses
expect(state, isLoadingState()); // ✅
expect(state, isLoadingState);   // ❌
```

### "BlocTestContext creating wrong mocks"
```dart
// BlocTestContext includes:
// - taskRepo, projectRepo, labelRepo
// - settingsRepo, wellbeingRepo
// - occurrenceExpander, occurrenceWriteHelper

// If you need different mocks, create them manually
```

---

## 💡 Best Practices

1. **Always use fallback registration** - It's free insurance
2. **Prefer TestData over raw constructors** - Unless testing construction
3. **Use matchers for repeated patterns** - But not for one-offs
4. **Keep tests focused** - One behavior per test
5. **Use descriptive test names** - "should do X when Y"
6. **Extract complex setup** - Use `setUp()` and helper methods
7. **Test behavior, not implementation** - Focus on outcomes
8. **Avoid testing private methods** - Test through public API

---

## 🎓 Learning Path

1. **Start here**: Add fallback registration (30 sec)
2. **Next**: Use TestData.task() (1 min)
3. **Then**: Try custom matchers (2 min)
4. **Advanced**: Use BlocTestContext (5 min)
5. **Master**: Create your own helpers

---

## 📖 Further Reading

- [test/TESTING_GUIDE.md](./TESTING_GUIDE.md) - Comprehensive testing guide
- [test/README.md](./README.md) - Test suite overview
- [test/examples/](./examples/) - Complete examples
  - `test_infrastructure_example_test.dart` - Full example
  - `custom_matchers_example_test.dart` - Matcher examples
