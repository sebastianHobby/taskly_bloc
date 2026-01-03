# Phase 8: Values Gateway

> **Status**: Not Started  
> **Effort**: 1-2 days  
> **Dependencies**: Phase 1 (Model Foundation)

---

## AI Implementation Instructions

### General Guidelines
1. **Follow existing patterns** - Match code style, naming conventions, and architecture patterns already in the codebase
2. **Do NOT run or update tests** - If tests break, leave them; they will be fixed separately
3. **Run `flutter analyze` at end of phase** - Fix ALL errors and warnings before marking phase complete
4. **Format code** - Use `dart format` or the dart_format tool for Dart files

### Build Runner
- **Assume `build_runner` is running in watch mode** in background
- **Do NOT run `dart run build_runner build` manually**
- After creating/modifying freezed files, wait for `.freezed.dart` / `.g.dart` files to regenerate
- If generated files don't update after ~45 seconds, there's likely a **syntax error in the source .dart file** - review and fix

### Freezed Syntax (Project Convention)
- Use **`sealed class`** for union types (multiple factory constructors / variants):
  ```dart
  @freezed
  sealed class MyEvent with _$MyEvent {
    const factory MyEvent.started() = _Started;
    const factory MyEvent.loaded(Data data) = _Loaded;
  }
  ```
- Use **`abstract class`** for single-class models with copyWith:
  ```dart
  @freezed
  abstract class MyModel with _$MyModel {
    const factory MyModel({
      required String id,
      required String name,
    }) = _MyModel;
  }
  ```

### Compatibility - IMPORTANT
- **No backwards compatibility** - Remove old fields/code completely
- **No deprecation annotations** - Just delete obsolete code
- **No migration logic** - Clean break, assume fresh state

### Presentation Layer Rules
- Use BLoC pattern for state management
- Widgets should be stateless where possible
- Use `context.l10n` for all user-facing strings
- Follow Material 3 theming conventions

---

## Objective

Require values setup before using Focus/allocation features:
- Show full-screen gateway when user has 0 values defined
- Explain the purpose and benefits of values
- Provide "Set Up My Values" CTA
- Offer "Skip" option with deadline-only fallback
- Remember skip preference

---

## Background

The persona-based allocation system is meaningless without values. Rather than showing an empty Focus screen or confusing results, we guide users to set up their values first.

**User journey:**
1. New user opens Focus tab
2. Gateway appears explaining values-based prioritization
3. User can:
   - **Set Up Values** → navigates to values screen
   - **Skip for Now** → shows tasks by deadline only

---

## Target UI Mockup

```
┌─────────────────────────────────────────┐
│                                         │
│              ⚖️                          │
│                                         │
│     Prioritize What Matters             │
│                                         │
│  Focus uses your personal values to     │
│  recommend which tasks deserve your     │
│  attention today.                       │
│                                         │
│  Define what's important to you—like    │
│  Health, Family, Career—and Focus       │
│  will help you spend time on what       │
│  truly matters.                         │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │       Set Up My Values          │    │
│  └─────────────────────────────────┘    │
│                                         │
│       Skip and show by deadline →       │
│                                         │
└─────────────────────────────────────────┘
```

---

## Files to Create

### 1. `lib/presentation/features/next_action/widgets/values_required_gateway.dart`

