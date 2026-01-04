# Phase 2: Unified Predicate Hierarchy

**Duration**: 1 day  
**Risk**: 🟡 Medium  
**Dependencies**: Phase 1 (Field definitions exist)

---

## Objectives

1. Create unified `Predicate<E>` sealed class hierarchy
2. Implement typed predicate subtypes (Bool, Date, String, Numeric, Null)
3. Implement compound predicates (And, Or, Not)
4. Preserve JSON serialization format for backward compatibility

---

## Deliverables

| File | Description |
|------|-------------|
| `lib/domain/queries/predicates/predicate.dart` | Base sealed class |
| `lib/domain/queries/predicates/bool_predicate.dart` | Boolean comparisons |
| `lib/domain/queries/predicates/date_predicate.dart` | Date comparisons |
| `lib/domain/queries/predicates/string_predicate.dart` | String comparisons |
| `lib/domain/queries/predicates/numeric_predicate.dart` | Numeric comparisons |
| `lib/domain/queries/predicates/null_predicate.dart` | Null checks |
| `lib/domain/queries/predicates/compound_predicate.dart` | And/Or/Not |
| `lib/domain/queries/predicates/predicates.dart` | Barrel export |

---

## Implementation Details

### 1. Base Predicate Class

```dart
// lib/domain/queries/predicates/predicate.dart
import 'package:meta/meta.dart';
import '../field_ref.dart';
import '../comparison_operator.dart';

/// Base class for all predicates on entity type [E].
/// 
/// Predicates define filtering criteria that can be:
/// - Serialized to JSON for persistence
/// - Converted to SQL for database queries
/// - Evaluated in memory for client-side filtering
@immutable
sealed class Predicate<E> {
  const Predicate();

  /// Serialize this predicate to JSON.
  /// Format must be backward compatible with existing predicates.
  Map<String, dynamic> toJson();

  /// Deserialize a predicate from JSON.
  /// 
  /// The [fieldResolver] function maps field names to FieldRef objects.
  static Predicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String name) fieldResolver,
  ) {
    final type = json['type'] as String;
    
    switch (type) {
      case 'bool':
        return BoolPredicate.fromJson(json, fieldResolver) as Predicate<E>;
      case 'date':
        return DatePredicate.fromJson(json, fieldResolver) as Predicate<E>;
      case 'string':
        return StringPredicate.fromJson(json, fieldResolver) as Predicate<E>;
      case 'numeric':
        return NumericPredicate.fromJson(json, fieldResolver) as Predicate<E>;
      case 'null':
        return NullPredicate.fromJson(json, fieldResolver) as Predicate<E>;
      case 'and':
        return AndPredicate.fromJson(json, fieldResolver) as Predicate<E>;
      case 'or':
        return OrPredicate.fromJson(json, fieldResolver) as Predicate<E>;
      case 'not':
        return NotPredicate.fromJson(json, fieldResolver) as Predicate<E>;
      default:
        throw ArgumentError('Unknown predicate type: $type');
    }
  }
}
```

### 2. BoolPredicate

```dart
// lib/domain/queries/predicates/bool_predicate.dart
import 'package:meta/meta.dart';
import '../field_ref.dart';
import '../comparison_operator.dart';
import 'predicate.dart';

/// Predicate for boolean field comparisons.
@immutable
final class BoolPredicate<E> extends Predicate<E> {
  const BoolPredicate({
    required this.field,
    required this.operator,
    required this.value,
  });

  final FieldRef<E, bool> field;
  final ComparisonOperator operator;
  final bool value;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'bool',
    'field': field.name,
    'operator': operator.toJson(),
    'value': value,
  };

  static BoolPredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final fieldName = json['field'] as String;
    final field = fieldResolver(fieldName);
    if (field == null) {
      throw ArgumentError('Unknown field: $fieldName');
    }
    
    return BoolPredicate<E>(
      field: field as FieldRef<E, bool>,
      operator: ComparisonOperator.fromJson(json['operator'] as String),
      value: json['value'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoolPredicate<E> &&
          field == other.field &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(field, operator, value);
}
```

### 3. DatePredicate

