# Phase 1: Models and Templates

> **Status:** Ready for implementation  
> **Depends on:** None  
> **Outputs:** Alert type enum, config model, rule model, templates

## Overview

Define the data model for allocation alerts. Fully data-driven with code-defined templates for supported personas.

## New Files

### 1. `lib/domain/models/settings/allocation_alert_type.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

/// Alert types for allocation exclusions.
///
/// Each type maps to a specific condition on ExcludedTask.
/// User enables/disables types and sets severity per type.
enum AllocationAlertType {
  /// Task is urgent but not in Focus
  /// Source: ExcludedTask.isUrgent == true
  @JsonValue('urgent_excluded')
  urgentExcluded,

  /// Task is overdue but not in Focus
  /// Source: ExcludedTask.task.deadlineDate < now
  @JsonValue('overdue_excluded')
  overdueExcluded,

  /// Task has no value assigned
  /// Source: ExcludedTask.exclusionType == noCategory
  @JsonValue('no_value_excluded')
  noValueExcluded,

  /// Task filtered due to low priority
  /// Source: ExcludedTask.exclusionType == lowPriority
  @JsonValue('low_priority_excluded')
  lowPriorityExcluded,

  /// Task excluded because category quota reached
  /// Source: ExcludedTask.exclusionType == categoryLimitReached
  @JsonValue('quota_full_excluded')
  quotaFullExcluded,
}

/// Extension for display properties
extension AllocationAlertTypeX on AllocationAlertType {
  String get displayName => switch (this) {
    AllocationAlertType.urgentExcluded => 'Urgent tasks',
    AllocationAlertType.overdueExcluded => 'Overdue tasks',
    AllocationAlertType.noValueExcluded => 'Tasks without values',
    AllocationAlertType.lowPriorityExcluded => 'Low priority tasks',
    AllocationAlertType.quotaFullExcluded => 'Quota exceeded tasks',
  };

  String get description => switch (this) {
    AllocationAlertType.urgentExcluded => 
      'Alert when urgent tasks are not included in Focus',
    AllocationAlertType.overdueExcluded => 
      'Alert when overdue tasks are not included in Focus',
    AllocationAlertType.noValueExcluded => 
      'Alert when tasks without assigned values are excluded',
    AllocationAlertType.lowPriorityExcluded => 
      'Alert when tasks are filtered due to low priority',
    AllocationAlertType.quotaFullExcluded => 
      'Alert when tasks are excluded because category quota is full',
  };

  /// Icon for this alert type
  String get iconName => switch (this) {
    AllocationAlertType.urgentExcluded => 'bolt',
    AllocationAlertType.overdueExcluded => 'schedule',
    AllocationAlertType.noValueExcluded => 'label_off',
    AllocationAlertType.lowPriorityExcluded => 'low_priority',
    AllocationAlertType.quotaFullExcluded => 'playlist_add_check',
  };
}
```

### 2. `lib/domain/models/settings/alert_severity.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

/// Severity levels for allocation alerts.
///
/// Determines banner styling and sort order.
enum AlertSeverity {
  /// Red banner, highest priority
  @JsonValue('critical')
  critical,

  /// Amber banner, medium priority  
  @JsonValue('warning')
  warning,

  /// Blue banner, informational
  @JsonValue('notice')
  notice,
}

extension AlertSeverityX on AlertSeverity {
  /// Sort order (lower = more severe)
  int get sortOrder => switch (this) {
    AlertSeverity.critical => 0,
    AlertSeverity.warning => 1,
    AlertSeverity.notice => 2,
  };

  String get displayName => switch (this) {
    AlertSeverity.critical => 'Critical',
    AlertSeverity.warning => 'Warning',
    AlertSeverity.notice => 'Notice',
  };
}
```

### 3. `lib/domain/models/settings/allocation_alert_rule.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';

part 'allocation_alert_rule.freezed.dart';
part 'allocation_alert_rule.g.dart';

