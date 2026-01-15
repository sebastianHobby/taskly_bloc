# Phase 03 — USM-005 (Option A): Identity value types

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Outcome
Reduce “stringly-typed identity” for:
- screen keys (`'my_day'` etc)
- section template IDs (`'task_list_v2'` etc)
- persistence keys (`'$screenKey:${section.templateId}:${section.index}'`)

Introduce small value types with centralized parsing/formatting. Adopt incrementally with minimal churn.

## AI instructions (required)
- Review architecture docs under `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.

## New value types
### 1) `ScreenKey`
- File: `lib/domain/screens/language/models/screen_key.dart`

Responsibilities:
- hold canonical screen key string (`my_day`, `scheduled`, etc)
- provide URL segment mapping helpers if useful (doc mentions hyphen ↔ underscore mapping)

Suggested API:
- `@immutable class ScreenKey {
    const ScreenKey(this.value);
    final String value;

    String toUrlSegment() => value.replaceAll('_', '-');
    static ScreenKey fromUrlSegment(String segment) => ScreenKey(segment.replaceAll('-', '_'));

    @override String toString() => value;
  }`

Adoption guideline:
- Do not immediately change routing signatures; add overloads/helpers and use internally.

### 2) `SectionTemplateIdValue`
- File: `lib/domain/screens/language/models/section_template_id_value.dart`

Responsibilities:
- wrap the existing canonical string IDs (still sourced from `SectionTemplateId` constants)
- eliminate accidental typos

Suggested API:
- `@immutable class SectionTemplateIdValue {
    const SectionTemplateIdValue(this.value);
    final String value;

    // canonical factories
    static const taskListV2 = SectionTemplateIdValue(SectionTemplateId.taskListV2);
    ...
  }`

Rule:
- This is a wrapper, not a second source of truth. It should reuse `SectionTemplateId.*` constants to avoid drift.

### 3) `SectionPersistenceKey`
- File: `lib/domain/screens/runtime/section_persistence_key.dart`

Responsibilities:
- stable, centralized persistence key format
- avoid ad-hoc string interpolation scattered across templates/renderers

Suggested API:
- `@immutable class SectionPersistenceKey {
    const SectionPersistenceKey._(this.value);
    final String value;

    factory SectionPersistenceKey.forSection({
      required ScreenKey screenKey,
      required SectionTemplateIdValue templateId,
      required int sectionIndex,
    }) {
      return SectionPersistenceKey._('${screenKey.value}:${templateId.value}:$sectionIndex');
    }
  }`

## Mechanical adoption steps
1) Add the new value-type classes (domain folders).
2) Start with the *lowest churn* adoption points:
  - persistence key generation
  - URL segment conversion helpers (if needed)

Avoid mechanically changing every `screenKey == '...'` comparison in one sweep.

Preferred incremental pattern:
- Use value types first at *construction sites*:
  - persistence key generation in `ScreenTemplateWidget`
  - persistence key generation in any renderer that uses PageStorage

3) Update persistence key creation:
   - `'$screenKey:${section.templateId}:${section.index}'` → `SectionPersistenceKey.forSection(...).value`

4) Keep public models stable until Phase 04:
   - `SectionVm.templateId` can remain `String` for now.
   - later convert to `SectionTemplateIdValue` in the sealed `SectionVm` refactor.

## Verification checklist
- Persistence keys are generated via a single helper (no duplicated formats).
- No new string constants for template IDs are introduced.
- `flutter analyze` passes.

## Doc updates
Update [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md) to mention:
- value types exist (even if adoption is incremental)
- recommended usage for persistence keys.
