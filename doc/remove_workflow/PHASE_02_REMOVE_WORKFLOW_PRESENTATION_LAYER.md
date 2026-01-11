# Phase 02 — Remove Workflow Presentation Layer

## Goal
Delete workflow UI screens and BLoCs and remove any remaining imports/usages.

## Target folders/files
- Workflow views:
  - `lib/presentation/features/workflow/view/workflow_list_page.dart`
  - `lib/presentation/features/workflow/view/workflow_creator_page.dart`
  - `lib/presentation/features/workflow/view/workflow_run_page.dart`
- Workflow BLoCs:
  - `lib/presentation/features/workflow/bloc/workflow_definition_bloc.dart`
  - `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart`
- Any exports that re-export workflow screens/models:
  - `lib/presentation/screens/screens.dart`
  - `lib/presentation/screens/models/workflow_screen.dart`

## Step-by-step
1. Remove all references to workflow pages from:
   - section widgets
   - router
   - settings
2. Delete the workflow view files.
3. Delete the workflow BLoC files.
4. Remove any remaining exports/imports referencing deleted files.

## Verification
- Run `flutter analyze`.
- Fix compilation errors only.

## Common fixes expected
- Missing imports from removed files.
- References to `WorkflowRunPage`, `WorkflowListPage`, `WorkflowCreatorPage`.
- References to workflow BLoC types in widget trees.
