# Phase 6: Test Migration

**Duration**: 1 day  
**Risk**: 🟢 Low  
**Dependencies**: Phase 5 (Repositories integrated)

---

## Objectives

1. Update all predicate-related unit tests to use new format
2. Update query tests to use new `filter` field
3. Ensure test coverage for all predicate types
4. Remove deprecated usage warnings from test files

---

## Deliverables

| Directory | Description |
|-----------|-------------|
| `test/domain/queries/` | Updated query tests |
| `test/domain/queries/predicates/` | New predicate tests |
| `test/data/repositories/mappers/` | Mapper tests |
| `test/domain/services/` | Evaluator tests |

---

## Test Categories

### 1. Predicate Unit Tests

Test each predicate type in isolation:

```dart
// test/domain/queries/predicates/bool_predicate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/entities/task.dart';
import 'package:taskly_bloc/domain/queries/fields/task_fields.dart';
import 'package:taskly_bloc/domain/queries/predicates/predicates.dart';
import 'package:taskly_bloc/domain/queries/comparison_operator.dart';

void main() {
  group('BoolPredicate', () {
    test('creates predicate with field and operator', () {
      final predicate = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: true,
      );

      expect(predicate.field, equals(TaskFields.isCompleted));
      expect(predicate.operator, equals(ComparisonOperator.equals));
      expect(predicate.value, isTrue);
    });

    test('toJson serializes correctly', () {
      final predicate = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: true,
      );

      final json = predicate.toJson();

      expect(json, equals({
        'type': 'bool',
        'field': 'isCompleted',
        'operator': 'equals',
        'value': true,
      }));
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'type': 'bool',
        'field': 'isCompleted',
        'operator': 'equals',
        'value': true,
      };

      final predicate = BoolPredicate.fromJson<Task>(json, TaskFields.byName);

      expect(predicate.field, equals(TaskFields.isCompleted));
      expect(predicate.value, isTrue);
    });

    test('equality works correctly', () {
      final p1 = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: true,
      );
      final p2 = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: true,
      );
      final p3 = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: false,
      );

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });
  });
}
```

### 2. Compound Predicate Tests

```dart
// test/domain/queries/predicates/compound_predicate_test.dart
void main() {
  group('AndPredicate', () {
    test('combines multiple predicates', () {
      final predicate = AndPredicate<Task>([
        BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: false,
        ),
        BoolPredicate<Task>(
          field: TaskFields.isTrashed,
          operator: ComparisonOperator.equals,
          value: false,
        ),
      ]);

      expect(predicate.predicates.length, equals(2));
    });

    test('toJson serializes nested predicates', () {
      final predicate = AndPredicate<Task>([
        BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: false,
        ),
      ]);

      final json = predicate.toJson();

      expect(json['type'], equals('and'));
      expect(json['predicates'], isA<List>());
      expect((json['predicates'] as List).first['type'], equals('bool'));
    });
  });

  group('NotPredicate', () {
    test('negates inner predicate', () {
      final inner = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: true,
      );
      final predicate = NotPredicate<Task>(inner);

      expect(predicate.predicate, equals(inner));
    });
  });
}
```

### 3. Mapper Tests

```dart
// test/data/repositories/mappers/unified_predicate_mapper_test.dart
void main() {
  final mapper = UnifiedPredicateMapper<Task>();

  group('UnifiedPredicateMapper', () {
    group('BoolPredicate', () {
      test('generates correct SQL for equals true', () {
        final predicate = BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: true,
        );

        final sql = mapper.toSql(predicate);

        expect(sql.sql, equals('is_completed = ?'));
        expect(sql.parameters, equals([1]));
      });

      test('generates correct SQL for equals false', () {
        final predicate = BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: false,
        );

        final sql = mapper.toSql(predicate);

        expect(sql.sql, equals('is_completed = ?'));
        expect(sql.parameters, equals([0]));
      });
    });

    group('DatePredicate', () {
      test('generates correct SQL for date comparison', () {
        final predicate = DatePredicate<Task>(
          field: TaskFields.dueDate,
          operator: ComparisonOperator.lessThanOrEqual,
          value: DateTime(2024, 1, 15),
        );

        final sql = mapper.toSql(predicate);

        expect(sql.sql, contains('due_date'));
        expect(sql.sql, contains('<='));
        expect(sql.parameters.first, contains('2024-01-15'));
      });
    });

    group('Compound predicates', () {
      test('generates correct SQL for AND', () {
        final predicate = AndPredicate<Task>([
          BoolPredicate<Task>(
            field: TaskFields.isCompleted,
            operator: ComparisonOperator.equals,
            value: false,
          ),
          BoolPredicate<Task>(
            field: TaskFields.isTrashed,
            operator: ComparisonOperator.equals,
            value: false,
          ),
        ]);

        final sql = mapper.toSql(predicate);

        expect(sql.sql, contains('AND'));
        expect(sql.sql, contains('is_completed'));
        expect(sql.sql, contains('is_trashed'));
      });
    });
  });
}
```

