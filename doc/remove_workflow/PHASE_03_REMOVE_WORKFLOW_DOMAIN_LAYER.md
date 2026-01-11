# Phase 03 — Remove Workflow Domain Layer

## Goal
Remove workflow domain models, contracts, and services that are only used by the workflow feature.

## Target files
- Domain models:
  - `lib/domain/workflow/model/workflow.dart`
  - `lib/domain/workflow/model/workflow_definition.dart`
  - `lib/domain/workflow/model/workflow_step.dart`
  - `lib/domain/workflow/model/workflow_step_state.dart`
- Domain service:
  - `lib/domain/services/workflow/workflow_service.dart`
- Repository contract:
  - `lib/domain/interfaces/workflow_repository_contract.dart`
- Workflow-specific screen-language models (only if unused elsewhere after workflow UI removal):
  - `lib/domain/screens/language/models/workflow_item.dart`
  - `lib/domain/screens/language/models/workflow_progress.dart`

## Step-by-step
1. Confirm workflow models are not referenced outside the workflow feature.
2. Remove `WorkflowRepositoryContract` and its DI registration.
3. Remove `WorkflowService` and its DI registration.
4. Delete workflow domain models.
5. Delete `workflow_item.dart` and `workflow_progress.dart` if now unused.

## Verification
- Run `flutter analyze`.
- Fix compilation errors only.

## Caution
Some workflow-adjacent “problem” widgets/models may live under `domain/models/workflow/*` naming but be used elsewhere (e.g. problems/soft gates). If they are used by non-workflow features, keep them and only remove the parts strictly required for workflows.
