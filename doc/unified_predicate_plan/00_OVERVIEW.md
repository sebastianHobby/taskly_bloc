# Unified Predicate Architecture (UPA) Migration Plan

## Overview

This plan migrates the codebase from entity-specific predicate hierarchies to a unified generic predicate system using typed FieldRef objects.

**Project Code**: UPA
**Duration**: 5-7 developer days
**Risk Level**: Medium
**Breaking Changes**: None (JSON format preserved)

---

## Problem Summary

| Problem | Current State | After UPA |
|---------|---------------|-----------|
| Duplicate predicate classes | 3 hierarchies (Task/Project/Journal) | 1 unified hierarchy |
| Duplicate SQL mappers | 3 mappers (~576 lines) | 1 mapper (~200 lines) |
| Duplicate evaluators | 2 evaluators (~179 lines) | 1 generic (~100 lines) |
| New entity cost | ~1,300 lines | ~355 lines |
| **Total affected code** | ~6,186 lines | ~5,193 lines (-16%) |

---

## Phase Overview

| Phase | Name | Duration | Risk | Dependencies |
|-------|------|----------|------|--------------|
| 0 | Foundation | 0.5 days | 🟢 Low | None |
| 1 | Field Definitions | 0.5 days | 🟢 Low | Phase 0 |
| 2 | Unified Predicates | 1 day | 🟡 Medium | Phase 1 |
| 3 | Unified Infrastructure | 1 day | 🟡 Medium | Phase 2 |
| 4 | Query Class Migration | 1 day | 🟡 Medium | Phase 3 |
| 5 | Repository Integration | 1 day | 🔴 High | Phase 4 |
| 6 | Test Migration | 1 day | 🟢 Low | Phase 5 |
| 7 | Cleanup & Deletion | 0.5 days | 🟢 Low | Phase 6 |
| 8 | Documentation | 0.5 days | 🟢 Low | Phase 7 |

---

## Timeline Visualization

```
Day 1  │ Phase 0 + Phase 1 (Foundation + Fields)
       │ ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
       │
Day 2  │ Phase 2 (Unified Predicates)
       │ ░░░░████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░
       │
Day 3  │ Phase 3 (Mapper + Evaluator)
       │ ░░░░░░░░░░░░████████░░░░░░░░░░░░░░░░░░░░
       │
Day 4  │ Phase 4 (Query Classes)
       │ ░░░░░░░░░░░░░░░░░░░░████████░░░░░░░░░░░░
       │
Day 5  │ Phase 5 (Repositories) ⚠️ CRITICAL
       │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████░░░░
       │
Day 6  │ Phase 6 (Tests)
       │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
       │
Day 7  │ Phase 7 + Phase 8 (Cleanup + Docs)
       │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
```

---

## Key Milestones

| Milestone | Phase | Verification |
|-----------|-------|--------------|
| 🏁 New predicate system compiles | 2 | `flutter analyze` passes |
| 🏁 Parity tests pass | 3 | Old vs new SQL identical |
| 🏁 All production code migrated | 5 | Integration tests pass |
| 🏁 Migration complete | 7 | Full test suite green |

---

## Rollback Points

| Point | Action | Impact |
|-------|--------|--------|
| Phase 0-3 | Delete new files | Zero production impact |
| Phase 4 | Revert query changes | New predicates remain usable |
| Phase 5 | Revert repository changes | Queries work with old predicates |
| Phase 6+ | Git revert entire branch | Full rollback |

---

## File Index