/// A single alert rule configuration.
///
/// Defines which alert type to check and at what severity.
/// null severity means disabled.
@freezed
abstract class AllocationAlertRule with _$AllocationAlertRule {
  const factory AllocationAlertRule({
    required AllocationAlertType type,
    
    /// Severity for this rule. null = disabled.
    AlertSeverity? severity,
  }) = _AllocationAlertRule;

  factory AllocationAlertRule.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertRuleFromJson(json);
}

extension AllocationAlertRuleX on AllocationAlertRule {
  bool get isEnabled => severity != null;
}
```

### 4. `lib/domain/models/settings/allocation_alert_config.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_rule.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';

part 'allocation_alert_config.freezed.dart';
part 'allocation_alert_config.g.dart';

/// Configuration for allocation alerts.
///
/// Contains a list of rules defining which alert types are enabled
/// and at what severity level.
@freezed
abstract class AllocationAlertConfig with _$AllocationAlertConfig {
  const AllocationAlertConfig._();

  const factory AllocationAlertConfig({
    /// Alert rules. Each type should appear at most once.
    @Default([]) List<AllocationAlertRule> rules,
    
    /// Whether alerts are globally enabled
    @Default(true) bool enabled,
  }) = _AllocationAlertConfig;

  factory AllocationAlertConfig.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertConfigFromJson(json);

  /// Get severity for a specific alert type, or null if disabled
  AlertSeverity? severityFor(AllocationAlertType type) {
    final rule = rules.where((r) => r.type == type).firstOrNull;
    return rule?.severity;
  }

  /// Check if a specific alert type is enabled
  bool isTypeEnabled(AllocationAlertType type) => severityFor(type) != null;

  /// Get all enabled alert types
  List<AllocationAlertType> get enabledTypes =>
      rules.where((r) => r.isEnabled).map((r) => r.type).toList();

  /// Create a new config with a rule updated
  AllocationAlertConfig withRule(AllocationAlertRule rule) {
    final newRules = rules.where((r) => r.type != rule.type).toList();
    if (rule.isEnabled) {
      newRules.add(rule);
    }
    return copyWith(rules: newRules);
  }

  /// Create a new config with a type enabled at given severity
  AllocationAlertConfig withTypeEnabled(
    AllocationAlertType type,
    AlertSeverity severity,
  ) => withRule(AllocationAlertRule(type: type, severity: severity));

  /// Create a new config with a type disabled
  AllocationAlertConfig withTypeDisabled(AllocationAlertType type) =>
      withRule(AllocationAlertRule(type: type, severity: null));
}
```

### 5. `lib/domain/models/settings/allocation_alert_templates.dart`

```dart
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_rule.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/strategy_settings.dart';

/// Predefined alert configurations for each persona.
///
/// These are code-defined templates that match persona philosophy.
/// Users can customize after applying a template.
abstract class AllocationAlertTemplates {
  AllocationAlertTemplates._();

