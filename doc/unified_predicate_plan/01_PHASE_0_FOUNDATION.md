# Phase 0: Foundation

**Duration**: 0.5 days  
**Risk**: 🟢 Low  
**Dependencies**: None

---

## Objectives

1. Create feature branch
2. Set up folder structure
3. Create base types (`FieldRef`, `ComparisonOperator`)

---

## Deliverables

| File | Description |
|------|-------------|
| `lib/domain/queries/field_ref.dart` | FieldRef<E,T> class |
| `lib/domain/queries/comparison_operator.dart` | Shared operators |

---

## Implementation Details

### 1. FieldRef Definition

```dart
// lib/domain/queries/field_ref.dart
import 'package:meta/meta.dart';

/// A typed reference to a field on entity type [E] with value type [T].
/// 
/// Used for compile-time type safety in predicate construction.
@immutable
final class FieldRef<E, T> {
  const FieldRef({
    required this.name,
    required this.columnName,
    required this.accessor,
    this.isNullable = false,
  });

  /// The logical field name (for JSON serialization).
  final String name;
  
  /// The SQL column name (for query building).
  final String columnName;
  
  /// Function to extract field value from entity.
  final T Function(E entity) accessor;
  
  /// Whether the field can be null.
  final bool isNullable;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldRef && name == other.name && columnName == other.columnName;

  @override
  int get hashCode => Object.hash(name, columnName);

  @override
  String toString() => 'FieldRef<$E, $T>($name)';
}
```

### 2. Comparison Operators

```dart
// lib/domain/queries/comparison_operator.dart
import 'package:meta/meta.dart';

/// Operators for comparing values in predicates.
@immutable
enum ComparisonOperator {
  equals('='),
  notEquals('!='),
  lessThan('<'),
  lessThanOrEqual('<='),
  greaterThan('>'),
  greaterThanOrEqual('>='),
  contains('LIKE'),
  isNull('IS NULL'),
  isNotNull('IS NOT NULL');

  const ComparisonOperator(this.sqlOperator);
  
  final String sqlOperator;
  
  /// Parse from JSON string.
  static ComparisonOperator fromJson(String value) {
    return ComparisonOperator.values.firstWhere(
      (op) => op.name == value,
      orElse: () => throw ArgumentError('Unknown operator: $value'),
    );
  }
  
  /// Convert to JSON string.
  String toJson() => name;
}

/// Operators for boolean logic.
@immutable
enum LogicalOperator {
  and,
  or;

  static LogicalOperator fromJson(String value) {
    return LogicalOperator.values.firstWhere(
      (op) => op.name == value,
      orElse: () => throw ArgumentError('Unknown logical operator: $value'),
    );
  }

  String toJson() => name;
}
```

---

## Step-by-Step Implementation

### Step 1: Create Branch

```bash
git checkout -b feature/upa-unified-predicates
```

### Step 2: Create Directory

Create `lib/domain/queries/` if it doesn't exist.

### Step 3: Create field_ref.dart

Copy the FieldRef implementation above.

### Step 4: Create comparison_operator.dart

Copy the ComparisonOperator implementation above.

### Step 5: Create Barrel Export

```dart
// lib/domain/queries/queries.dart
export 'comparison_operator.dart';
export 'field_ref.dart';
```

---

## ✅ Verification Checklist

- [ ] Feature branch created
- [ ] `lib/domain/queries/field_ref.dart` exists
- [ ] `lib/domain/queries/comparison_operator.dart` exists
- [ ] `lib/domain/queries/queries.dart` barrel export exists
- [ ] `flutter analyze lib/domain/queries/` shows no errors
- [ ] All tests still pass: `flutter test`

---

## 🤖 AI Assistant Instructions

### Context Required

Attach or reference these files:
- `lib/domain/queries/` directory (or note that it needs to be created)
- Existing `comparison_operator.dart` if any (check current location)

### Implementation Checklist

1. [ ] Create `lib/domain/queries/` directory
2. [ ] Create `field_ref.dart` with `FieldRef<E,T>` class
3. [ ] Create `comparison_operator.dart` with enums
4. [ ] Create `queries.dart` barrel export
5. [ ] Verify no analyzer errors

### Key Prompts

**Prompt 1 - Create Foundation Files:**
> Create the foundation types for the UPA migration:
> 1. `lib/domain/queries/field_ref.dart` - FieldRef<E,T> class with name, columnName, accessor, isNullable
> 2. `lib/domain/queries/comparison_operator.dart` - ComparisonOperator and LogicalOperator enums
> 3. `lib/domain/queries/queries.dart` - barrel export
>
> Use `@immutable` annotations, `const` constructors, and follow Pattern 3 (hand-written, no freezed).

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| `@freezed` on these classes | Use `@immutable` + `final class` |
| Running build_runner | Assume watch mode is running |
| Mutable fields | All fields `final` |
| Missing const constructor | `const FieldRef({...})` |
| Missing equality | Override `==` and `hashCode` |

### Verification Questions

After completion, verify:
1. Can you create a `const FieldRef`? (Should work)
2. Does `flutter analyze lib/domain/queries/` pass?
3. Is `ComparisonOperator.equals.sqlOperator` equal to `'='`?
4. Do existing tests still pass?

---

## Files to Create

```
lib/domain/queries/
├── field_ref.dart           # NEW
├── comparison_operator.dart # NEW  
└── queries.dart             # NEW (barrel)
```

---

## Next Phase

→ [Phase 1: Field Definitions](./02_PHASE_1_FIELDS.md)
