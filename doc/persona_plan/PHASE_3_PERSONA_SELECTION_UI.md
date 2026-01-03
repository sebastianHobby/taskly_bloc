# Phase 3: Persona Selection UI

> **Status**: Not Started  
> **Effort**: 2-3 days  
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

Replace the technical "allocation strategy" selection with a user-friendly persona-based UI:
- Create persona selection cards with descriptions
- Show "Recommended" badge on Realist
- Implement expandable "How it works" sections
- Add threshold configuration inputs
- Show full settings panel when Custom is selected
- **Auto-switch to Custom** when any setting is modified from its persona preset

---

## Files to Create

### 1. `lib/presentation/features/next_action/widgets/persona_selection_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly/domain/models/settings/allocation_persona.dart';

/// A selectable card representing an allocation persona.
/// 
/// Displays:
/// - Persona name and icon
/// - Short description
/// - Optional "Recommended" badge
/// - Expandable "How it works" section
class PersonaSelectionCard extends StatelessWidget {
  const PersonaSelectionCard({
    super.key,
    required this.persona,
    required this.isSelected,
    required this.onTap,
    this.isRecommended = false,
  });

  final AllocationPersona persona;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForPersona(persona),
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nameForPersona(persona),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Chip(
                      label: Text(
                        'Recommended',
                        style: theme.textTheme.labelSmall,
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _descriptionForPersona(persona),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _HowItWorksExpansion(persona: persona),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPersona(AllocationPersona persona) {
    return switch (persona) {
      AllocationPersona.idealist => Icons.star_outline,
      AllocationPersona.reflector => Icons.history,
      AllocationPersona.realist => Icons.balance,
      AllocationPersona.firefighter => Icons.local_fire_department,
      AllocationPersona.custom => Icons.tune,
    };
  }

  String _nameForPersona(AllocationPersona persona) {
    // TODO: Use context.l10n for localization
    return switch (persona) {
      AllocationPersona.idealist => 'Idealist',
      AllocationPersona.reflector => 'Reflector',
      AllocationPersona.realist => 'Realist',
      AllocationPersona.firefighter => 'Firefighter',
      AllocationPersona.custom => 'Custom',
    };
  }

  String _descriptionForPersona(AllocationPersona persona) {
    // TODO: Use context.l10n for localization
    return switch (persona) {
      AllocationPersona.idealist => 'Pure value alignment. Ignores urgency entirely.',
      AllocationPersona.reflector => 'Prioritizes values you\'ve been neglecting.',
      AllocationPersona.realist => 'Balanced approach with urgency awareness.',
      AllocationPersona.firefighter => 'Urgency-first. All urgent tasks included.',
      AllocationPersona.custom => 'Configure all settings manually.',
    };
  }
}

class _HowItWorksExpansion extends StatelessWidget {
  const _HowItWorksExpansion({required this.persona});

  final AllocationPersona persona;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'How it works',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        Text(
          _howItWorksForPersona(persona),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _howItWorksForPersona(AllocationPersona persona) {
    // TODO: Use context.l10n for localization
    return switch (persona) {
      AllocationPersona.idealist => 
        'Tasks are selected purely based on your value weights. '
        'Deadlines and urgency are completely ignored. '
        'Best for: Long-term value alignment without time pressure.',
      AllocationPersona.reflector => 
        'Analyzes your recent completions and prioritizes values you\'ve been ignoring. '
        'Helps maintain balance when you tend to over-focus on certain areas. '
        'Best for: Avoiding burnout on favorite values.',
      AllocationPersona.realist => 
        'Respects your value weights while warning about approaching deadlines. '
        'Urgent tasks with values get a priority boost. '
        'Best for: Most users who want balance.',
      AllocationPersona.firefighter => 
        'Deadlines come first. All urgent tasks are included, even without values. '
        'Prevents missed deadlines at the cost of value alignment. '
        'Best for: High-pressure periods with many deadlines.',
      AllocationPersona.custom => 
        'Full control over all allocation parameters. '
        'Configure urgency thresholds, boost multipliers, and display options. '
        'Best for: Power users who want fine-grained control.',
    };
  }
}
```

---

## Files to Modify

### 2. `lib/presentation/features/next_action/view/allocation_settings_page.dart`

**Complete redesign required.** The page should now contain:

#### Section 1: Persona Selection
```
┌─────────────────────────────────────────┐
│  How should Focus prioritize tasks?     │
├─────────────────────────────────────────┤
│  ☆ Idealist                             │
│  Pure value alignment...                │
├─────────────────────────────────────────┤
│  ⏱ Reflector                            │
│  Prioritizes neglected values...        │
├─────────────────────────────────────────┤
│  ⚖ Realist              [Recommended]  ✓│
│  Balanced approach...                   │
├─────────────────────────────────────────┤
│  🔥 Firefighter                         │
│  Urgency-first...                       │
├─────────────────────────────────────────┤
│  ⚙ Custom                               │
│  Configure all settings...              │
└─────────────────────────────────────────┘
```

#### Section 2: Threshold Settings (always visible)
```
┌─────────────────────────────────────────┐
│  Urgency Thresholds                     │
├─────────────────────────────────────────┤
│  Task urgency (days before deadline)    │
│  [  3  ] ▼                              │
│                                         │
│  Project urgency (days before deadline) │
│  [  7  ] ▼                              │
└─────────────────────────────────────────┘
```

#### Section 3: Display Options (always visible)
```
┌─────────────────────────────────────────┐
│  Display Options                        │
├─────────────────────────────────────────┤
│  Show unassigned task count    [toggle] │
│  Show project next task        [toggle] │
│  Daily task limit              [  10  ] │
└─────────────────────────────────────────┘
```

#### Section 4: Advanced Settings (only when Custom selected)
```
┌─────────────────────────────────────────┐
│  Advanced Settings                      │
├─────────────────────────────────────────┤
│  Urgent task handling                   │
│  ( ) Ignore                             │
│  (•) Warn only                          │
│  ( ) Include all                        │
│                                         │
│  Value-aligned urgency boost            │
│  [  1.5  ] ▼                            │
│                                         │
│  Reflector lookback (days)              │
│  [  7  ] ▼                              │
│                                         │
│  Neglect influence (0-1)                │
│  [  0.7  ] ▼                            │
└─────────────────────────────────────────┘
```

**Implementation approach:**
1. Replace entire build method
2. Use `ListView` with sections
3. Map persona selection to `PersonaSelectionCard` widgets
4. When persona changes, apply preset from `StrategySettings.forPersona()`
5. Show Advanced section only when `persona == AllocationPersona.custom`
6. **Auto-switch to Custom** when any setting is modified from preset values

**Applying persona presets:**
```dart
void _onPersonaSelected(AllocationPersona persona) {
  // Apply the preset strategy settings for this persona
  final presetStrategy = StrategySettings.forPersona(persona);
  
  config = config.copyWith(
    persona: persona,
    strategy: presetStrategy,
  );
  
  // Persist and notify BLoC
  _saveConfig(config);
}
```

**Auto-switch to Custom on modification:**
```dart
/// Call this when ANY strategy setting is changed by the user.
/// If the new value differs from the current persona's preset, switch to Custom.
void _onStrategySettingChanged(StrategySettings newStrategy) {
  final currentPersona = config.persona;
  
  // Don't check if already Custom
  if (currentPersona == AllocationPersona.custom) {
    config = config.copyWith(strategy: newStrategy);
    _saveConfig(config);
    return;
  }
  
  // Compare with preset for current persona
  final preset = StrategySettings.forPersona(currentPersona);
  
  if (newStrategy != preset) {
    // User modified a setting - switch to Custom
    config = config.copyWith(
      persona: AllocationPersona.custom,
      strategy: newStrategy,
    );
    _saveConfig(config);
    
    // Optionally show a snackbar: "Switched to Custom mode"
  } else {
    config = config.copyWith(strategy: newStrategy);
    _saveConfig(config);
  }
}
```

---

## Step-by-Step Implementation

### Step 1: Create PersonaSelectionCard widget
Create `lib/presentation/features/next_action/widgets/persona_selection_card.dart`.

### Step 2: Review existing allocation_settings_page.dart
Read the current implementation to understand:
- How settings are loaded/saved
- BLoC integration
- Current widget structure

### Step 3: Redesign allocation_settings_page.dart
1. Add imports for new widgets and enums
2. Replace body with sectioned ListView
3. Add persona selection section with 5 cards
4. Add threshold settings section
5. Add display options section
6. Add conditional advanced settings section

### Step 4: Implement persona preset logic
When a persona card is tapped:
1. Apply preset values for that persona
2. Update the BLoC state
3. If Custom, show advanced section

### Step 5: Add localization strings
Add all new strings to both `app_en.arb` and `app_es.arb`.

### Step 6: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Localization Strings

**app_en.arb:**
```json
"personaIdealist": "Idealist",
"personaIdealistDescription": "Pure value alignment. Ignores urgency entirely.",
"personaIdealistHowItWorks": "Tasks are selected purely based on your value weights. Deadlines and urgency are completely ignored. Best for: Long-term value alignment without time pressure.",

"personaReflector": "Reflector",
"personaReflectorDescription": "Prioritizes values you've been neglecting.",
"personaReflectorHowItWorks": "Analyzes your recent completions and prioritizes values you've been ignoring. Helps maintain balance when you tend to over-focus on certain areas. Best for: Avoiding burnout on favorite values.",

"personaRealist": "Realist",
"personaRealistDescription": "Balanced approach with urgency awareness.",
"personaRealistHowItWorks": "Respects your value weights while warning about approaching deadlines. Urgent tasks with values get a priority boost. Best for: Most users who want balance.",

"personaFirefighter": "Firefighter",
"personaFirefighterDescription": "Urgency-first. All urgent tasks included.",
"personaFirefighterHowItWorks": "Deadlines come first. All urgent tasks are included, even without values. Prevents missed deadlines at the cost of value alignment. Best for: High-pressure periods with many deadlines.",

"personaCustom": "Custom",
"personaCustomDescription": "Configure all settings manually.",
"personaCustomHowItWorks": "Full control over all allocation parameters. Configure urgency thresholds, boost multipliers, and display options. Best for: Power users who want fine-grained control.",

"personaRecommended": "Recommended",
"personaHowItWorks": "How it works",

"urgencyThresholdsSection": "Urgency Thresholds",
"taskUrgencyDays": "Task urgency (days before deadline)",
"projectUrgencyDays": "Project urgency (days before deadline)",

"displayOptionsSection": "Display Options",
"showUnassignedTaskCount": "Show unassigned task count",
"showProjectNextTask": "Show project next task",
"dailyTaskLimit": "Daily task limit",

"advancedSettingsSection": "Advanced Settings",
"urgentTaskHandling": "Urgent task handling",
"urgentTaskIgnore": "Ignore",
"urgentTaskWarnOnly": "Warn only",
"urgentTaskIncludeAll": "Include all",
"valueAlignedUrgencyBoost": "Value-aligned urgency boost",
"reflectorLookbackDays": "Reflector lookback (days)",
"neglectInfluence": "Neglect influence (0-1)"
```

**app_es.arb:**
```json
"personaIdealist": "Idealista",
"personaIdealistDescription": "Alineación pura con valores. Ignora la urgencia.",
"personaIdealistHowItWorks": "Las tareas se seleccionan únicamente según tus pesos de valores. Las fechas límite y la urgencia se ignoran por completo. Mejor para: Alineación de valores a largo plazo sin presión de tiempo.",

"personaReflector": "Reflector",
"personaReflectorDescription": "Prioriza valores que has estado descuidando.",
"personaReflectorHowItWorks": "Analiza tus completaciones recientes y prioriza valores que has estado ignorando. Ayuda a mantener el equilibrio cuando tiendes a enfocarte demasiado en ciertas áreas. Mejor para: Evitar el agotamiento en valores favoritos.",

"personaRealist": "Realista",
"personaRealistDescription": "Enfoque equilibrado con conciencia de urgencia.",
"personaRealistHowItWorks": "Respeta tus pesos de valores mientras advierte sobre fechas límite próximas. Las tareas urgentes con valores obtienen un impulso de prioridad. Mejor para: La mayoría de usuarios que quieren equilibrio.",

"personaFirefighter": "Bombero",
"personaFirefighterDescription": "Urgencia primero. Todas las tareas urgentes incluidas.",
"personaFirefighterHowItWorks": "Las fechas límite van primero. Todas las tareas urgentes se incluyen, incluso sin valores. Previene fechas límite perdidas a costa de la alineación de valores. Mejor para: Períodos de alta presión con muchas fechas límite.",

"personaCustom": "Personalizado",
"personaCustomDescription": "Configura todos los ajustes manualmente.",
"personaCustomHowItWorks": "Control total sobre todos los parámetros de asignación. Configura umbrales de urgencia, multiplicadores de impulso y opciones de visualización. Mejor para: Usuarios avanzados que quieren control detallado.",

"personaRecommended": "Recomendado",
"personaHowItWorks": "Cómo funciona",

"urgencyThresholdsSection": "Umbrales de Urgencia",
"taskUrgencyDays": "Urgencia de tarea (días antes de la fecha límite)",
"projectUrgencyDays": "Urgencia de proyecto (días antes de la fecha límite)",

"displayOptionsSection": "Opciones de Visualización",
"showUnassignedTaskCount": "Mostrar conteo de tareas sin asignar",
"showProjectNextTask": "Mostrar siguiente tarea del proyecto",
"dailyTaskLimit": "Límite diario de tareas",

"advancedSettingsSection": "Configuración Avanzada",
"urgentTaskHandling": "Manejo de tareas urgentes",
"urgentTaskIgnore": "Ignorar",
"urgentTaskWarnOnly": "Solo advertir",
"urgentTaskIncludeAll": "Incluir todas",
"valueAlignedUrgencyBoost": "Impulso de urgencia alineada con valores",
"reflectorLookbackDays": "Días de retrospectiva del Reflector",
"neglectInfluence": "Influencia de descuido (0-1)"
```

---

## Verification Checklist

- [ ] `PersonaSelectionCard` widget created
- [ ] Card shows icon, name, description for each persona
- [ ] Card shows "Recommended" badge for Realist
- [ ] Card shows checkmark when selected
- [ ] "How it works" expands/collapses
- [ ] Settings page shows 5 persona cards
- [ ] Selecting persona updates `AllocationConfig.persona`
- [ ] Selecting persona applies `StrategySettings.forPersona()` preset
- [ ] Selecting Idealist sets `urgentTaskBehavior` to `ignore` (no urgency impact)
- [ ] Selecting Reflector enables neglect weighting with preset values
- [ ] Selecting Realist sets `urgentTaskBehavior` to `warnOnly` with `urgencyBoostMultiplier` of `1.5`
- [ ] Selecting Firefighter sets `urgentTaskBehavior` to `includeAll` with `urgencyBoostMultiplier` of `2.0`
- [ ] Selecting Custom preserves existing strategy values
- [ ] **Auto-switch**: Modifying ANY setting while on a persona switches to Custom
- [ ] **Auto-switch**: Snackbar or feedback shown when auto-switching to Custom
- [ ] Threshold inputs update `config.strategySettings` settings
- [ ] Display toggle switches update `config.displaySettings` settings
- [ ] Daily limit input updates `config.dailyLimit`
- [ ] Advanced section only visible when Custom selected
- [ ] All UI strings use `context.l10n`
- [ ] Localization strings added (English + Spanish)
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## UI/UX Notes

### Selection Feedback
- Selected card has primary color border and elevated shadow
- Checkmark icon appears in top-right of selected card
- Smooth transition when changing selection

### Accessibility
- All cards are focusable and tappable
- Screen reader announces persona name and selection state
- Sufficient color contrast for all text

### Responsiveness
- Cards stack vertically on narrow screens
- Threshold inputs use appropriate keyboard types
- Toggle switches are touch-friendly size