  /// Idealist: Trust the system, minimal alerts
  /// Only critical issues surface (overdue)
  static const idealist = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        type: AllocationAlertType.overdueExcluded,
        severity: AlertSeverity.notice,
      ),
      // Other types disabled - trust allocation
    ],
  );

  /// Reflector: Balanced awareness
  /// Overdue is warning, urgent is notice
  static const reflector = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        type: AllocationAlertType.overdueExcluded,
        severity: AlertSeverity.warning,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.urgentExcluded,
        severity: AlertSeverity.notice,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.noValueExcluded,
        severity: AlertSeverity.notice,
      ),
    ],
  );

  /// Realist: Deadline-focused, strong alerts
  /// Overdue and urgent are critical
  static const realist = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        type: AllocationAlertType.overdueExcluded,
        severity: AlertSeverity.critical,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.urgentExcluded,
        severity: AlertSeverity.warning,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.quotaFullExcluded,
        severity: AlertSeverity.notice,
      ),
    ],
  );

  /// Firefighter: Maximum visibility
  /// Everything that might be urgent is surfaced
  static const firefighter = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        type: AllocationAlertType.overdueExcluded,
        severity: AlertSeverity.critical,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.urgentExcluded,
        severity: AlertSeverity.critical,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.noValueExcluded,
        severity: AlertSeverity.warning,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.lowPriorityExcluded,
        severity: AlertSeverity.notice,
      ),
      AllocationAlertRule(
        type: AllocationAlertType.quotaFullExcluded,
        severity: AlertSeverity.warning,
      ),
    ],
  );

  /// Custom: Same as Reflector (sensible default)
  static const custom = reflector;

  /// Get template for a persona
  static AllocationAlertConfig forPersona(AllocationPersona persona) =>
      switch (persona) {
        AllocationPersona.idealist => idealist,
        AllocationPersona.reflector => reflector,
        AllocationPersona.realist => realist,
        AllocationPersona.firefighter => firefighter,
        AllocationPersona.custom => custom,
      };

  /// All available templates with metadata
  static const List<AlertTemplateInfo> all = [
    AlertTemplateInfo(
      id: 'idealist',
      name: 'Idealist',
      description: 'Trust the system. Minimal alerts.',
      config: idealist,
    ),
    AlertTemplateInfo(
      id: 'reflector',
      name: 'Reflector',
      description: 'Balanced awareness of exclusions.',
      config: reflector,
    ),
    AlertTemplateInfo(
      id: 'realist',
      name: 'Realist',
      description: 'Deadline-focused. Strong alerts for time-sensitive items.',
      config: realist,
    ),
    AlertTemplateInfo(
      id: 'firefighter',
      name: 'Firefighter',
      description: 'Maximum visibility. See everything outside Focus.',
      config: firefighter,
    ),
  ];
}

/// Metadata for a template
class AlertTemplateInfo {
  const AlertTemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.config,
  });

  final String id;
  final String name;
  final String description;
  final AllocationAlertConfig config;
}
```

### 6. `lib/domain/models/settings/allocation_alert_settings.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_templates.dart';

part 'allocation_alert_settings.freezed.dart';
part 'allocation_alert_settings.g.dart';

/// User settings for allocation alerts.
///
/// Stored separately from AllocationConfig to allow independent customization.
/// Persisted via SettingsRepository with key 'allocation_alerts'.
@freezed
abstract class AllocationAlertSettings with _$AllocationAlertSettings {
  const AllocationAlertSettings._();

  const factory AllocationAlertSettings({
    /// Current alert configuration
    @Default(AllocationAlertConfig()) AllocationAlertConfig config,
    
    /// Whether user has customized from persona default
    @Default(false) bool isCustomized,
    
    /// Last applied template ID (for UI display)
    String? appliedTemplateId,
  }) = _AllocationAlertSettings;

  factory AllocationAlertSettings.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertSettingsFromJson(json);

  /// Default settings (Reflector template)
  static const defaults = AllocationAlertSettings(
    config: AllocationAlertTemplates.reflector,
    appliedTemplateId: 'reflector',
  );

  /// Apply a template, resetting customization flag
  AllocationAlertSettings applyTemplate(AlertTemplateInfo template) =>
      AllocationAlertSettings(
        config: template.config,
        isCustomized: false,
        appliedTemplateId: template.id,
      );

  /// Update config, marking as customized
  AllocationAlertSettings withConfig(AllocationAlertConfig newConfig) =>
      copyWith(
        config: newConfig,
        isCustomized: true,
      );
}
```

## Export Updates

### Update `lib/domain/models/settings.dart`

Add exports:
```dart
export 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
export 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
export 'package:taskly_bloc/domain/models/settings/allocation_alert_rule.dart';
export 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
export 'package:taskly_bloc/domain/models/settings/allocation_alert_templates.dart';
export 'package:taskly_bloc/domain/models/settings/allocation_alert_settings.dart';
```

### Update `lib/domain/models/settings_key.dart`

Add new settings key:
```dart
enum SettingsKey<T> {
  // ... existing keys ...
  
