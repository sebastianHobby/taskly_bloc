# Phase 8: Values Gateway

> **Status**: Not Started  
> **Effort**: 1 day  
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
- Use **`sealed class`** for union types (multiple factory constructors / variants)
- Use **`abstract class`** for single-class models with copyWith

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
- Provide "Set Up My Values" CTA that navigates to values screen
- User can go back/cancel but cannot use Focus without at least one value
- **No skip option** - values are required for allocation

---

## Background

The persona-based allocation system is meaningless without values. Rather than showing an empty Focus screen or confusing results, we guide users to set up their values first.

**User journey:**
1. New user opens Focus tab
2. Gateway appears explaining values-based prioritization
3. User taps **Set Up Values** → navigates to values screen
4. User creates at least one value
5. User returns to Focus → normal allocation works

**No skip option**: Values are required. User can navigate away but Focus remains gated until values exist.

---

## Target UI Mockup

```
┌─────────────────────────────────────────┐
│  ←                                      │  ← Back button to exit Focus
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
└─────────────────────────────────────────┘
```

**Note**: No skip option. User can use back button to leave Focus, but cannot access Focus features without values.

---

## Files to Create

### 1. `lib/presentation/features/next_action/widgets/values_required_gateway.dart`

```dart
import 'package:flutter/material.dart';

/// Full-screen gateway shown when user has no values defined.
/// 
/// Explains the purpose of values-based allocation. User must set up
/// values to use Focus - there is no skip option.
class ValuesRequiredGateway extends StatelessWidget {
  const ValuesRequiredGateway({
    super.key,
    required this.onSetUpValues,
  });

  /// Called when "Set Up My Values" is tapped.
  final VoidCallback onSetUpValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        // Back button automatically provided by Navigator
        title: Text(l10n.focusTitle),
      ),
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
                l10n.valuesGatewayTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                l10n.valuesGatewayDescription,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),

              // Primary CTA - only option
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSetUpValues,
                  icon: const Icon(Icons.star_outline),
                  label: Text(l10n.setUpMyValues),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
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

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<NextActionsBloc, NextActionsState>(
    builder: (context, state) {
      // Gateway shows when no values exist - values are REQUIRED
      if (state.values.isEmpty) {
        return ValuesRequiredGateway(
          onSetUpValues: () => _navigateToValuesSetup(context),
        );
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
```

---

## Step-by-Step Implementation

### Step 1: Create ValuesRequiredGateway widget
Create `lib/presentation/features/next_action/widgets/values_required_gateway.dart`.

### Step 2: Integrate gateway into next_actions_page
1. Import gateway widget
2. Add condition check in build method
3. Show gateway when values empty

### Step 3: Add localization strings
Add gateway text to l10n files (English + Spanish).

### Step 4: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `ValuesRequiredGateway` widget created
- [ ] Gateway shows icon, title, description
- [ ] Gateway has "Set Up My Values" primary button
- [ ] **No skip option exists**
- [ ] "Set Up" navigates to values screen
- [ ] Gateway shows when: `values.isEmpty`
- [ ] Normal Focus shows when: has at least one value
- [ ] Back button in AppBar allows user to leave Focus
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
5. User creates at least one value
6. User returns to Focus
7. → Normal Focus with allocated tasks
```

### Flow 2: User Navigates Away Without Values
```
1. User opens Focus (first time)
2. Gateway appears
3. User taps back button
4. → User leaves Focus (goes to previous screen or home)
5. Next time user opens Focus → Gateway still shown
```

### Flow 3: User Deletes All Values
```
1. User had values, deletes all
2. Next Focus visit shows gateway again
3. Must create value to use Focus
```

---

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No values, first launch | Show gateway |
| No values, returns to Focus | Show gateway |
| Has at least one value | Show normal Focus |
| Back button pressed | Navigate away from Focus |
| All values deleted | Show gateway on next Focus visit |

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
}
```

**app_es.arb:**
```json
"valuesGatewayTitle": "Prioriza Lo Que Importa",
"valuesGatewayDescription": "Focus utiliza tus valores personales para recomendar qué tareas merecen tu atención hoy.\n\nDefine lo que es importante para ti—como Salud, Familia, Carrera—y Focus te ayudará a dedicar tiempo a lo que realmente importa.",
"setUpMyValues": "Configurar Mis Valores"
```

---

## Notes

- **Simplified scope**: No skip option means no deadline-based fallback view, no session state tracking
- **Clean UX**: Users understand that values are required upfront
- **Reduced complexity**: No BLoC state changes needed for this phase