```dart
// lib/domain/queries/predicates/date_predicate.dart
import 'package:meta/meta.dart';
import '../field_ref.dart';
import '../comparison_operator.dart';
import 'predicate.dart';

/// Predicate for date field comparisons.
/// 
/// Supports both absolute dates and relative dates (today, this week, etc.)
@immutable
final class DatePredicate<E> extends Predicate<E> {
  const DatePredicate({
    required this.field,
    required this.operator,
    this.value,
    this.relativeDate,
  }) : assert(
         value != null || relativeDate != null,
         'Either value or relativeDate must be provided',
       );

  final FieldRef<E, DateTime?> field;
  final ComparisonOperator operator;
  final DateTime? value;
  final RelativeDate? relativeDate;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'date',
    'field': field.name,
    'operator': operator.toJson(),
    if (value != null) 'value': value!.toIso8601String(),
    if (relativeDate != null) 'relativeDate': relativeDate!.toJson(),
  };

  static DatePredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final fieldName = json['field'] as String;
    final field = fieldResolver(fieldName);
    if (field == null) {
      throw ArgumentError('Unknown field: $fieldName');
    }
    
    return DatePredicate<E>(
      field: field as FieldRef<E, DateTime?>,
      operator: ComparisonOperator.fromJson(json['operator'] as String),
      value: json['value'] != null 
          ? DateTime.parse(json['value'] as String) 
          : null,
      relativeDate: json['relativeDate'] != null
          ? RelativeDate.fromJson(json['relativeDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatePredicate<E> &&
          field == other.field &&
          operator == other.operator &&
          value == other.value &&
          relativeDate == other.relativeDate;

  @override
  int get hashCode => Object.hash(field, operator, value, relativeDate);
}

/// Relative date references for dynamic date predicates.
enum RelativeDate {
  today,
  tomorrow,
  yesterday,
  thisWeek,
  nextWeek,
  lastWeek,
  thisMonth,
  nextMonth,
  lastMonth;

  static RelativeDate fromJson(String value) {
    return RelativeDate.values.firstWhere(
      (rd) => rd.name == value,
      orElse: () => throw ArgumentError('Unknown relative date: $value'),
    );
  }

  String toJson() => name;

  /// Resolve to actual DateTime based on reference date.
  DateTime resolve([DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    return switch (this) {
      RelativeDate.today => DateTime(ref.year, ref.month, ref.day),
      RelativeDate.tomorrow => DateTime(ref.year, ref.month, ref.day + 1),
      RelativeDate.yesterday => DateTime(ref.year, ref.month, ref.day - 1),
      // Add more as needed
      _ => DateTime(ref.year, ref.month, ref.day),
    };
  }
}
```

### 4. StringPredicate

```dart
// lib/domain/queries/predicates/string_predicate.dart
import 'package:meta/meta.dart';
import '../field_ref.dart';
import '../comparison_operator.dart';
import 'predicate.dart';

/// Predicate for string field comparisons.
@immutable
final class StringPredicate<E> extends Predicate<E> {
  const StringPredicate({
    required this.field,
    required this.operator,
    required this.value,
    this.caseSensitive = false,
  });

  final FieldRef<E, String> field;
  final ComparisonOperator operator;
  final String value;
  final bool caseSensitive;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'string',
    'field': field.name,
    'operator': operator.toJson(),
    'value': value,
    'caseSensitive': caseSensitive,
  };

  static StringPredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final fieldName = json['field'] as String;
    final field = fieldResolver(fieldName);
    if (field == null) {
      throw ArgumentError('Unknown field: $fieldName');
    }
    
    return StringPredicate<E>(
      field: field as FieldRef<E, String>,
      operator: ComparisonOperator.fromJson(json['operator'] as String),
      value: json['value'] as String,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringPredicate<E> &&
          field == other.field &&
          operator == other.operator &&
          value == other.value &&
          caseSensitive == other.caseSensitive;

  @override
  int get hashCode => Object.hash(field, operator, value, caseSensitive);
}
```

### 5. NumericPredicate