  /// Allocation alert configuration
  allocationAlerts<AllocationAlertSettings>(
    'allocation_alerts',
    AllocationAlertSettings.defaults,
  ),
}
```

## Build Runner

After creating files, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Tests

### `test/domain/models/settings/allocation_alert_config_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings.dart';

void main() {
  group('AllocationAlertConfig', () {
    test('severityFor returns correct severity', () {
      const config = AllocationAlertConfig(
        rules: [
          AllocationAlertRule(
            type: AllocationAlertType.overdueExcluded,
            severity: AlertSeverity.critical,
          ),
        ],
      );

      expect(
        config.severityFor(AllocationAlertType.overdueExcluded),
        AlertSeverity.critical,
      );
      expect(
        config.severityFor(AllocationAlertType.urgentExcluded),
        isNull,
      );
    });

    test('isTypeEnabled returns correct value', () {
      const config = AllocationAlertConfig(
        rules: [
          AllocationAlertRule(
            type: AllocationAlertType.overdueExcluded,
            severity: AlertSeverity.critical,
          ),
          AllocationAlertRule(
            type: AllocationAlertType.urgentExcluded,
            severity: null, // Disabled
          ),
        ],
      );

      expect(config.isTypeEnabled(AllocationAlertType.overdueExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.urgentExcluded), isFalse);
    });

    test('withTypeEnabled adds new rule', () {
      const config = AllocationAlertConfig();
      final updated = config.withTypeEnabled(
        AllocationAlertType.overdueExcluded,
        AlertSeverity.warning,
      );

      expect(updated.isTypeEnabled(AllocationAlertType.overdueExcluded), isTrue);
      expect(
        updated.severityFor(AllocationAlertType.overdueExcluded),
        AlertSeverity.warning,
      );
    });

    test('withTypeDisabled removes rule', () {
      const config = AllocationAlertConfig(
        rules: [
          AllocationAlertRule(
            type: AllocationAlertType.overdueExcluded,
            severity: AlertSeverity.critical,
          ),
        ],
      );
      final updated = config.withTypeDisabled(AllocationAlertType.overdueExcluded);

      expect(updated.isTypeEnabled(AllocationAlertType.overdueExcluded), isFalse);
    });
  });

  group('AllocationAlertTemplates', () {
    test('forPersona returns correct template', () {
      expect(
        AllocationAlertTemplates.forPersona(AllocationPersona.firefighter),
        AllocationAlertTemplates.firefighter,
      );
    });

    test('firefighter has all alert types enabled', () {
      final config = AllocationAlertTemplates.firefighter;
      
      expect(config.isTypeEnabled(AllocationAlertType.overdueExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.urgentExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.noValueExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.lowPriorityExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.quotaFullExcluded), isTrue);
    });

    test('idealist has minimal alerts', () {
      final config = AllocationAlertTemplates.idealist;
      
      expect(config.enabledTypes.length, 1);
      expect(config.isTypeEnabled(AllocationAlertType.overdueExcluded), isTrue);
    });
  });
}
```

## AI Implementation Instructions

1. **Create files in order listed** - Dependencies flow downward
2. **Don't modify existing ExcludedTask** - We read from it, don't change it
3. **Match existing freezed patterns** - See `allocation_config.dart` for style
4. **Run build_runner after all files created** - Single run is more efficient
5. **Run tests to validate** - Catch serialization issues early

## Checklist

- [ ] Create `allocation_alert_type.dart`
- [ ] Create `alert_severity.dart`
- [ ] Create `allocation_alert_rule.dart` (freezed)
- [ ] Create `allocation_alert_config.dart` (freezed)
- [ ] Create `allocation_alert_templates.dart`
- [ ] Create `allocation_alert_settings.dart` (freezed)
- [ ] Update `settings.dart` exports
- [ ] Update `settings_key.dart` with new key
- [ ] Run build_runner
- [ ] Create and run tests
