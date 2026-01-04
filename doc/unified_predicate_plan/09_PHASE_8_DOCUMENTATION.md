# Phase 8: Documentation

**Duration**: 0.5 days  
**Risk**: 🟢 Low  
**Dependencies**: Phase 7 (Cleanup complete)

---

## Objectives

1. Document the new predicate architecture
2. Add API documentation to all new classes
3. Create usage guide with examples
4. Update architecture documentation

---

## Deliverables

| File | Description |
|------|-------------|
| `lib/domain/queries/README.md` | Usage guide |
| Updated dartdoc comments | API documentation |
| `doc/ARCHITECTURE_DECISIONS.md` | Updated architecture docs |

---

## Documentation Content

### 1. README.md

```markdown
# Unified Query System

This directory contains the unified predicate-based query system for filtering
entities in Taskly.

## Overview

The query system uses typed predicates with compile-time field safety:

```dart
// Create a query for incomplete, non-trashed tasks
final query = TaskQuery(
  filter: AndPredicate([
    BoolPredicate(
      field: TaskFields.isCompleted,
      operator: ComparisonOperator.equals,
      value: false,
    ),
    BoolPredicate(
      field: TaskFields.isTrashed,
      operator: ComparisonOperator.equals,
      value: false,
    ),
  ]),
  sortBy: TaskSortField.dueDate,
  sortDirection: SortDirection.ascending,
);
```

## Architecture

```
queries/
├── field_ref.dart           # FieldRef<E,T> - typed field reference
├── comparison_operator.dart # Comparison and logical operators
├── fields/
│   ├── task_fields.dart     # TaskFields.* constants
│   ├── project_fields.dart  # ProjectFields.* constants
│   └── journal_fields.dart  # JournalFields.* constants
├── predicates/
│   ├── predicate.dart       # Predicate<E> sealed base
│   ├── bool_predicate.dart  # Boolean comparisons
│   ├── date_predicate.dart  # Date comparisons
│   ├── string_predicate.dart# String comparisons
│   ├── numeric_predicate.dart# Numeric comparisons
│   ├── null_predicate.dart  # Null checks
│   └── compound_predicate.dart # And/Or/Not
└── [entity]_query.dart      # Query classes with pagination/sorting
```

## Usage Examples

### Simple Boolean Filter

```dart
// Tasks that are completed
final completed = BoolPredicate<Task>(
  field: TaskFields.isCompleted,
  operator: ComparisonOperator.equals,
  value: true,
);
```

### Date Range Filter

```dart
// Tasks due before a specific date
final dueSoon = DatePredicate<Task>(
  field: TaskFields.dueDate,
  operator: ComparisonOperator.lessThanOrEqual,
  value: DateTime.now().add(Duration(days: 7)),
);
```

### Compound Filters

```dart
// Active tasks (not completed, not trashed, has due date)
final active = AndPredicate<Task>([
  BoolPredicate(field: TaskFields.isCompleted, operator: ComparisonOperator.equals, value: false),
  BoolPredicate(field: TaskFields.isTrashed, operator: ComparisonOperator.equals, value: false),
  NullPredicate(field: TaskFields.dueDate, isNull: false),
]);
```

### String Search

```dart
// Tasks with "meeting" in the title
final meetings = StringPredicate<Task>(
  field: TaskFields.title,
  operator: ComparisonOperator.contains,
  value: 'meeting',
  caseSensitive: false,
);
```

## Type Safety

The `FieldRef<E,T>` system ensures compile-time type checking:

```dart
// ✅ Compiles - isCompleted is bool
BoolPredicate<Task>(field: TaskFields.isCompleted, ...)

// ❌ Compile error - dueDate is DateTime?, not bool
BoolPredicate<Task>(field: TaskFields.dueDate, ...)  // Type error!
```

## JSON Serialization

Predicates serialize to JSON for persistence:

```dart
final predicate = BoolPredicate<Task>(...);
final json = predicate.toJson();
// {"type": "bool", "field": "isCompleted", "operator": "equals", "value": true}

