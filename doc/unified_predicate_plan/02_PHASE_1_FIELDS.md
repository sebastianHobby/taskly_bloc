# Phase 1: Field Definitions

**Duration**: 0.5 days  
**Risk**: 🟢 Low  
**Dependencies**: Phase 0 (FieldRef exists)

---

## Objectives

1. Create `TaskFields` - typed field references for Task entity
2. Create `ProjectFields` - typed field references for Project entity
3. Create `JournalFields` - typed field references for JournalEntry entity
4. Verify IDE autocomplete works correctly

---

## Deliverables

| File | Description |
|------|-------------|
| `lib/domain/queries/fields/task_fields.dart` | Task entity field refs |
| `lib/domain/queries/fields/project_fields.dart` | Project entity field refs |
| `lib/domain/queries/fields/journal_fields.dart` | JournalEntry field refs |
| `lib/domain/queries/fields/fields.dart` | Barrel export |

---

## Implementation Details

### 1. TaskFields

```dart
// lib/domain/queries/fields/task_fields.dart
import '../field_ref.dart';
import '../../entities/task.dart';

/// Typed field references for [Task] entity.
/// 
/// Usage:
/// ```dart
/// final predicate = BoolPredicate(
///   field: TaskFields.isCompleted,
///   operator: ComparisonOperator.equals,
///   value: true,
/// );
/// ```
abstract final class TaskFields {
  // Prevent instantiation
  TaskFields._();

  // === Boolean Fields ===
  static const isCompleted = FieldRef<Task, bool>(
    name: 'isCompleted',
    columnName: 'is_completed',
    accessor: _getIsCompleted,
  );

  static const isTrashed = FieldRef<Task, bool>(
    name: 'isTrashed',
    columnName: 'is_trashed',
    accessor: _getIsTrashed,
  );

  static const isRecurring = FieldRef<Task, bool>(
    name: 'isRecurring',
    columnName: 'is_recurring',
    accessor: _getIsRecurring,
  );

  static const isPinned = FieldRef<Task, bool>(
    name: 'isPinned',
    columnName: 'is_pinned',
    accessor: _getIsPinned,
  );

  // === Date Fields ===
  static const startDate = FieldRef<Task, DateTime?>(
    name: 'startDate',
    columnName: 'start_date',
    accessor: _getStartDate,
    isNullable: true,
  );

  static const dueDate = FieldRef<Task, DateTime?>(
    name: 'dueDate',
    columnName: 'due_date',
    accessor: _getDueDate,
    isNullable: true,
  );

  static const completedAt = FieldRef<Task, DateTime?>(
    name: 'completedAt',
    columnName: 'completed_at',
    accessor: _getCompletedAt,
    isNullable: true,
  );

  static const createdAt = FieldRef<Task, DateTime>(
    name: 'createdAt',
    columnName: 'created_at',
    accessor: _getCreatedAt,
  );

  // === String Fields ===
  static const id = FieldRef<Task, String>(
    name: 'id',
    columnName: 'id',
    accessor: _getId,
  );

  static const title = FieldRef<Task, String>(
    name: 'title',
    columnName: 'title',
    accessor: _getTitle,
  );

  static const projectId = FieldRef<Task, String?>(
    name: 'projectId',
    columnName: 'project_id',
    accessor: _getProjectId,
    isNullable: true,
  );

  // === Integer Fields ===
  static const priority = FieldRef<Task, int>(
    name: 'priority',
    columnName: 'priority',
    accessor: _getPriority,
  );

  // === Field Registry (for JSON deserialization) ===
  static const Map<String, FieldRef<Task, dynamic>> all = {
    'isCompleted': isCompleted,
    'isTrashed': isTrashed,
    'isRecurring': isRecurring,
    'isPinned': isPinned,
    'startDate': startDate,
    'dueDate': dueDate,
    'completedAt': completedAt,
    'createdAt': createdAt,
    'id': id,
    'title': title,
    'projectId': projectId,
    'priority': priority,
  };

  /// Lookup field by name (for JSON deserialization).
  static FieldRef<Task, dynamic>? byName(String name) => all[name];

