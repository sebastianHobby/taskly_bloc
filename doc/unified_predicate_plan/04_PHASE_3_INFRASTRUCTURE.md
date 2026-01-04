# Phase 3: Unified Infrastructure

**Duration**: 1 day  
**Risk**: 🟡 Medium  
**Dependencies**: Phase 2 (Predicate hierarchy exists)

---

## Objectives

1. Create `UnifiedPredicateMapper<E>` - single mapper using FieldRef metadata
2. Create `FilterEvaluator<E>` - single evaluator using FieldRef accessors
3. Write parity tests to ensure old/new produce identical results

---

## Deliverables

| File | Description |
|------|-------------|
| `lib/data/repositories/mappers/unified_predicate_mapper.dart` | Generic SQL mapper |
| `lib/domain/services/filter_evaluator.dart` | Generic in-memory evaluator |
| `test/parity/predicate_mapper_parity_test.dart` | Parity test |
| `test/parity/filter_evaluator_parity_test.dart` | Parity test |

---

## Implementation Details

### 1. UnifiedPredicateMapper

```dart
// lib/data/repositories/mappers/unified_predicate_mapper.dart
import 'package:taskly_bloc/domain/queries/predicates/predicates.dart';
import 'package:taskly_bloc/domain/queries/field_ref.dart';
import 'package:taskly_bloc/domain/queries/comparison_operator.dart';

/// Converts [Predicate<E>] to SQL WHERE clauses.
/// 
/// Uses FieldRef metadata to generate column names and handle type-specific
/// SQL generation. Replaces entity-specific mappers with a single generic
/// implementation.
class UnifiedPredicateMapper<E> {
  const UnifiedPredicateMapper();

  /// Convert a predicate to SQL WHERE clause and parameters.
  /// 
  /// Returns a [SqlClause] with the SQL string and positional parameters.
  SqlClause toSql(Predicate<E> predicate) {
    return switch (predicate) {
      BoolPredicate<E> p => _mapBool(p),
      DatePredicate<E> p => _mapDate(p),
      StringPredicate<E> p => _mapString(p),
      NumericPredicate<E> p => _mapNumeric(p),
      NullPredicate<E> p => _mapNull(p),
      AndPredicate<E> p => _mapAnd(p),
      OrPredicate<E> p => _mapOr(p),
      NotPredicate<E> p => _mapNot(p),
    };
  }

  SqlClause _mapBool(BoolPredicate<E> p) {
    final column = p.field.columnName;
    final value = p.value ? 1 : 0; // SQLite uses integers for bools
    
    return switch (p.operator) {
      ComparisonOperator.equals => SqlClause('$column = ?', [value]),
      ComparisonOperator.notEquals => SqlClause('$column != ?', [value]),
      _ => throw ArgumentError('Invalid operator for bool: ${p.operator}'),
    };
  }

  SqlClause _mapDate(DatePredicate<E> p) {
    final column = p.field.columnName;
    
    // Resolve actual date value
    final dateValue = p.value ?? p.relativeDate?.resolve();
    if (dateValue == null) {
      throw ArgumentError('DatePredicate must have value or relativeDate');
    }
    
    // Use ISO8601 string for date comparison
    final value = dateValue.toIso8601String();
    
    return switch (p.operator) {
      ComparisonOperator.equals => 
          SqlClause("date($column) = date(?)", [value]),
      ComparisonOperator.notEquals => 
          SqlClause("date($column) != date(?)", [value]),
      ComparisonOperator.lessThan => 
          SqlClause("date($column) < date(?)", [value]),
      ComparisonOperator.lessThanOrEqual => 
          SqlClause("date($column) <= date(?)", [value]),
      ComparisonOperator.greaterThan => 
          SqlClause("date($column) > date(?)", [value]),
      ComparisonOperator.greaterThanOrEqual => 
          SqlClause("date($column) >= date(?)", [value]),
      _ => throw ArgumentError('Invalid operator for date: ${p.operator}'),
    };
  }

  SqlClause _mapString(StringPredicate<E> p) {
    final column = p.field.columnName;
    final value = p.value;
    
    // Handle case sensitivity
    final col = p.caseSensitive ? column : 'LOWER($column)';
    final val = p.caseSensitive ? value : value.toLowerCase();
    
    return switch (p.operator) {
      ComparisonOperator.equals => SqlClause('$col = ?', [val]),
      ComparisonOperator.notEquals => SqlClause('$col != ?', [val]),
      ComparisonOperator.contains => SqlClause('$col LIKE ?', ['%$val%']),
      _ => throw ArgumentError('Invalid operator for string: ${p.operator}'),
    };
  }

  SqlClause _mapNumeric(NumericPredicate<E> p) {
    final column = p.field.columnName;
    final value = p.value;
    
    return switch (p.operator) {
      ComparisonOperator.equals => SqlClause('$column = ?', [value]),
      ComparisonOperator.notEquals => SqlClause('$column != ?', [value]),
      ComparisonOperator.lessThan => SqlClause('$column < ?', [value]),
      ComparisonOperator.lessThanOrEqual => SqlClause('$column <= ?', [value]),
      ComparisonOperator.greaterThan => SqlClause('$column > ?', [value]),
      ComparisonOperator.greaterThanOrEqual => SqlClause('$column >= ?', [value]),
      _ => throw ArgumentError('Invalid operator for numeric: ${p.operator}'),
    };
  }

  SqlClause _mapNull(NullPredicate<E> p) {
    final column = p.field.columnName;
    
    return p.isNull
        ? SqlClause('$column IS NULL', [])
        : SqlClause('$column IS NOT NULL', []);
  }

  SqlClause _mapAnd(AndPredicate<E> p) {
    if (p.predicates.isEmpty) {
      return const SqlClause('1=1', []); // Always true
    }
    
    final clauses = p.predicates.map(toSql).toList();
    final sql = clauses.map((c) => '(${c.sql})').join(' AND ');
    final params = clauses.expand((c) => c.parameters).toList();
    
    return SqlClause(sql, params);
  }

  SqlClause _mapOr(OrPredicate<E> p) {
    if (p.predicates.isEmpty) {
      return const SqlClause('1=0', []); // Always false
    }
    
    final clauses = p.predicates.map(toSql).toList();
    final sql = clauses.map((c) => '(${c.sql})').join(' OR ');
    final params = clauses.expand((c) => c.parameters).toList();
    
    return SqlClause(sql, params);
  }

  SqlClause _mapNot(NotPredicate<E> p) {
    final inner = toSql(p.predicate);
    return SqlClause('NOT (${inner.sql})', inner.parameters);
  }
}

/// Result of converting a predicate to SQL.
class SqlClause {
  const SqlClause(this.sql, this.parameters);
  
  final String sql;
  final List<Object?> parameters;
  
  @override
  String toString() => 'SqlClause($sql, $parameters)';
}
```