```dart
// lib/domain/queries/predicates/numeric_predicate.dart
import 'package:meta/meta.dart';
import '../field_ref.dart';
import '../comparison_operator.dart';
import 'predicate.dart';

/// Predicate for numeric field comparisons (int, double).
@immutable
final class NumericPredicate<E> extends Predicate<E> {
  const NumericPredicate({
    required this.field,
    required this.operator,
    required this.value,
  });

  final FieldRef<E, num> field;
  final ComparisonOperator operator;
  final num value;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'numeric',
    'field': field.name,
    'operator': operator.toJson(),
    'value': value,
  };

  static NumericPredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final fieldName = json['field'] as String;
    final field = fieldResolver(fieldName);
    if (field == null) {
      throw ArgumentError('Unknown field: $fieldName');
    }
    
    return NumericPredicate<E>(
      field: field as FieldRef<E, num>,
      operator: ComparisonOperator.fromJson(json['operator'] as String),
      value: json['value'] as num,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumericPredicate<E> &&
          field == other.field &&
          operator == other.operator &&
          value == other.value;

  @override
  int get hashCode => Object.hash(field, operator, value);
}
```

### 6. NullPredicate

```dart
// lib/domain/queries/predicates/null_predicate.dart
import 'package:meta/meta.dart';
import '../field_ref.dart';
import '../comparison_operator.dart';
import 'predicate.dart';

/// Predicate for null/not-null checks on nullable fields.
@immutable
final class NullPredicate<E> extends Predicate<E> {
  const NullPredicate({
    required this.field,
    required this.isNull,
  });

  final FieldRef<E, Object?> field;
  final bool isNull;

  ComparisonOperator get operator => 
      isNull ? ComparisonOperator.isNull : ComparisonOperator.isNotNull;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'null',
    'field': field.name,
    'isNull': isNull,
  };

  static NullPredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final fieldName = json['field'] as String;
    final field = fieldResolver(fieldName);
    if (field == null) {
      throw ArgumentError('Unknown field: $fieldName');
    }
    
    return NullPredicate<E>(
      field: field as FieldRef<E, Object?>,
      isNull: json['isNull'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NullPredicate<E> &&
          field == other.field &&
          isNull == other.isNull;

  @override
  int get hashCode => Object.hash(field, isNull);
}
```

### 7. Compound Predicates