| File | Purpose |
|------|---------|
| [01_PHASE_0_FOUNDATION.md](./01_PHASE_0_FOUNDATION.md) | Branch setup, base classes |
| [02_PHASE_1_FIELDS.md](./02_PHASE_1_FIELDS.md) | Entity field definitions |
| [03_PHASE_2_PREDICATES.md](./03_PHASE_2_PREDICATES.md) | Unified predicate hierarchy |
| [04_PHASE_3_INFRASTRUCTURE.md](./04_PHASE_3_INFRASTRUCTURE.md) | Mapper and evaluator |
| [05_PHASE_4_QUERIES.md](./05_PHASE_4_QUERIES.md) | Query class migration |
| [06_PHASE_5_REPOSITORIES.md](./06_PHASE_5_REPOSITORIES.md) | Repository integration |
| [07_PHASE_6_TESTS.md](./07_PHASE_6_TESTS.md) | Test migration |
| [08_PHASE_7_CLEANUP.md](./08_PHASE_7_CLEANUP.md) | Deletion and cleanup |
| [09_PHASE_8_DOCUMENTATION.md](./09_PHASE_8_DOCUMENTATION.md) | Final documentation |

---

## Global AI Instructions

### Build Runner Assumption

**ALWAYS assume `build_runner` is running in watch mode.**

```bash
# This is ALREADY running in a terminal:
dart run build_runner watch --delete-conflicting-outputs
```

- ✅ DO: Create/modify files and wait for generation
- ✅ DO: Check for `.g.dart` / `.freezed.dart` files after changes
- ❌ DON'T: Run `build_runner build` manually
- ❌ DON'T: Suggest running build_runner commands

### Class Syntax Patterns

**This codebase uses specific patterns - follow exactly:**

#### Pattern 1: Freezed Union Types (Events/States)
```dart
// CORRECT - for union types with multiple factories
@freezed
sealed class TaskDetailEvent with _$TaskDetailEvent {
  const factory TaskDetailEvent.update(...) = _TaskDetailUpdate;
  const factory TaskDetailEvent.delete(...) = _TaskDetailDelete;
}
```

#### Pattern 2: Freezed Data Classes (Single Factory)
```dart
// CORRECT - for data classes with one factory
@freezed
abstract class AnalyticsSnapshot with _$AnalyticsSnapshot {
  const factory AnalyticsSnapshot({...}) = _AnalyticsSnapshot;
}
```

#### Pattern 3: Hand-Written Sealed Hierarchies (NO freezed)
```dart
// CORRECT - for predicates and similar (NO @freezed, NO build_runner)
@immutable
sealed class TaskPredicate {
  const TaskPredicate();
  Map<String, dynamic> toJson();
  static TaskPredicate fromJson(Map<String, dynamic> json) { ... }
}

@immutable
final class TaskBoolPredicate extends TaskPredicate {
  const TaskBoolPredicate({required this.field, required this.operator});
  // ...
}
```

### UPA Uses Pattern 3

**The new Predicate<E> hierarchy should use Pattern 3:**
- `@immutable` annotation
- `sealed class` for base
- `final class` for concrete types
- Hand-written `toJson`/`fromJson`
- NO `@freezed`, NO generated code

### Common Mistakes to Avoid

| ❌ Wrong | ✅ Correct |
|---------|-----------|
| `@freezed sealed class Predicate<E>` | `@immutable sealed class Predicate<E>` |
| `abstract class DatePredicate` | `final class DatePredicate` |
| Running `build_runner build` | Assume watch mode is running |
| `class TaskFields` | `abstract final class TaskFields` |
| `static final startDate = ...` | `static const startDate = ...` |
| Mutable FieldRef | Immutable FieldRef with const constructor |

---

## Quick Reference Commands

```bash
# Create feature branch
git checkout -b feature/upa-unified-predicates

# Run specific tests during migration
flutter test test/domain/queries/
flutter test test/data/repositories/mappers/

# Full verification
flutter test
flutter analyze

# Check for analyzer issues in new files
flutter analyze lib/domain/queries/
```

---

## Success Criteria

At migration completion:
- [ ] Net code reduction: ~993 lines
- [ ] All 210+ existing tests pass
- [ ] JSON serialization backward compatible
- [ ] No analyzer warnings
- [ ] IDE autocomplete works for `TaskFields.`
- [ ] Adding new entity requires only ~355 lines