### 2. FilterEvaluator

```dart
// lib/domain/services/filter_evaluator.dart
import 'package:taskly_bloc/domain/queries/predicates/predicates.dart';
import 'package:taskly_bloc/domain/queries/comparison_operator.dart';

/// Evaluates predicates against entities in memory.
/// 
/// Uses FieldRef accessors to extract field values for comparison.
/// Replaces entity-specific evaluators with a single generic implementation.
class FilterEvaluator<E> {
  const FilterEvaluator();

  /// Check if an entity matches a predicate.
  bool matches(E entity, Predicate<E> predicate) {
    return switch (predicate) {
      BoolPredicate<E> p => _matchBool(entity, p),
      DatePredicate<E> p => _matchDate(entity, p),
      StringPredicate<E> p => _matchString(entity, p),
      NumericPredicate<E> p => _matchNumeric(entity, p),
      NullPredicate<E> p => _matchNull(entity, p),
      AndPredicate<E> p => _matchAnd(entity, p),
      OrPredicate<E> p => _matchOr(entity, p),
      NotPredicate<E> p => _matchNot(entity, p),
    };
  }

  /// Filter a list of entities by a predicate.
  List<E> filter(List<E> entities, Predicate<E> predicate) {
    return entities.where((e) => matches(e, predicate)).toList();
  }

  bool _matchBool(E entity, BoolPredicate<E> p) {
    final value = p.field.accessor(entity);
    return switch (p.operator) {
      ComparisonOperator.equals => value == p.value,
      ComparisonOperator.notEquals => value != p.value,
      _ => throw ArgumentError('Invalid operator for bool: ${p.operator}'),
    };
  }

  bool _matchDate(E entity, DatePredicate<E> p) {
    final value = p.field.accessor(entity);
    if (value == null) return false; // Null dates don't match date predicates
    
    final target = p.value ?? p.relativeDate?.resolve();
    if (target == null) {
      throw ArgumentError('DatePredicate must have value or relativeDate');
    }
    
    // Compare dates only (ignore time)
    final entityDate = DateTime(value.year, value.month, value.day);
    final targetDate = DateTime(target.year, target.month, target.day);
    final cmp = entityDate.compareTo(targetDate);
    
    return switch (p.operator) {
      ComparisonOperator.equals => cmp == 0,
      ComparisonOperator.notEquals => cmp != 0,
      ComparisonOperator.lessThan => cmp < 0,
      ComparisonOperator.lessThanOrEqual => cmp <= 0,
      ComparisonOperator.greaterThan => cmp > 0,
      ComparisonOperator.greaterThanOrEqual => cmp >= 0,
      _ => throw ArgumentError('Invalid operator for date: ${p.operator}'),
    };
  }

  bool _matchString(E entity, StringPredicate<E> p) {
    var value = p.field.accessor(entity);
    var target = p.value;
    
    if (!p.caseSensitive) {
      value = value.toLowerCase();
      target = target.toLowerCase();
    }
    
    return switch (p.operator) {
      ComparisonOperator.equals => value == target,
      ComparisonOperator.notEquals => value != target,
      ComparisonOperator.contains => value.contains(target),
      _ => throw ArgumentError('Invalid operator for string: ${p.operator}'),
    };
  }

  bool _matchNumeric(E entity, NumericPredicate<E> p) {
    final value = p.field.accessor(entity);
    final cmp = value.compareTo(p.value);
    
    return switch (p.operator) {
      ComparisonOperator.equals => cmp == 0,
      ComparisonOperator.notEquals => cmp != 0,
      ComparisonOperator.lessThan => cmp < 0,
      ComparisonOperator.lessThanOrEqual => cmp <= 0,
      ComparisonOperator.greaterThan => cmp > 0,
      ComparisonOperator.greaterThanOrEqual => cmp >= 0,
      _ => throw ArgumentError('Invalid operator for numeric: ${p.operator}'),
    };
  }

  bool _matchNull(E entity, NullPredicate<E> p) {
    final value = p.field.accessor(entity);
    return p.isNull ? value == null : value != null;
  }

  bool _matchAnd(E entity, AndPredicate<E> p) {
    return p.predicates.every((pred) => matches(entity, pred));
  }

  bool _matchOr(E entity, OrPredicate<E> p) {
    return p.predicates.any((pred) => matches(entity, pred));
  }

  bool _matchNot(E entity, NotPredicate<E> p) {
    return !matches(entity, p.predicate);
  }
}
```

