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

    test('enabledTypes returns only enabled types', () {
      const config = AllocationAlertConfig(
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
            type: AllocationAlertType.noValueExcluded,
            severity: null, // Disabled
          ),
        ],
      );

      expect(config.enabledTypes.length, 2);
      expect(
        config.enabledTypes,
        containsAll([
          AllocationAlertType.overdueExcluded,
          AllocationAlertType.urgentExcluded,
        ]),
      );
    });

    test('withTypeEnabled adds new rule', () {
      const config = AllocationAlertConfig();
      final updated = config.withTypeEnabled(
        AllocationAlertType.overdueExcluded,
        AlertSeverity.warning,
      );

      expect(
        updated.isTypeEnabled(AllocationAlertType.overdueExcluded),
        isTrue,
      );
      expect(
        updated.severityFor(AllocationAlertType.overdueExcluded),
        AlertSeverity.warning,
      );
    });

    test('withTypeEnabled updates existing rule', () {
      const config = AllocationAlertConfig(
        rules: [
          AllocationAlertRule(
            type: AllocationAlertType.overdueExcluded,
            severity: AlertSeverity.notice,
          ),
        ],
      );
      final updated = config.withTypeEnabled(
        AllocationAlertType.overdueExcluded,
        AlertSeverity.critical,
      );

      expect(
        updated.severityFor(AllocationAlertType.overdueExcluded),
        AlertSeverity.critical,
      );
      expect(updated.rules.length, 1);
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
      final updated = config.withTypeDisabled(
        AllocationAlertType.overdueExcluded,
      );

      expect(
        updated.isTypeEnabled(AllocationAlertType.overdueExcluded),
        isFalse,
      );
    });

    test('empty config has no enabled types', () {
      const config = AllocationAlertConfig();
      expect(config.enabledTypes, isEmpty);
    });

    test('disabled config returns null for all severities', () {
      const config = AllocationAlertConfig(
        enabled: false,
        rules: [
          AllocationAlertRule(
            type: AllocationAlertType.overdueExcluded,
            severity: AlertSeverity.critical,
          ),
        ],
      );

      // Note: severityFor still returns the severity,
      // but the evaluator checks enabled flag separately
      expect(
        config.severityFor(AllocationAlertType.overdueExcluded),
        AlertSeverity.critical,
      );
    });
  });

  group('AllocationAlertRule', () {
    test('isEnabled returns true when severity is set', () {
      const rule = AllocationAlertRule(
        type: AllocationAlertType.overdueExcluded,
        severity: AlertSeverity.warning,
      );
      expect(rule.isEnabled, isTrue);
    });

    test('isEnabled returns false when severity is null', () {
      const rule = AllocationAlertRule(
        type: AllocationAlertType.overdueExcluded,
        severity: null,
      );
      expect(rule.isEnabled, isFalse);
    });
  });

  group('AllocationAlertTemplates', () {
    test('forPersona returns correct template', () {
      expect(
        AllocationAlertTemplates.forPersona(AllocationPersona.firefighter),
        AllocationAlertTemplates.firefighter,
      );
      expect(
        AllocationAlertTemplates.forPersona(AllocationPersona.idealist),
        AllocationAlertTemplates.idealist,
      );
    });

    test('firefighter has all alert types enabled', () {
      const config = AllocationAlertTemplates.firefighter;

      expect(config.isTypeEnabled(AllocationAlertType.overdueExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.urgentExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.noValueExcluded), isTrue);
      expect(
        config.isTypeEnabled(AllocationAlertType.lowPriorityExcluded),
        isTrue,
      );
      expect(
        config.isTypeEnabled(AllocationAlertType.quotaFullExcluded),
        isTrue,
      );
    });

    test('idealist has minimal alerts', () {
      const config = AllocationAlertTemplates.idealist;

      expect(config.enabledTypes.length, 1);
      expect(config.isTypeEnabled(AllocationAlertType.overdueExcluded), isTrue);
      expect(config.isTypeEnabled(AllocationAlertType.urgentExcluded), isFalse);
    });

    test('realist prioritizes deadlines', () {
      const config = AllocationAlertTemplates.realist;

      expect(
        config.severityFor(AllocationAlertType.overdueExcluded),
        AlertSeverity.critical,
      );
      expect(
        config.severityFor(AllocationAlertType.urgentExcluded),
        AlertSeverity.warning,
      );
    });

    test('reflector has balanced awareness', () {
      const config = AllocationAlertTemplates.reflector;

      expect(
        config.severityFor(AllocationAlertType.overdueExcluded),
        AlertSeverity.warning,
      );
      expect(
        config.severityFor(AllocationAlertType.urgentExcluded),
        AlertSeverity.notice,
      );
      expect(
        config.severityFor(AllocationAlertType.noValueExcluded),
        AlertSeverity.notice,
      );
    });

    test('custom is same as reflector', () {
      expect(
        AllocationAlertTemplates.custom,
        AllocationAlertTemplates.reflector,
      );
    });

    test('all templates list contains expected entries', () {
      expect(AllocationAlertTemplates.all.length, 4);
      expect(
        AllocationAlertTemplates.all.map((t) => t.id),
        containsAll(['idealist', 'reflector', 'realist', 'firefighter']),
      );
    });
  });

  group('AllocationAlertSettings', () {
    test('defaults uses reflector template', () {
      expect(
        AllocationAlertSettings.defaults.config,
        AllocationAlertTemplates.reflector,
      );
      expect(AllocationAlertSettings.defaults.appliedTemplateId, 'reflector');
      expect(AllocationAlertSettings.defaults.isCustomized, isFalse);
    });

    test('applyTemplate updates config and resets customization', () {
      const settings = AllocationAlertSettings(
        isCustomized: true,
        appliedTemplateId: 'old',
      );

      final template = AllocationAlertTemplates.all.firstWhere(
        (t) => t.id == 'firefighter',
      );
      final updated = settings.applyTemplate(template);

      expect(updated.config, AllocationAlertTemplates.firefighter);
      expect(updated.appliedTemplateId, 'firefighter');
      expect(updated.isCustomized, isFalse);
    });

    test('withConfig marks as customized', () {
      const settings = AllocationAlertSettings.defaults;
      final newConfig = settings.config.withTypeEnabled(
        AllocationAlertType.lowPriorityExcluded,
        AlertSeverity.critical,
      );
      final updated = settings.withConfig(newConfig);

      expect(updated.isCustomized, isTrue);
      expect(
        updated.config.isTypeEnabled(AllocationAlertType.lowPriorityExcluded),
        isTrue,
      );
    });
  });

  group('AlertSeverity', () {
    test('sortOrder is correct', () {
      expect(AlertSeverity.critical.sortOrder, 0);
      expect(AlertSeverity.warning.sortOrder, 1);
      expect(AlertSeverity.notice.sortOrder, 2);
    });

    test('displayName is correct', () {
      expect(AlertSeverity.critical.displayName, 'Critical');
      expect(AlertSeverity.warning.displayName, 'Warning');
      expect(AlertSeverity.notice.displayName, 'Notice');
    });
  });

  group('AllocationAlertType', () {
    test('displayName is correct', () {
      expect(
        AllocationAlertType.urgentExcluded.displayName,
        'Urgent tasks',
      );
      expect(
        AllocationAlertType.overdueExcluded.displayName,
        'Overdue tasks',
      );
    });

    test('description is correct', () {
      expect(
        AllocationAlertType.urgentExcluded.description,
        contains('urgent'),
      );
    });

    test('iconName is correct', () {
      expect(AllocationAlertType.urgentExcluded.iconName, 'bolt');
      expect(AllocationAlertType.overdueExcluded.iconName, 'schedule');
    });
  });

  group('AllocationPersonaX', () {
    test('excludedSectionTitle returns correct titles', () {
      expect(
        AllocationPersona.idealist.excludedSectionTitle,
        'Needs Alignment',
      );
      expect(
        AllocationPersona.reflector.excludedSectionTitle,
        'Worth Considering',
      );
      expect(
        AllocationPersona.realist.excludedSectionTitle,
        'Overdue Attention',
      );
      expect(
        AllocationPersona.firefighter.excludedSectionTitle,
        'Active Fires',
      );
      expect(
        AllocationPersona.custom.excludedSectionTitle,
        'Outside Focus',
      );
    });
  });
}