final restored = Predicate.fromJson<Task>(json, TaskFields.byName);
```

## Adding New Fields

To add a new field to an entity:

1. Add field to entity class
2. Add `FieldRef` constant to `*Fields` class
3. Add to `all` map for JSON deserialization
4. Add private accessor function

```dart
// In task_fields.dart
static const newField = FieldRef<Task, String>(
  name: 'newField',
  columnName: 'new_field',
  accessor: _getNewField,
);

static const Map<String, FieldRef<Task, dynamic>> all = {
  // ...existing fields...
  'newField': newField,
};

static String _getNewField(Task t) => t.newField;
```

## Adding New Entity Types

To add predicates for a new entity (e.g., `Note`):

1. Create `note_fields.dart` with `NoteFields` class
2. Create `NotePredicateConverter` for JSON
3. Create `NoteQuery` class with `filter` field
4. Add to `UnifiedPredicateMapper` if needed
5. Add to `FilterEvaluator` if needed

Estimated effort: ~300-400 lines (vs ~1300 with old system).
```

### 2. API Documentation

Add dartdoc to all public APIs:

```dart
/// A typed reference to a field on entity type [E] with value type [T].
/// 
/// Used for compile-time type safety in predicate construction.
/// The [columnName] is used for SQL generation, while [accessor]
/// is used for in-memory filtering.
/// 
/// Example:
/// ```dart
/// static const isCompleted = FieldRef<Task, bool>(
///   name: 'isCompleted',
///   columnName: 'is_completed',
///   accessor: _getIsCompleted,
/// );
/// ```
@immutable
final class FieldRef<E, T> { ... }
```

```dart
/// Base class for all predicates on entity type [E].
/// 
/// Predicates define filtering criteria that can be:
/// - Serialized to JSON for persistence
/// - Converted to SQL for database queries
/// - Evaluated in memory for client-side filtering
/// 
/// ## Predicate Types
/// 
/// - [BoolPredicate] - Boolean field comparisons
/// - [DatePredicate] - Date/time comparisons
/// - [StringPredicate] - String comparisons with case sensitivity
/// - [NumericPredicate] - Numeric comparisons
/// - [NullPredicate] - Null/not-null checks
/// - [AndPredicate] - Logical AND combination
/// - [OrPredicate] - Logical OR combination
/// - [NotPredicate] - Logical NOT negation
/// 
/// ## Example
/// 
/// ```dart
/// final filter = AndPredicate<Task>([
///   BoolPredicate(
///     field: TaskFields.isCompleted,
///     operator: ComparisonOperator.equals,
///     value: false,
///   ),
///   DatePredicate(
///     field: TaskFields.dueDate,
///     operator: ComparisonOperator.lessThanOrEqual,
///     value: DateTime.now(),
///   ),
/// ]);
/// ```
@immutable
sealed class Predicate<E> { ... }
```

### 3. Architecture Decision Record

Update `doc/ARCHITECTURE_DECISIONS.md`:

```markdown
## ADR-XXX: Unified Predicate Architecture

### Status
Accepted

### Context
The codebase had duplicate predicate hierarchies for each entity type
(Task, Project, JournalEntry), resulting in ~90% code duplication.
Adding a new entity required copying ~1,300 lines of boilerplate.

### Decision
Implement a unified generic predicate system using typed `FieldRef<E,T>`
objects for compile-time field safety while sharing predicate logic.

### Consequences

**Positive:**
- ~993 lines reduced (16% overall)
- New entity cost: ~355 lines vs ~1,300
- Single source of truth for predicate logic
- Compile-time type safety preserved
- IDE autocomplete works (`TaskFields.`)

**Negative:**
- Learning curve for new pattern
- One-time migration effort (~5-7 days)
- Slightly more complex generic types

