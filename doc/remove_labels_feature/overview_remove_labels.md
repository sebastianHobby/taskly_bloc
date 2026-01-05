# Remove Labels Feature Plan

This document outlines the comprehensive, phased plan to remove the "Label" concept from the Taskly codebase, consolidate everything into "Values", and introduce a `priority` field.

**Note:** This plan assumes a destructive database migration (user data will be cleared).

## Phase 1: Database Schema & Migration (Destructive)

**Goal:** Replace `labels` tables with `values` tables, update the schema, and introduce Priority.

1.  **Modify `lib/data/drift/drift_database.dart`**:
    *   **Delete Tables**: `LabelTable`, `ProjectLabelsTable`, `TaskLabelsTable`.
    *   **Create Table `ValueTable`** (name: `values`):
        *   Columns: `id`, `name`, `color`, `iconName`, `createdAt`, `updatedAt`, `userId`.
        *   **Add**: `TextColumn get priority => textEnum<ValuePriority>()` (Enum: low, medium, high, urgent).
        *   **Remove**: `type` column.
        *   **Remove**: `systemLabelType` and `isSystemLabel` columns (System labels concept removed entirely).
    *   **Create Table `ProjectValuesTable`** (name: `project_values`):
        *   Columns: `id`, `projectId`, `valueId` (references `ValueTable`), `createdAt`, `updatedAt`, `userId`.
    *   **Create Table `TaskValuesTable`** (name: `task_values`):
        *   Columns: `id`, `taskId`, `valueId` (references `ValueTable`), `createdAt`, `updatedAt`, `userId`.
    *   **Update `TaskTable` & `ProjectTable`**:
        *   **Add**: `BoolColumn get isPinned => boolean().withDefault(const Constant(false)).named('is_pinned')();`
2.  **Generate Migration**:
    *   Run `dart run build_runner build` to generate `drift_database.g.dart`.
    *   Since this is destructive, the migration strategy will be to drop the old tables and create the new ones.

## Phase 2: Domain Layer Refactoring

**Goal:** Rename all Domain entities and contracts to "Value", remove "Label" logic, and integrate Priority.

1.  **Create Priority Enum**:
    *   Create `lib/domain/models/value_priority.dart`.
    *   Enum `ValuePriority` { low, medium, high, urgent }.
    *   Add `weight` property (1, 3, 5, 8).
2.  **Rename & Update Models**:
    *   `lib/domain/models/label.dart` → **`value.dart`**
        *   Class `Label` → `Value`.
        *   Remove `LabelType` enum.
        *   **Add**: `ValuePriority priority` field (default: medium).
        *   **Remove**: `SystemLabelType`, `isSystemLabel`, `systemLabelType` fields.
    *   **Update `Task` & `Project` Models**:
        *   Add `bool isPinned` field (default: false).
    *   **Delete**: `lib/domain/models/labels/system_label_templates.dart` (System labels removed).
    *   **Delete**: `lib/domain/models/settings/value_ranking.dart` (Replaced by intrinsic priority).
3.  **Rename & Update Interfaces**:
    *   `lib/domain/interfaces/label_repository_contract.dart` → **`value_repository_contract.dart`**
        *   Interface `LabelRepositoryContract` → `ValueRepositoryContract`.
        *   Remove `watchByType`/`getAllByType`.
        *   Add `watchAllValues`/`getAllValues`.
        *   Update method signatures to accept `ValuePriority`.
        *   Remove system label methods.
4.  **Rename & Update Queries**:
    *   `lib/domain/queries/label_query.dart` → **`value_query.dart`**
    *   `lib/domain/queries/label_predicate.dart` → **`value_predicate.dart`**
    *   `lib/domain/queries/label_match_mode.dart` → **`value_match_mode.dart`**
    *   `lib/domain/queries/operators/label_comparison.dart` → **`value_comparison.dart`**
    *   **Delete**: `LabelTypePredicate`.

## Phase 3: Data Layer Implementation

**Goal:** Update the repository to implement the new contract and talk to the new tables.