### 4. Evaluator Tests

```dart
// test/domain/services/filter_evaluator_test.dart
void main() {
  final evaluator = FilterEvaluator<Task>();

  // Test fixture
  Task createTask({
    bool isCompleted = false,
    bool isTrashed = false,
    DateTime? dueDate,
    int priority = 0,
  }) {
    return Task(
      id: 'test-id',
      title: 'Test Task',
      isCompleted: isCompleted,
      isTrashed: isTrashed,
      dueDate: dueDate,
      priority: priority,
      createdAt: DateTime.now(),
    );
  }

  group('FilterEvaluator', () {
    group('BoolPredicate', () {
      test('matches when value equals', () {
        final task = createTask(isCompleted: true);
        final predicate = BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: true,
        );

        expect(evaluator.matches(task, predicate), isTrue);
      });

      test('does not match when value differs', () {
        final task = createTask(isCompleted: false);
        final predicate = BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: true,
        );

        expect(evaluator.matches(task, predicate), isFalse);
      });
    });

    group('filter', () {
      test('filters list correctly', () {
        final tasks = [
          createTask(isCompleted: true),
          createTask(isCompleted: false),
          createTask(isCompleted: true),
        ];
        final predicate = BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: true,
        );

        final result = evaluator.filter(tasks, predicate);

        expect(result.length, equals(2));
        expect(result.every((t) => t.isCompleted), isTrue);
      });
    });
  });
}
```

### 5. Query Tests

```dart
// test/domain/queries/task_query_test.dart
void main() {
  group('TaskQuery', () {
    test('creates query with new filter field', () {
      final query = TaskQuery(
        filter: BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: false,
        ),
      );

      expect(query.filter, isNotNull);
      expect(query.effectivePredicate, equals(query.filter));
    });

    test('effectivePredicate prefers filter over predicates', () {
      final filter = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: false,
      );

      final query = TaskQuery(
        filter: filter,
        // ignore: deprecated_member_use_from_same_package
        predicates: [
          TaskBoolPredicate(
            field: TaskBoolField.isTrashed,
            operator: BoolOperator.equals,
            value: false,
          ),
        ],
      );

      // Should use filter, not predicates
      expect(query.effectivePredicate, equals(filter));
    });

    test('effectivePredicate converts legacy predicates', () {
      // ignore: deprecated_member_use_from_same_package
      final query = TaskQuery(
        predicates: [
          TaskBoolPredicate(
            field: TaskBoolField.isCompleted,
            operator: BoolOperator.equals,
            value: false,
          ),
        ],
      );

      final effective = query.effectivePredicate;

      expect(effective, isA<BoolPredicate<Task>>());
    });

    test('JSON round-trip preserves filter', () {
      final original = TaskQuery(
        filter: BoolPredicate<Task>(
          field: TaskFields.isCompleted,
          operator: ComparisonOperator.equals,
          value: false,
        ),
      );

      final json = original.toJson();
      final restored = TaskQuery.fromJson(json);

      expect(restored.filter, isNotNull);
      expect(restored.filter, equals(original.filter));
    });
  });
}
```

---

## Step-by-Step Implementation

### Step 1: Create Predicate Test Directory

```bash
mkdir test/domain/queries/predicates
```

### Step 2: Write Predicate Tests

Create test files for each predicate type:
- `bool_predicate_test.dart`
- `date_predicate_test.dart`
- `string_predicate_test.dart`
- `numeric_predicate_test.dart`
- `null_predicate_test.dart`
- `compound_predicate_test.dart`

### Step 3: Write Mapper Tests