### Implementation
See `lib/domain/queries/` for implementation.
See `doc/unified_predicate_plan/` for migration plan.
```

---

## Step-by-Step Implementation

### Step 1: Create README

Create `lib/domain/queries/README.md` with usage guide.

### Step 2: Add Dartdoc Comments

Review and enhance documentation for:
- `FieldRef`
- `Predicate` and subtypes
- `ComparisonOperator`
- `TaskFields`, `ProjectFields`, `JournalFields`
- `UnifiedPredicateMapper`
- `FilterEvaluator`

### Step 3: Update Architecture Docs

Add ADR to `doc/ARCHITECTURE_DECISIONS.md`.

### Step 4: Generate API Docs

```bash
dart doc .
```

### Step 5: Review and Polish

Read through all documentation for clarity and accuracy.

---

## ✅ Verification Checklist

- [ ] README.md exists with examples
- [ ] All public classes have dartdoc
- [ ] Examples in docs compile correctly
- [ ] Architecture decision documented
- [ ] `dart doc` generates without warnings
- [ ] Documentation is accurate and helpful

---

## 🤖 AI Assistant Instructions

### Context Required

- Completed implementation files from previous phases
- Existing documentation style in codebase
- `doc/ARCHITECTURE_DECISIONS.md` format

### Implementation Checklist

1. [ ] Create `lib/domain/queries/README.md`
2. [ ] Add dartdoc to `FieldRef` class
3. [ ] Add dartdoc to `Predicate` sealed class
4. [ ] Add dartdoc to each predicate subtype
5. [ ] Add dartdoc to `ComparisonOperator`
6. [ ] Add dartdoc to `*Fields` classes
7. [ ] Add dartdoc to `UnifiedPredicateMapper`
8. [ ] Add dartdoc to `FilterEvaluator`
9. [ ] Update `ARCHITECTURE_DECISIONS.md`
10. [ ] Run `dart doc` to verify

### Key Prompts

**Prompt 1 - Create README:**
> Create `lib/domain/queries/README.md` documenting:
> 1. Overview of the predicate system
> 2. Directory structure explanation
> 3. Usage examples for each predicate type
> 4. Type safety explanation
> 5. JSON serialization format
> 6. Guide for adding new fields/entities
>
> Use code examples that compile correctly.

**Prompt 2 - Add Dartdoc:**
> Add comprehensive dartdoc comments to `lib/domain/queries/predicates/predicate.dart`:
> 1. Class-level documentation with overview
> 2. List all predicate subtypes
> 3. Example usage with code block
> 4. Document `toJson()` and `fromJson()` methods
>
> Follow Effective Dart documentation guidelines.

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| Non-compiling code examples | Test examples before including |
| Missing dartdoc on public APIs | Document all public members |
| Outdated information | Verify against current implementation |
| Overly complex examples | Start simple, build up |

### Documentation Quality Checklist

For each public class/method:
- [ ] Has summary sentence
- [ ] Purpose is clear
- [ ] Has code example if complex
- [ ] Parameters documented
- [ ] Return value documented
- [ ] Throws clauses documented

### Verification Questions

After completion, verify:
1. Does `dart doc .` complete without warnings?
2. Are code examples accurate and working?
3. Can a new developer understand the system from docs?
4. Is the architecture decision recorded?

---

## Files to Create/Modify

```
lib/domain/queries/
├── README.md              # NEW
├── field_ref.dart         # ADD dartdoc
├── comparison_operator.dart # ADD dartdoc
├── fields/
│   ├── task_fields.dart   # ADD dartdoc
│   ├── project_fields.dart # ADD dartdoc
│   └── journal_fields.dart # ADD dartdoc
├── predicates/
│   ├── predicate.dart     # ADD dartdoc
│   ├── bool_predicate.dart # ADD dartdoc
│   └── ...                # ADD dartdoc to all

doc/
└── ARCHITECTURE_DECISIONS.md # UPDATE
```

---

## Migration Complete! 🎉

After completing this phase:

1. **Merge PR** - Merge the feature branch
2. **Announce** - Inform team of new query system
3. **Monitor** - Watch for issues in production
4. **Celebrate** - You've reduced ~1000 lines of duplicate code!

### Final Statistics

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Total predicate code | ~1,800 lines | ~800 lines | -55% |
| New entity cost | ~1,300 lines | ~355 lines | -73% |
| Mapper files | 3 | 1 | -67% |
| Evaluator files | 2 | 1 | -50% |

### Next Steps

Consider these future improvements:
1. Add more predicate types (In, Between)
2. Add query builder fluent API
3. Add predicate validation
4. Add query caching based on predicate hash