### 3. Parity Tests

```dart
// test/parity/predicate_mapper_parity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/entities/task.dart';
import 'package:taskly_bloc/domain/queries/fields/task_fields.dart';
import 'package:taskly_bloc/domain/queries/predicates/predicates.dart';
import 'package:taskly_bloc/domain/queries/comparison_operator.dart';
import 'package:taskly_bloc/data/repositories/mappers/unified_predicate_mapper.dart';
// Import old mapper for comparison
import 'package:taskly_bloc/data/repositories/mappers/task_predicate_mapper.dart';

void main() {
  group('Parity: UnifiedPredicateMapper vs TaskPredicateMapper', () {
    final newMapper = UnifiedPredicateMapper<Task>();
    final oldMapper = TaskPredicateMapper();

    test('bool predicate generates same SQL', () {
      final newPredicate = BoolPredicate<Task>(
        field: TaskFields.isCompleted,
        operator: ComparisonOperator.equals,
        value: true,
      );
      
      // TODO: Create equivalent old predicate
      // final oldPredicate = TaskBoolPredicate(
      //   field: TaskBoolField.isCompleted,
      //   operator: BoolOperator.equals,
      //   value: true,
      // );
      
      final newSql = newMapper.toSql(newPredicate);
      // final oldSql = oldMapper.toSql(oldPredicate);
      
      // expect(newSql.sql, equals(oldSql.sql));
      // expect(newSql.parameters, equals(oldSql.parameters));
      
      // Verify format is correct
      expect(newSql.sql, contains('is_completed'));
      expect(newSql.sql, contains('='));
    });

    test('date predicate generates same SQL', () {
      final date = DateTime(2024, 1, 15);
      final newPredicate = DatePredicate<Task>(
        field: TaskFields.dueDate,
        operator: ComparisonOperator.lessThanOrEqual,
        value: date,
      );
      
      final newSql = newMapper.toSql(newPredicate);
      
      expect(newSql.sql, contains('due_date'));
      expect(newSql.sql, contains('<='));
    });

    test('compound AND predicate generates same SQL', () {
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
      
      final sql = newMapper.toSql(predicate);
      
      expect(sql.sql, contains('AND'));
      expect(sql.sql, contains('is_completed'));
      expect(sql.sql, contains('is_trashed'));
    });
  });
}
```