  // === Private Accessors ===
  static bool _getIsCompleted(Task t) => t.isCompleted;
  static bool _getIsTrashed(Task t) => t.isTrashed;
  static bool _getIsRecurring(Task t) => t.isRecurring;
  static bool _getIsPinned(Task t) => t.isPinned;
  static DateTime? _getStartDate(Task t) => t.startDate;
  static DateTime? _getDueDate(Task t) => t.dueDate;
  static DateTime? _getCompletedAt(Task t) => t.completedAt;
  static DateTime _getCreatedAt(Task t) => t.createdAt;
  static String _getId(Task t) => t.id;
  static String _getTitle(Task t) => t.title;
  static String? _getProjectId(Task t) => t.projectId;
  static int _getPriority(Task t) => t.priority;
}
```

### 2. ProjectFields

```dart
// lib/domain/queries/fields/project_fields.dart
import '../field_ref.dart';
import '../../entities/project.dart';

/// Typed field references for [Project] entity.
abstract final class ProjectFields {
  ProjectFields._();

  // === Boolean Fields ===
  static const isArchived = FieldRef<Project, bool>(
    name: 'isArchived',
    columnName: 'is_archived',
    accessor: _getIsArchived,
  );

  static const isTrashed = FieldRef<Project, bool>(
    name: 'isTrashed',
    columnName: 'is_trashed',
    accessor: _getIsTrashed,
  );

  // === Date Fields ===
  static const createdAt = FieldRef<Project, DateTime>(
    name: 'createdAt',
    columnName: 'created_at',
    accessor: _getCreatedAt,
  );

  // === String Fields ===
  static const id = FieldRef<Project, String>(
    name: 'id',
    columnName: 'id',
    accessor: _getId,
  );

  static const name = FieldRef<Project, String>(
    name: 'name',
    columnName: 'name',
    accessor: _getName,
  );

  static const color = FieldRef<Project, String>(
    name: 'color',
    columnName: 'color',
    accessor: _getColor,
  );

  // === Field Registry ===
  static const Map<String, FieldRef<Project, dynamic>> all = {
    'isArchived': isArchived,
    'isTrashed': isTrashed,
    'createdAt': createdAt,
    'id': id,
    'name': name,
    'color': color,
  };

  static FieldRef<Project, dynamic>? byName(String name) => all[name];

  // === Private Accessors ===
  static bool _getIsArchived(Project p) => p.isArchived;
  static bool _getIsTrashed(Project p) => p.isTrashed;
  static DateTime _getCreatedAt(Project p) => p.createdAt;
  static String _getId(Project p) => p.id;
  static String _getName(Project p) => p.name;
  static String _getColor(Project p) => p.color;
}
```

### 3. JournalFields

```dart
// lib/domain/queries/fields/journal_fields.dart
import '../field_ref.dart';
import '../../entities/journal_entry.dart';

/// Typed field references for [JournalEntry] entity.
abstract final class JournalFields {
  JournalFields._();

  // === Date Fields ===
  static const date = FieldRef<JournalEntry, DateTime>(
    name: 'date',
    columnName: 'date',
    accessor: _getDate,
  );

  static const createdAt = FieldRef<JournalEntry, DateTime>(
    name: 'createdAt',
    columnName: 'created_at',
    accessor: _getCreatedAt,
  );

  // === String Fields ===
  static const id = FieldRef<JournalEntry, String>(
    name: 'id',
    columnName: 'id',
    accessor: _getId,
  );

  static const content = FieldRef<JournalEntry, String>(
    name: 'content',
    columnName: 'content',
    accessor: _getContent,
  );

  // === Field Registry ===
  static const Map<String, FieldRef<JournalEntry, dynamic>> all = {
    'date': date,
    'createdAt': createdAt,
    'id': id,
    'content': content,
  };

  static FieldRef<JournalEntry, dynamic>? byName(String name) => all[name];