1.  **Rename & Update Repository**:
    *   `lib/data/repositories/label_repository.dart` → **`value_repository.dart`**
        *   Class `LabelRepository` → `ValueRepository`.
        *   Implement `ValueRepositoryContract`.
        *   Update queries to use `db.values`, `db.projectValues`, `db.taskValues`.
        *   Map `priority` field.
        *   Remove system label logic.
2.  **Update Mappers**:
    *   Update `lib/data/mappers/drift_to_domain.dart`:
        *   Map `ValueTableData` to `Value` domain entity.
        *   Include `priority` mapping.

## Phase 4: Presentation Layer - Feature Renaming & BLoCs

**Goal:** Rename the feature folder and update state management.

1.  **Rename Feature Folder**:
    *   `lib/presentation/features/labels/` → **`lib/presentation/features/values/`**
2.  **Rename & Update BLoCs**:
    *   `.../bloc/label_detail_bloc.dart` → **`value_detail_bloc.dart`**
        *   Class `LabelDetailBloc` → `ValueDetailBloc`.
        *   Remove `type` from state/events.
        *   Add `priority` to state/events.
    *   `.../bloc/label_list_bloc.dart` → **`value_list_bloc.dart`**
        *   Class `LabelListBloc` → `ValueListBloc`.
        *   Remove `typeFilter`.
3.  **Update Service Injection**:
    *   Update `lib/core/di/` (or wherever `GetIt` is configured) to register `ValueRepository` instead of `LabelRepository`.

## Phase 5: Presentation Layer - UI Components & Widgets

**Goal:** Update the UI to reflect "Values" and add the Priority input.

1.  **Rename & Update Pages**:
    *   `.../view/label_detail_view.dart` → **`value_detail_view.dart`**
    *   `.../view/label_detail_unified_page.dart` → **`value_detail_unified_page.dart`**
2.  **Rename & Update Widgets**:
    *   `.../widgets/label_form.dart` → **`value_form.dart`**
        *   Remove `LabelType` picker.
        *   **Add**: Priority Picker (Low, Medium, High, Urgent).
    *   `.../widgets/labels_list.dart` → **`values_list.dart`**
    *   `.../widgets/label_list_tile.dart` → **`value_list_tile.dart`**
        *   Display priority indicator.
    *   `.../widgets/add_label_fab.dart` → **`add_value_fab.dart`**
3.  **Shared Widgets Updates**:
    *   `lib/presentation/widgets/label_chip.dart` → **`value_chip.dart`**
    *   `lib/presentation/widgets/labels_section.dart` → **`values_section.dart`**
    *   `lib/presentation/widgets/form_fields/form_builder_label_picker_modern.dart` → **`form_builder_value_picker_modern.dart`**
        *   Remove `limitToType`.
        *   Rename class to `FormBuilderValuePicker`.
4.  **Allocation Settings**:
    *   Update `AllocationSettingsPage` to remove "Value Ranking" drag-and-drop.
    *   Replace with a list of values showing their intrinsic priority.
5.  **Delete Legacy Widgets**:
    *   Delete `form_builder_label_type_picker_modern.dart`.
    *   Delete `form_builder_tag_picker.dart`.

## Phase 6: Cleanup & Verification

**Goal:** Ensure the codebase compiles and tests pass.

1.  **Global Search & Replace**:
    *   Replace `task.labels` with `task.values`.
    *   Replace `project.labels` with `project.values`.
    *   Replace `LabelType.value` checks (remove them, assume true).
    *   Replace `SettingsKey.valueRanking` usages with `value.priority.weight`.
2.  **Localization**:
    *   Update `app_en.arb`: Rename "Label" keys to "Value" keys.
3.  **Run Build Runner**:
    *   `dart run build_runner build --delete-conflicting-outputs`.
4.  **Fix Compilation Errors**:
    *   Address any remaining broken references.
5.  **Run Tests**:
    *   Update and run tests to verify the new "Value" logic and Priority field.
