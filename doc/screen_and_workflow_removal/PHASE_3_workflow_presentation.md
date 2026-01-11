# Phase 3: Remove Workflow Presentation Layer

**Risk Level:** Medium  
**Estimated Time:** 20 minutes  
**Dependencies:** Phase 2 complete

---

## Objective

Remove all workflow-related UI components, BLoCs, and routing. This removes the user-facing workflow features.

---

## Files to Delete (5 files)

### Presentation Layer
```
lib/presentation/features/workflow/view/workflow_detail_page.dart
lib/presentation/features/workflow/view/workflow_list_page.dart
lib/presentation/features/workflow/view/workflow_run_page.dart
lib/presentation/features/workflow/bloc/workflow_run_bloc.dart
lib/presentation/features/workflow/ (entire folder after individual deletions)
```

---

## Files to Modify (6 files)

### 1. Remove Workflow System Screen

**File:** `lib/domain/screens/catalog/system_screens/system_screen_definitions.dart`

**Action:** Remove `workflows` screen definition

**Find and remove:** (around line 330-350)
```dart
  /// Workflows screen
  static const workflows = ScreenDefinition(
    id: 'workflows',
    screenKey: 'workflows',
    // ... rest of definition
  );
```

**Also remove from:**
- `getByKey()` switch statement (around line 520)
- `defaultSortOrders` map (around line 570)

### 2. Remove Workflow Section Template

**File:** `lib/domain/screens/language/models/section_template_id.dart`

**Find and remove:**
```dart
  static const String workflowDetail = 'workflow_detail';
```

### 3. Remove Workflow Routes

**File:** `lib/presentation/routing/routing.dart`

**Search for and remove:**
- Any routes to `WorkflowListPage`
- Any routes to `WorkflowDetailPage`
- Any routes to `WorkflowRunPage`
- Route path definitions (e.g., `/workflows`, `/workflow/:id`)

### 4. Remove Navigation Icons

**File:** `lib/presentation/features/navigation/services/navigation_icon_resolver.dart`

**Find and remove:**
```dart
      'workflows' || 'workflow' => (
        name: 'Workflows',
        icon: Icons.workflow_icon, // or whatever icon
      ),
```

### 5. Remove Section Template Interpreter (if exists)

**File:** `lib/domain/screens/templates/interpreters/` folder

**Search for:** Any files with `workflow` in the name
- `workflow_detail_section_interpreter.dart`

**Delete:** Any workflow-related interpreters

### 6. Remove Section Template Params (if exists)

**File:** `lib/domain/screens/templates/params/` folder

**Search for:** Any files with `workflow` in the name
- `workflow_detail_section_params.dart`

**Delete:** Any workflow-related params

---

## Repository Method Impact

These repository methods will become unused (removed in Phase 4):
- `getWorkflowById()`
- `watchWorkflows()`
- `createWorkflow()`
- `updateWorkflow()`
- `deleteWorkflow()`
- `updateLastReviewedAt()` (for tasks/projects)

---

## Test Files to Delete

```bash
rm -rf test/presentation/features/workflow/
rm test/domain/screens/templates/interpreters/*workflow*.dart
```

---

## Validation Steps

### 1. Delete presentation files
```bash
rm -rf lib/presentation/features/workflow/
```

### 2. Delete section template files (if exist)
```bash
rm lib/domain/screens/templates/interpreters/*workflow*.dart
rm lib/domain/screens/templates/params/*workflow*.dart
rm lib/presentation/screens/templates/renderers/*workflow*.dart
```

### 3. Make modifications
- Edit `system_screen_definitions.dart`
- Edit `section_template_id.dart`
- Edit `routing.dart`
- Edit `navigation_icon_resolver.dart`

### 4. Delete test files
```bash
rm -rf test/presentation/features/workflow/
rm test/domain/screens/templates/interpreters/*workflow*.dart
```

### 5. Run analysis
```bash
flutter analyze
```

### 6. Fix any import errors
Common issues:
- Other pages navigating to workflow pages
- Menu items still referencing workflows screen
- Deep links still configured for workflows

### 7. Verify no references remain
```bash
grep -ri "WorkflowListPage" lib/ --exclude-dir=.dart_tool
grep -ri "WorkflowDetailPage" lib/ --exclude-dir=.dart_tool
grep -ri "WorkflowRunPage" lib/ --exclude-dir=.dart_tool
grep -ri "WorkflowRunBloc" lib/ --exclude-dir=.dart_tool
grep -ri "workflow_detail" lib/ --exclude-dir=.dart_tool
```

---

## Expected Issues and Fixes

### Issue 1: Navigation menu still showing workflows
**File:** Navigation drawer/menu configuration
**Fix:** Remove workflows menu item

### Issue 2: Deep link routes failing
**File:** App routing configuration
**Fix:** Remove workflow-related route patterns

### Issue 3: Home screen linking to workflows
**File:** Home screen or dashboard
**Fix:** Remove workflow shortcut/card

---

## Expected Analyze Output

```
Analyzing taskly_bloc...
No issues found!
```

---
---

## Next Phase

→ **Phase 4:** Remove workflow data layer and services