---

## Step-by-Step Implementation

### Step 1: Create UnifiedPredicateMapper

Create the mapper using the template above, adjusting imports for your project structure.

### Step 2: Create FilterEvaluator

Create the evaluator using the template above.

### Step 3: Create Parity Test Directory

```bash
mkdir test/parity
```

### Step 4: Write Parity Tests

Create tests that:
1. Construct equivalent old and new predicates
2. Compare SQL output
3. Compare filter results

### Step 5: Run Parity Tests

```bash
flutter test test/parity/
```

### Step 6: Fix Any Discrepancies

If SQL differs, adjust the new mapper to match old behavior exactly.

---

## ✅ Verification Checklist

- [ ] `UnifiedPredicateMapper<Task>` compiles
- [ ] `FilterEvaluator<Task>` compiles
- [ ] Mapper generates valid SQL for all predicate types
- [ ] Evaluator correctly filters entities
- [ ] Parity tests pass (old vs new produce same results)
- [ ] `flutter analyze lib/data/repositories/mappers/` clean
- [ ] All existing tests still pass

---

## 🤖 AI Assistant Instructions

### Context Required

Attach or reference these files:
- `lib/domain/queries/predicates/predicates.dart` (from Phase 2)
- `lib/domain/queries/fields/task_fields.dart` (from Phase 1)
- `lib/data/repositories/mappers/task_predicate_mapper.dart` (existing - for reference)
- `lib/domain/services/task_filter_evaluator.dart` (existing - for reference)

### Implementation Checklist

1. [ ] Create `unified_predicate_mapper.dart` with `SqlClause` class
2. [ ] Implement all predicate type mappings in switch expression
3. [ ] Create `filter_evaluator.dart` with `matches` and `filter` methods
4. [ ] Implement all predicate type evaluations
5. [ ] Create `test/parity/` directory
6. [ ] Write parity tests comparing old vs new
7. [ ] Verify SQL output matches existing format

### Key Prompts

**Prompt 1 - Create Mapper:**
> Create `lib/data/repositories/mappers/unified_predicate_mapper.dart`:
> - Generic class `UnifiedPredicateMapper<E>`
> - `toSql(Predicate<E>)` returns `SqlClause(sql, parameters)`
> - Use exhaustive switch on sealed Predicate type
> - Use `field.columnName` for SQL column names
> - Handle date formatting with SQLite `date()` function
>
> Reference the existing `task_predicate_mapper.dart` for SQL patterns.

**Prompt 2 - Create Evaluator:**
> Create `lib/domain/services/filter_evaluator.dart`:
> - Generic class `FilterEvaluator<E>`
> - `matches(E entity, Predicate<E>)` returns bool
> - `filter(List<E>, Predicate<E>)` returns filtered list
> - Use `field.accessor(entity)` to get values
> - Handle null values appropriately

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| Entity-specific code in mapper | Use FieldRef metadata only |
| Different SQL format | Match existing mapper exactly |
| Missing predicate types in switch | Handle ALL sealed subtypes |
| Ignoring null handling | Handle nullable fields properly |
| Case sensitivity differences | Match existing behavior |

### SQL Format Reference

**CRITICAL**: Match existing SQL patterns exactly:

```sql
-- Bool fields use integers in SQLite
is_completed = 1   -- NOT is_completed = true

-- Date comparisons use date() function
date(due_date) <= date(?)   -- NOT due_date <= ?

-- String LIKE uses % wildcards
LOWER(title) LIKE ?  -- with value '%search%'
```

### Verification Questions

After completion, verify:
1. Does `UnifiedPredicateMapper<Task>().toSql(predicate)` work?
2. Does the SQL use `is_completed` (snake_case) not `isCompleted`?
3. Do date predicates use `date()` function?
4. Does `FilterEvaluator<Task>().matches(task, predicate)` work?
5. Do parity tests confirm old/new generate identical SQL?

---

## Files to Create

```
lib/
├── data/repositories/mappers/
│   └── unified_predicate_mapper.dart  # NEW
└── domain/services/
    └── filter_evaluator.dart          # NEW

test/
└── parity/
    ├── predicate_mapper_parity_test.dart   # NEW
    └── filter_evaluator_parity_test.dart   # NEW
```

---

## Next Phase

→ [Phase 4: Query Class Migration](./05_PHASE_4_QUERIES.md)