Create/update `unified_predicate_mapper_test.dart`.

### Step 4: Write Evaluator Tests

Create/update `filter_evaluator_test.dart`.

### Step 5: Update Query Tests

Update existing query tests to use new `filter` field.

### Step 6: Run All Tests

```bash
flutter test
```

### Step 7: Check Coverage

```bash
flutter test --coverage
```

---

## ✅ Verification Checklist

- [ ] All predicate types have unit tests
- [ ] Mapper tests cover all predicate types
- [ ] Evaluator tests cover all predicate types
- [ ] Query tests use new `filter` field
- [ ] JSON serialization tests pass
- [ ] Equality tests pass
- [ ] No deprecated warnings in test files
- [ ] Full test suite passes
- [ ] Coverage maintained or improved

---

## 🤖 AI Assistant Instructions

### Context Required

Attach or reference these files:
- `lib/domain/queries/predicates/predicates.dart` (from Phase 2)
- `lib/data/repositories/mappers/unified_predicate_mapper.dart` (from Phase 3)
- `lib/domain/services/filter_evaluator.dart` (from Phase 3)
- Existing test files in `test/domain/queries/`
- Existing test files in `test/data/repositories/`

### Implementation Checklist

1. [ ] Create `test/domain/queries/predicates/` directory
2. [ ] Write tests for each predicate type
3. [ ] Write mapper tests for all SQL generation
4. [ ] Write evaluator tests for all matching logic
5. [ ] Update existing query tests
6. [ ] Remove deprecated usage from test files
7. [ ] Run full test suite

### Key Prompts

**Prompt 1 - Create Predicate Tests:**
> Create comprehensive tests for `BoolPredicate<Task>`:
> 1. Construction with field, operator, value
> 2. toJson() serialization format
> 3. fromJson() deserialization
> 4. Equality comparison
>
> Use TaskFields for field references. Follow existing test patterns in the codebase.

**Prompt 2 - Create Mapper Tests:**
> Create tests for `UnifiedPredicateMapper<Task>`:
> 1. Bool predicate → SQL (equals true/false)
> 2. Date predicate → SQL (with date() function)
> 3. String predicate → SQL (with LIKE)
> 4. Compound predicates → SQL (AND/OR/NOT)
>
> Verify exact SQL format matches existing mappers.

**Prompt 3 - Update Query Tests:**
> Update `test/domain/queries/task_query_test.dart` to:
> 1. Use new `filter` field instead of `predicates`
> 2. Test `effectivePredicate` getter
> 3. Test backward compatibility with deprecated field
> 4. Test JSON round-trip with new format

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| Using deprecated `predicates` without ignore | Add `// ignore: deprecated_member_use` |
| Missing edge cases | Test empty lists, null values |
| Hard-coded dates | Use `DateTime(2024, 1, 15)` for reproducibility |
| Flaky tests | No random values, deterministic fixtures |

### Test Coverage Goals

| Component | Coverage Target |
|-----------|-----------------|
| Predicate classes | 100% |
| UnifiedPredicateMapper | 95%+ |
| FilterEvaluator | 95%+ |
| Query classes | 90%+ |

### Verification Questions

After completion, verify:
1. Does `flutter test` pass with no errors?
2. Are there any deprecated warnings in test output?
3. Does coverage report show good coverage for new files?
4. Do tests document expected behavior clearly?

---

## Files to Create/Modify

```
test/
├── domain/
│   ├── queries/
│   │   ├── predicates/
│   │   │   ├── bool_predicate_test.dart      # NEW
│   │   │   ├── date_predicate_test.dart      # NEW
│   │   │   ├── string_predicate_test.dart    # NEW
│   │   │   ├── numeric_predicate_test.dart   # NEW
│   │   │   ├── null_predicate_test.dart      # NEW
│   │   │   └── compound_predicate_test.dart  # NEW
│   │   ├── task_query_test.dart              # MODIFY
│   │   └── project_query_test.dart           # MODIFY
│   └── services/
│       └── filter_evaluator_test.dart        # NEW
└── data/
    └── repositories/
        └── mappers/
            └── unified_predicate_mapper_test.dart  # NEW
```

---

## Next Phase

→ [Phase 7: Cleanup & Deletion](./08_PHASE_7_CLEANUP.md)
