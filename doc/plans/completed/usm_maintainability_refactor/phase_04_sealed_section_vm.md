# Phase 04 — USM-003 (Option A): Sealed `SectionVm` hierarchy

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15 (UTC)

Completed at: 2026-01-15 (UTC)

## Completed summary
- Replaced the old stringly-typed `SectionVm` with a Freezed sealed union carrying typed params and `SectionDataResult?`.
- Updated the domain module interpreter registry and presentation renderer registry to switch on `SectionVm` variants (removing template-id casting).

## Outcome
Replace the current loosely-typed `SectionVm`:
- `templateId: String`
- `params: Object`
- `data: Object?`

with a sealed hierarchy where each section VM carries typed params and typed data.

This eliminates widespread casting in `SectionWidget` and makes the “contract per template” explicit.

## AI instructions (required)
- Review architecture docs under `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.

## Proposed model
### Location
- Replace file: `lib/domain/screens/runtime/section_vm.dart`

### Base type
- `sealed class SectionVm { const SectionVm(); int get index; SectionTemplateIdValue get templateId; String? get title; DisplayConfig? get displayConfig; bool get isLoading; String? get error; }`

Add shared base implementation if needed:
- `abstract base class SectionVmBase implements SectionVm` with common fields.

### Variants (initial set)
Define VM variants for the templates that are actually used by the typed USM system screens today.

Avoid adding unused variants “just in case”; prefer adding them when you add a template/module.

1) Task list
- `final class TaskListV2SectionVm extends SectionVmBase {
    const TaskListV2SectionVm({ required int index, required ListSectionParamsV2 params, required DataV2SectionResult data, ... });
    final ListSectionParamsV2 params;
    final DataV2SectionResult data;
  }`

2) Value list
- `ValueListV2SectionVm` (same shape as task list)

3) Interleaved list
- `InterleavedListV2SectionVm` (params: `InterleavedListSectionParamsV2`, data: `DataV2SectionResult`)

4) Hierarchy
- `HierarchyValueProjectTaskV2SectionVm` (params: `HierarchyValueProjectTaskSectionParamsV2`, data: `HierarchyValueProjectTaskV2SectionResult`)

5) Agenda
- `AgendaV2SectionVm` (params: `AgendaSectionParamsV2`, data: `AgendaSectionResult`)

6) Attention banner
- `AttentionBannerV2SectionVm` (params type per interpreter, data: `AttentionBannerV2SectionResult`)

7) Attention inbox
- `AttentionInboxV1SectionVm` (this one currently renders without `data`, using params only)

8) Entity header
- `EntityHeaderSectionVm` (data: `EntityHeader*SectionResult`, params type per module)

9) Unknown / error
- `UnknownSectionVm` (keeps forward compatibility; used when registry misses a mapping)

### Migration rule
- For each module interpreter mapping, emit the correct typed VM variant.
- Presentation renderers switch on VM type (sealed pattern match) rather than checking `templateId` + casting `params/data`.

## Mechanical migration steps
1) Introduce `SectionTemplateIdValue` usage for `SectionVm.templateId`.
   - This may require updating registries and interpreters to emit value types.

2) Update domain module interpreter registry (Phase 02 artifact):
   - `ScreenModuleInterpreterRegistryImpl.watch(...)` should now emit the right VM variant.
   - Replace code that builds `SectionVm(index:..., templateId:..., params:..., data:...)` with the correct class.

3) Update `SlottedSectionVms` and `ScreenSpecData` types if needed.

4) Update presentation renderer registry (Phase 02 artifact):
   - Renderer selection can be:
     - by `SectionTemplateIdValue`, or
     - by VM runtime type.

Pick whichever produces the smallest diff in this repo.

Recommended approach:
- Keep registry keyed by `SectionTemplateIdValue` but inside renderer, pattern-match on the VM type.
- Alternatively, registry can be keyed by `Type` (VM runtimeType).

5) Refactor [lib/presentation/widgets/section_widget.dart](../../../lib/presentation/widgets/section_widget.dart):
   - remove all casting of `section.params` and `section.data`.
   - switch on VM subtype.

6) Update any other call sites that use `SectionVm.copyWith`.
   - The existing `copyWith` is used for filtering in `_filterPrimarySectionsByCompletion` in `ScreenTemplateWidget`.
   - Replace with a VM-specific transformation:
     - If the filter applies only to `DataV2SectionResult` sections, handle only VMs that carry `DataV2SectionResult`.
     - Provide a `copyWithData(...)` method on the affected VM types OR recreate a new instance.

Mechanical pattern for filtering (example):
- `switch (sectionVm) {
    case TaskListV2SectionVm(:final data, :final params, ...):
      final filtered = data.copyWith(items: filteredItems);
      return TaskListV2SectionVm(..., data: filtered);
    case InterleavedListV2SectionVm(...): ...
    default: return sectionVm;
  }`

## Verification checklist
- No `as SomeParamsType` casts remain in `SectionWidget`.
- Adding a new template requires:
  - add VM variant
  - add domain registry mapping
  - add renderer mapping
- `flutter analyze` passes.

## Doc updates
Update [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md):
- replace `SectionVm (with templateId)` description with “sealed `SectionVm` variants per template”.