```dart
// lib/domain/queries/predicates/compound_predicate.dart
import 'package:meta/meta.dart';
import '../field_ref.dart';
import 'predicate.dart';

/// Combines predicates with AND logic (all must match).
@immutable
final class AndPredicate<E> extends Predicate<E> {
  const AndPredicate(this.predicates);

  final List<Predicate<E>> predicates;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'and',
    'predicates': predicates.map((p) => p.toJson()).toList(),
  };

  static AndPredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final predicatesJson = json['predicates'] as List<dynamic>;
    return AndPredicate<E>(
      predicatesJson
          .cast<Map<String, dynamic>>()
          .map((p) => Predicate.fromJson<E>(p, fieldResolver))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AndPredicate<E> &&
          _listEquals(predicates, other.predicates);

  @override
  int get hashCode => Object.hashAll(predicates);
}

/// Combines predicates with OR logic (any must match).
@immutable
final class OrPredicate<E> extends Predicate<E> {
  const OrPredicate(this.predicates);

  final List<Predicate<E>> predicates;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'or',
    'predicates': predicates.map((p) => p.toJson()).toList(),
  };

  static OrPredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final predicatesJson = json['predicates'] as List<dynamic>;
    return OrPredicate<E>(
      predicatesJson
          .cast<Map<String, dynamic>>()
          .map((p) => Predicate.fromJson<E>(p, fieldResolver))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrPredicate<E> &&
          _listEquals(predicates, other.predicates);

  @override
  int get hashCode => Object.hashAll(predicates);
}

/// Negates a predicate (logical NOT).
@immutable
final class NotPredicate<E> extends Predicate<E> {
  const NotPredicate(this.predicate);

  final Predicate<E> predicate;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'not',
    'predicate': predicate.toJson(),
  };

  static NotPredicate<E> fromJson<E>(
    Map<String, dynamic> json,
    FieldRef<E, dynamic>? Function(String) fieldResolver,
  ) {
    final predicateJson = json['predicate'] as Map<String, dynamic>;
    return NotPredicate<E>(
      Predicate.fromJson<E>(predicateJson, fieldResolver),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotPredicate<E> && predicate == other.predicate;

  @override
  int get hashCode => predicate.hashCode;
}

// Helper for list equality
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

### 8. Barrel Export

```dart
// lib/domain/queries/predicates/predicates.dart
export 'predicate.dart';
export 'bool_predicate.dart';
export 'date_predicate.dart';
export 'string_predicate.dart';
export 'numeric_predicate.dart';
export 'null_predicate.dart';
export 'compound_predicate.dart';
```

---

## ✅ Verification Checklist

- [ ] All predicate files compile without errors
- [ ] `Predicate<Task>` can be created with `TaskFields`
- [ ] JSON serialization round-trips correctly
- [ ] JSON format matches existing predicate format
- [ ] Compound predicates can be nested
- [ ] `flutter analyze lib/domain/queries/predicates/` shows no errors
- [ ] All existing tests still pass

---

## 🤖 AI Assistant Instructions

### Context Required

Attach or reference these files:
- `lib/domain/queries/field_ref.dart` (from Phase 0)
- `lib/domain/queries/fields/task_fields.dart` (from Phase 1)
- `lib/domain/predicates/task_predicate.dart` (existing - for JSON format reference)

### Implementation Checklist

1. [ ] Create `lib/domain/queries/predicates/` directory
2. [ ] Create `predicate.dart` with base sealed class
3. [ ] Create `bool_predicate.dart`
4. [ ] Create `date_predicate.dart` with `RelativeDate` enum
5. [ ] Create `string_predicate.dart`
6. [ ] Create `numeric_predicate.dart`
7. [ ] Create `null_predicate.dart`
8. [ ] Create `compound_predicate.dart` (And/Or/Not)
9. [ ] Create `predicates.dart` barrel export
10. [ ] Update `queries.dart` to export predicates

### Key Prompts

**Prompt 1 - Create Base Predicate:**
> Create `lib/domain/queries/predicates/predicate.dart` with:
> - `@immutable sealed class Predicate<E>` base class
> - Abstract `toJson()` method
> - Static `fromJson<E>()` factory with type dispatch
> - Import FieldRef from parent directory
>
> Follow Pattern 3 (hand-written sealed class, NO @freezed).

**Prompt 2 - Create All Predicates:**
> Create the predicate subtypes following this pattern:
> - Use `@immutable final class XPredicate<E> extends Predicate<E>`
> - Accept `FieldRef<E, T>` for typed field reference
> - Implement `toJson()` with `'type': 'x'` discriminator
> - Implement static `fromJson<E>()` factory
> - Override `==` and `hashCode`
>
> Create: bool, date, string, numeric, null predicates

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| `@freezed sealed class Predicate` | `@immutable sealed class Predicate` |
| `abstract class BoolPredicate` | `final class BoolPredicate` |
| Missing type parameter | Always use `<E>` type parameter |
| Non-const constructor | Use `const` where possible |
| Different JSON format | Match existing predicate JSON exactly |
| Missing equality | Override `==` and `hashCode` |

### JSON Format Compatibility

**CRITICAL**: The JSON format must be backward compatible:

```json
// Existing format (must be preserved)
{
  "type": "bool",
  "field": "isCompleted",
  "operator": "equals",
  "value": true
}

// NOT this format (would break existing data)
{
  "predicateType": "boolean",  // ❌ Wrong key
  "fieldName": "isCompleted",  // ❌ Wrong key
  "op": "=="                   // ❌ Wrong value
}
```

### Verification Questions

After completion, verify:
1. Does this compile?
   ```dart
   final p = BoolPredicate<Task>(
     field: TaskFields.isCompleted,
     operator: ComparisonOperator.equals,
     value: true,
   );
   ```
2. Does `p.toJson()` return `{'type': 'bool', 'field': 'isCompleted', ...}`?
3. Does `Predicate.fromJson<Task>(json, TaskFields.byName)` work?
4. Can you nest `AndPredicate([p1, p2])`?

---

## Files to Create

```
lib/domain/queries/predicates/
├── predicate.dart           # NEW - base sealed class
├── bool_predicate.dart      # NEW
├── date_predicate.dart      # NEW (includes RelativeDate)
├── string_predicate.dart    # NEW
├── numeric_predicate.dart   # NEW
├── null_predicate.dart      # NEW
├── compound_predicate.dart  # NEW (And/Or/Not)
└── predicates.dart          # NEW (barrel)
```

---

## Next Phase

→ [Phase 3: Unified Infrastructure](./04_PHASE_3_INFRASTRUCTURE.md)