```dart
import 'package:flutter/material.dart';

/// Full-screen gateway shown when user has no values defined.
/// 
/// Explains the purpose of values-based allocation and prompts
/// the user to set up their values or skip to deadline-based view.
class ValuesRequiredGateway extends StatelessWidget {
  const ValuesRequiredGateway({
    super.key,
    required this.onSetUpValues,
    required this.onSkip,
  });

  /// Called when "Set Up My Values" is tapped.
  final VoidCallback onSetUpValues;

  /// Called when "Skip" is tapped.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Icon
              Icon(
                Icons.balance,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Prioritize What Matters', // TODO: context.l10n
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Focus uses your personal values to recommend which tasks '
                'deserve your attention today.\n\n'
                'Define what\'s important to you—like Health, Family, '
                'Career—and Focus will help you spend time on what truly matters.',
                // TODO: context.l10n
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),

              // Primary CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSetUpValues,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Set Up My Values'), // TODO: context.l10n
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Skip option
              TextButton(
                onPressed: onSkip,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip and show by deadline', // TODO: context.l10n
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Files to Modify

### 2. `lib/presentation/features/next_action/view/next_actions_page.dart`

**Add gateway check to build method:**

> **IMPORTANT**: Gateway ALWAYS shows when there are no values, regardless of skip preference. Skip only affects the current session - if user returns to Focus with no values, gateway shows again.

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<NextActionsBloc, NextActionsState>(
    builder: (context, state) {
      // Gateway ALWAYS shows when no values exist
      // Skip preference only hides gateway for current session
      if (state.values.isEmpty && !state.hasSkippedValuesSetupThisSession) {
        return ValuesRequiredGateway(
          onSetUpValues: () => _navigateToValuesSetup(context),
          onSkip: () => _handleSkip(context),
        );
      }

      // Show deadline-based view if skipped (no values)
      if (state.values.isEmpty && state.hasSkippedValuesSetupThisSession) {
        return _DeadlineBasedFocusView(tasks: state.deadlineSortedTasks);
      }

      // Normal values-based Focus content
      return Scaffold(
        // ... existing implementation
      );
    },
  );
}

void _navigateToValuesSetup(BuildContext context) {
  // Navigate to values screen
  context.push('/values');
}

void _handleSkip(BuildContext context) {
  // Mark as skipped for THIS SESSION ONLY (not persisted)
  context.read<NextActionsBloc>().add(
    const NextActionsEvent.valuesSetupSkippedThisSession(),
  );
}
```

---

### 3. Update BLoC State

**Add to state:**

```dart
/// Whether the user has skipped values setup THIS SESSION.
/// NOT persisted - gateway shows again on next app launch if no values.
final bool hasSkippedValuesSetupThisSession;
```

**Add event:**

```dart
/// User chose to skip values setup for this session.
const factory NextActionsEvent.valuesSetupSkippedThisSession() = _ValuesSetupSkippedThisSession;
```

**Handle in BLoC:**

```dart
on<_ValuesSetupSkippedThisSession>((event, emit) {
  // Session-only skip - NOT persisted to storage
  emit(state.copyWith(hasSkippedValuesSetupThisSession: true));
});
```

---

### 4. Deadline-Based Fallback View

When user skips values setup for the session, show tasks sorted by deadline only:

```dart
class _DeadlineBasedFocusView extends StatelessWidget {
  const _DeadlineBasedFocusView({required this.tasks});
  
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.focusTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/values'),
            child: Text(l10n.setUpValues),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.showingTasksByDeadline,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskListTile(task: tasks[index]),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Deadline sorting logic (in BLoC):**

```dart
List<Task> get deadlineSortedTasks {
  final sortedTasks = state.tasks
      .where((t) => !t.completed)
      .toList()
      ..sort((a, b) {
        // Tasks with deadlines first
        if (a.deadlineDate != null && b.deadlineDate == null) return -1;
        if (a.deadlineDate == null && b.deadlineDate != null) return 1;
        if (a.deadlineDate != null && b.deadlineDate != null) {
          return a.deadlineDate!.compareTo(b.deadlineDate!);
        }
        // Fall back to creation date
        return a.createdAt.compareTo(b.createdAt);
      });
  
  return sortedTasks.take(state.settings.dailyTaskLimit).toList();
}
```

---

## Step-by-Step Implementation

### Step 1: Create ValuesRequiredGateway widget
Create `lib/presentation/features/next_action/widgets/values_required_gateway.dart`.

### Step 2: Update BLoC state and events
1. Add `hasSkippedValuesSetupThisSession` to state (NOT persisted)
2. Add `valuesSetupSkippedThisSession` event
3. Handle skip event (in-memory only)

### Step 3: Integrate gateway into next_actions_page
1. Import gateway widget
2. Add condition check in build method
3. Show gateway when values empty AND not skipped this session

### Step 4: Implement deadline-based fallback view
When skipped, show simple deadline-sorted list with info banner.

### Step 5: Add localization strings
Add all gateway text to l10n files (English + Spanish).

### Step 6: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `ValuesRequiredGateway` widget created
- [ ] Gateway shows icon, title, description
- [ ] Gateway has "Set Up My Values" primary button
- [ ] Gateway has "Skip" text button
- [ ] "Set Up" navigates to values screen
- [ ] "Skip" sets session flag and shows fallback
- [ ] Skip is **session-only** (NOT persisted)
- [ ] `hasSkippedValuesSetupThisSession` added to BLoC state
- [ ] `valuesSetupSkippedThisSession` event added to BLoC
- [ ] Gateway shows when: values empty AND not skipped this session
- [ ] Gateway shows again on app restart if no values
- [ ] Normal Focus shows when: has values
- [ ] Deadline-based fallback view works correctly
- [ ] Fallback view has "Set Up Values" button in app bar
- [ ] All UI strings use `context.l10n`
- [ ] Localization strings added (English + Spanish)
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## User Flows

### Flow 1: New User Sets Up Values
```
1. User opens Focus (first time)
2. Gateway appears
3. User taps "Set Up My Values"
4. → Navigates to Values screen
5. User creates 2-3 values
6. User returns to Focus
7. → Normal Focus with allocated tasks
```

### Flow 2: New User Skips (Session Only)
```
1. User opens Focus (first time)
2. Gateway appears
3. User taps "Skip and show by deadline"
4. → Focus shows deadline-sorted tasks
5. User uses app for session
6. User closes and reopens app
7. → Gateway appears again (skip not persisted)
```

### Flow 3: User Adds Values from Fallback
```
1. User skipped gateway, sees deadline view
2. User taps "Set Up Values" in app bar
3. User creates first value
4. User returns to Focus
5. → Normal Focus with values-based allocation
```

### Flow 4: User Deletes All Values
```
1. User had values, deletes all
2. Next Focus visit shows gateway again
3. Skip preference is session-only, so gateway always shows
```

---

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No values, first launch | Show gateway |
| No values, skipped this session | Show deadline fallback |
| No values, new session (app restarted) | Show gateway again |
| Has values | Show normal Focus |
| Skip tapped | Show deadline list for session |
| All values deleted | Show gateway |
| App reinstall | Gateway shows |

---

## UI/UX Notes

### Visual Design
- Gateway uses centered layout for emphasis
- Primary CTA is prominent (filled button)
- Skip option is subtle but accessible
- Icon reinforces "balance" theme

### Accessibility
- All text is readable at large font sizes
- Buttons are touch-friendly
- Screen reader announces purpose clearly

### Copy Considerations
- "Prioritize What Matters" - aspirational, benefit-focused
- Description is concise but informative
- "Set Up My Values" - action-oriented
- "Skip and show by deadline" - clear alternative

---

## Localization Strings

**app_en.arb:**
```json
"valuesGatewayTitle": "Prioritize What Matters",
"@valuesGatewayTitle": {
  "description": "Title for values setup gateway"
},
"valuesGatewayDescription": "Focus uses your personal values to recommend which tasks deserve your attention today.\n\nDefine what's important to you—like Health, Family, Career—and Focus will help you spend time on what truly matters.",
"@valuesGatewayDescription": {
  "description": "Description for values setup gateway"
},
"setUpMyValues": "Set Up My Values",
"@setUpMyValues": {
  "description": "Button to set up values"
},
"skipShowByDeadline": "Skip and show by deadline",
"@skipShowByDeadline": {
  "description": "Skip button for values gateway"
},
"showingTasksByDeadline": "Showing tasks by deadline. Set up values for personalized prioritization.",
"@showingTasksByDeadline": {
  "description": "Info banner in deadline fallback view"
},
"setUpValues": "Set Up Values",
"@setUpValues": {
  "description": "App bar action to set up values"
}
```

**app_es.arb:**
```json
"valuesGatewayTitle": "Prioriza Lo Que Importa",
"valuesGatewayDescription": "Focus utiliza tus valores personales para recomendar qué tareas merecen tu atención hoy.\n\nDefine lo que es importante para ti—como Salud, Familia, Carrera—y Focus te ayudará a dedicar tiempo a lo que realmente importa.",
"setUpMyValues": "Configurar Mis Valores",
"skipShowByDeadline": "Omitir y mostrar por fecha límite",
"showingTasksByDeadline": "Mostrando tareas por fecha límite. Configura valores para priorización personalizada.",
"setUpValues": "Configurar Valores"
```

---

## Future Enhancements

Not in scope for this phase, but consider:

1. **Onboarding flow** - Multi-step wizard for first-time users
2. **Suggested values** - Pre-populated templates (Life Balance, Career Focus, etc.)
3. **Re-prompt after time** - If skipped, ask again after 7 days
4. **Benefits preview** - Show example of values-based Focus before setup