  // === Private Accessors ===
  static DateTime _getDate(JournalEntry j) => j.date;
  static DateTime _getCreatedAt(JournalEntry j) => j.createdAt;
  static String _getId(JournalEntry j) => j.id;
  static String _getContent(JournalEntry j) => j.content;
}
```

### 4. Barrel Export

```dart
// lib/domain/queries/fields/fields.dart
export 'task_fields.dart';
export 'project_fields.dart';
export 'journal_fields.dart';
```

---

## Step-by-Step Implementation

### Step 1: Review Entity Definitions

Before creating fields, review the actual entity files:
- `lib/domain/entities/task.dart`
- `lib/domain/entities/project.dart`
- `lib/domain/entities/journal_entry.dart`

Ensure field names and types match exactly.

### Step 2: Create Fields Directory

```bash
mkdir lib/domain/queries/fields
```

### Step 3: Create TaskFields

Map all fields from Task entity to FieldRef constants.

### Step 4: Create ProjectFields

Map all fields from Project entity to FieldRef constants.

### Step 5: Create JournalFields

Map all fields from JournalEntry entity to FieldRef constants.

### Step 6: Create Barrel Export

Create `fields.dart` that exports all field files.

### Step 7: Update queries.dart Barrel

```dart
// lib/domain/queries/queries.dart
export 'comparison_operator.dart';
export 'field_ref.dart';
export 'fields/fields.dart';  // ADD THIS
```

---

## ✅ Verification Checklist

- [ ] `TaskFields` has all fields from Task entity
- [ ] `ProjectFields` has all fields from Project entity
- [ ] `JournalFields` has all fields from JournalEntry entity
- [ ] Each field has correct `columnName` (snake_case)
- [ ] Each field has correct `isNullable` flag
- [ ] IDE autocomplete shows fields when typing `TaskFields.`
- [ ] All accessor functions compile without error
- [ ] `flutter analyze lib/domain/queries/` shows no errors

---

## 🤖 AI Assistant Instructions

### Context Required

Attach or reference these files:
- `lib/domain/entities/task.dart` (for field names and types)
- `lib/domain/entities/project.dart`
- `lib/domain/entities/journal_entry.dart`
- `lib/domain/queries/field_ref.dart` (from Phase 0)

### Implementation Checklist

1. [ ] Read entity files to get exact field names/types
2. [ ] Create `lib/domain/queries/fields/` directory
3. [ ] Create `task_fields.dart` with all Task fields
4. [ ] Create `project_fields.dart` with all Project fields
5. [ ] Create `journal_fields.dart` with all JournalEntry fields
6. [ ] Create `fields.dart` barrel export
7. [ ] Update `queries.dart` to export fields
8. [ ] Verify autocomplete works

### Key Prompts

**Prompt 1 - Create TaskFields:**
> Based on the Task entity definition in `lib/domain/entities/task.dart`, create `lib/domain/queries/fields/task_fields.dart` following the UPA pattern:
> - Use `abstract final class TaskFields` (non-instantiable)
> - Create `static const` FieldRef for each entity field
> - Include `all` map and `byName` lookup method
> - Use private static accessor functions
> - Match column names to snake_case versions

**Prompt 2 - Create All Fields:**
> Create field definitions for Project and JournalEntry entities following the same pattern as TaskFields. Reference the entity files for exact field names and types.

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| `class TaskFields` | `abstract final class TaskFields` |
| `static final field = ...` | `static const field = ...` |
| Closures as accessors | Static function references |
| Missing fields from entity | Include ALL entity fields |
| Wrong column names | Use exact snake_case from DB schema |
| Wrong nullable flags | Check entity field types carefully |

### Anti-Pattern Examples

```dart
// ❌ WRONG: Using closure directly
static const dueDate = FieldRef<Task, DateTime?>(
  name: 'dueDate',
  columnName: 'due_date',
  accessor: (t) => t.dueDate,  // Closure can't be const!
);

// ✅ CORRECT: Using static function reference
static const dueDate = FieldRef<Task, DateTime?>(
  name: 'dueDate',
  columnName: 'due_date',
  accessor: _getDueDate,  // Function reference IS const
);
static DateTime? _getDueDate(Task t) => t.dueDate;
```

### Verification Questions

After completion, verify:
1. Does `TaskFields.startDate.columnName` equal `'start_date'`?
2. Does `TaskFields.byName('isCompleted')` return `TaskFields.isCompleted`?
3. Can you call `TaskFields.isCompleted.accessor(someTask)`?
4. Does typing `TaskFields.` in IDE show all field suggestions?

---

## Field Mapping Reference

Ensure these patterns are followed:

| Entity Field | FieldRef Name | Column Name | Type |
|-------------|---------------|-------------|------|
| `task.isCompleted` | `isCompleted` | `is_completed` | `bool` |
| `task.startDate` | `startDate` | `start_date` | `DateTime?` |
| `task.dueDate` | `dueDate` | `due_date` | `DateTime?` |
| `project.isArchived` | `isArchived` | `is_archived` | `bool` |

---

## Files to Create

```
lib/domain/queries/fields/
├── task_fields.dart      # NEW
├── project_fields.dart   # NEW
├── journal_fields.dart   # NEW
└── fields.dart           # NEW (barrel)
```

---

## Next Phase

→ [Phase 2: Unified Predicates](./03_PHASE_2_PREDICATES.md)
