import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';

void main() {
  group('FocusMode', () {
    test('has all expected values', () {
      expect(FocusMode.values, [
        FocusMode.intentional,
        FocusMode.sustainable,
        FocusMode.responsive,
        FocusMode.personalized,
      ]);
    });
  });

  group('UrgentTaskBehavior', () {
    test('has all expected values', () {
      expect(UrgentTaskBehavior.values, [
        UrgentTaskBehavior.ignore,
        UrgentTaskBehavior.warnOnly,
        UrgentTaskBehavior.includeAll,
      ]);
    });
  });

  group('AllocationConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = AllocationConfig();

        expect(config.dailyLimit, 10);
        expect(config.hasSelectedFocusMode, false);
        expect(config.focusMode, FocusMode.sustainable);
        expect(config.strategySettings, const StrategySettings());
        expect(config.displaySettings, const DisplaySettings());
      });

      test('creates with custom values', () {
        const config = AllocationConfig(
          dailyLimit: 15,
          hasSelectedFocusMode: true,
          focusMode: FocusMode.responsive,
          strategySettings: StrategySettings(
            urgentTaskBehavior: UrgentTaskBehavior.includeAll,
          ),
          displaySettings: DisplaySettings(
            showOrphanTaskCount: false,
          ),
        );

        expect(config.dailyLimit, 15);
        expect(config.hasSelectedFocusMode, true);
        expect(config.focusMode, FocusMode.responsive);
        expect(
          config.strategySettings.urgentTaskBehavior,
          UrgentTaskBehavior.includeAll,
        );
        expect(config.displaySettings.showOrphanTaskCount, false);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'daily_limit': 20,
          'has_selected_focus_mode': true,
          'focus_mode': 'responsive',
          'strategy_settings': {
            'urgent_task_behavior': 'includeAll',
            'task_urgency_threshold_days': 5,
            'project_urgency_threshold_days': 10,
            'urgency_boost_multiplier': 2.0,
            'enable_neglect_weighting': true,
            'neglect_lookback_days': 14,
            'neglect_influence': 0.5,
          },
          'display_settings': {
            'show_orphan_task_count': false,
            'show_project_next_task': false,
            'gap_warning_threshold_percent': 20,
            'sparkline_weeks': 6,
          },
        };

        final config = AllocationConfig.fromJson(json);

        expect(config.dailyLimit, 20);
        expect(config.hasSelectedFocusMode, true);
        expect(config.focusMode, FocusMode.responsive);
        expect(
          config.strategySettings.urgentTaskBehavior,
          UrgentTaskBehavior.includeAll,
        );
        expect(config.strategySettings.taskUrgencyThresholdDays, 5);
        expect(config.strategySettings.projectUrgencyThresholdDays, 10);
        expect(config.strategySettings.urgencyBoostMultiplier, 2.0);
        expect(config.strategySettings.enableNeglectWeighting, true);
        expect(config.strategySettings.neglectLookbackDays, 14);
        expect(config.strategySettings.neglectInfluence, 0.5);
        expect(config.displaySettings.showOrphanTaskCount, false);
        expect(config.displaySettings.showProjectNextTask, false);
        expect(config.displaySettings.gapWarningThresholdPercent, 20);
        expect(config.displaySettings.sparklineWeeks, 6);
      });

      test('parses empty JSON with defaults', () {
        final config = AllocationConfig.fromJson(const {});

        expect(config.dailyLimit, 10);
        expect(config.hasSelectedFocusMode, false);
        expect(config.focusMode, FocusMode.sustainable);
        expect(
          config.strategySettings.urgentTaskBehavior,
          UrgentTaskBehavior.warnOnly,
        );
      });

      test('parses all focus modes', () {
        for (final mode in FocusMode.values) {
          final json = {'focus_mode': mode.name};
          final config = AllocationConfig.fromJson(json);
          expect(config.focusMode, mode);
        }
      });

      test('parses all urgentTaskBehavior types', () {
        for (final behavior in UrgentTaskBehavior.values) {
          final json = {
            'strategy_settings': {'urgent_task_behavior': behavior.name},
          };
          final config = AllocationConfig.fromJson(json);
          expect(config.strategySettings.urgentTaskBehavior, behavior);
        }
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const config = AllocationConfig(
          dailyLimit: 25,
          hasSelectedFocusMode: true,
          focusMode: FocusMode.intentional,
          strategySettings: StrategySettings(
            urgentTaskBehavior: UrgentTaskBehavior.ignore,
            urgencyBoostMultiplier: 1,
          ),
          displaySettings: DisplaySettings(
            showOrphanTaskCount: false,
          ),
        );

        final json = config.toJson();

        expect(json['daily_limit'], 25);
        expect(json['has_selected_focus_mode'], true);
        expect(json['focus_mode'], 'intentional');
        // Note: nested objects are not serialized automatically by toJson
        // They need separate toJson calls
      });

      test('round-trips through JSON using proper serialization', () {
        const original = AllocationConfig(
          dailyLimit: 12,
          hasSelectedFocusMode: true,
          focusMode: FocusMode.personalized,
          strategySettings: StrategySettings(
            enableNeglectWeighting: true,
            neglectInfluence: 0.8,
          ),
          displaySettings: DisplaySettings(
            sparklineWeeks: 8,
          ),
        );

        // Manual deep serialization
        final json = {
          'daily_limit': original.dailyLimit,
          'has_selected_focus_mode': original.hasSelectedFocusMode,
          'focus_mode': original.focusMode.name,
          'strategy_settings': original.strategySettings.toJson(),
          'display_settings': original.displaySettings.toJson(),
        };
        final restored = AllocationConfig.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const config = AllocationConfig(
          hasSelectedFocusMode: true,
          focusMode: FocusMode.responsive,
          dailyLimit: 15,
        );

        final copied = config.copyWith();

        expect(copied, config);
      });

      test('copies with focusMode change', () {
        const config = AllocationConfig();

        final copied = config.copyWith(
          focusMode: FocusMode.intentional,
        );

        expect(copied.focusMode, FocusMode.intentional);
        expect(copied.dailyLimit, config.dailyLimit);
      });

      test('copies with hasSelectedFocusMode change', () {
        const config = AllocationConfig();

        final copied = config.copyWith(hasSelectedFocusMode: true);

        expect(copied.hasSelectedFocusMode, true);
      });

      test('copies with dailyLimit change', () {
        const config = AllocationConfig();

        final copied = config.copyWith(dailyLimit: 30);

        expect(copied.dailyLimit, 30);
      });

      test('copies with strategySettings change', () {
        const config = AllocationConfig();

        final copied = config.copyWith(
          strategySettings: const StrategySettings(
            urgentTaskBehavior: UrgentTaskBehavior.includeAll,
          ),
        );

        expect(
          copied.strategySettings.urgentTaskBehavior,
          UrgentTaskBehavior.includeAll,
        );
      });

      test('copies with displaySettings change', () {
        const config = AllocationConfig();

        final copied = config.copyWith(
          displaySettings: const DisplaySettings(
            showOrphanTaskCount: false,
          ),
        );

        expect(copied.displaySettings.showOrphanTaskCount, false);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = AllocationConfig(
          dailyLimit: 15,
          hasSelectedFocusMode: true,
          focusMode: FocusMode.responsive,
        );
        const config2 = AllocationConfig(
          dailyLimit: 15,
          hasSelectedFocusMode: true,
          focusMode: FocusMode.responsive,
        );

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('different focusMode are not equal', () {
        const config1 = AllocationConfig(
          hasSelectedFocusMode: true,
          focusMode: FocusMode.intentional,
        );
        const config2 = AllocationConfig(
          hasSelectedFocusMode: true,
          focusMode: FocusMode.sustainable,
        );

        expect(config1, isNot(config2));
      });

      test('different dailyLimit are not equal', () {
        const config1 = AllocationConfig(dailyLimit: 10);
        const config2 = AllocationConfig(dailyLimit: 20);

        expect(config1, isNot(config2));
      });
    });
  });

  group('StrategySettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = StrategySettings();

        expect(settings.urgentTaskBehavior, UrgentTaskBehavior.warnOnly);
        expect(settings.taskUrgencyThresholdDays, 3);
        expect(settings.projectUrgencyThresholdDays, 7);
        expect(settings.urgencyBoostMultiplier, 1.0);
        expect(settings.enableNeglectWeighting, false);
        expect(settings.neglectLookbackDays, 7);
        expect(settings.neglectInfluence, 0.7);
      });
    });

    group('forFocusMode factory', () {
      test('intentional preset', () {
        final settings = StrategySettings.forFocusMode(FocusMode.intentional);

        expect(settings.urgentTaskBehavior, UrgentTaskBehavior.ignore);
        expect(settings.taskUrgencyThresholdDays, 3);
        expect(settings.projectUrgencyThresholdDays, 7);
        expect(settings.urgencyBoostMultiplier, 1);
        expect(settings.enableNeglectWeighting, false);
        expect(settings.neglectLookbackDays, 7);
        expect(settings.neglectInfluence, 0.0);
        expect(settings.valuePriorityWeight, 2);
        expect(settings.taskPriorityBoost, 0.5);
        expect(settings.recencyPenalty, 0);
        expect(settings.startDateProximity, 0);
        expect(settings.overdueEmergencyMultiplier, 1);
      });

      test('sustainable preset', () {
        final settings = StrategySettings.forFocusMode(FocusMode.sustainable);

        expect(settings.urgentTaskBehavior, UrgentTaskBehavior.warnOnly);
        expect(settings.taskUrgencyThresholdDays, 3);
        expect(settings.projectUrgencyThresholdDays, 7);
        expect(settings.urgencyBoostMultiplier, 1.5);
        expect(settings.enableNeglectWeighting, true);
        expect(settings.neglectLookbackDays, 7);
        expect(settings.neglectInfluence, 0.5);
        expect(settings.valuePriorityWeight, 1.5);
        expect(settings.taskPriorityBoost, 1);
        expect(settings.recencyPenalty, 0.1);
        expect(settings.startDateProximity, 0.5);
        expect(settings.overdueEmergencyMultiplier, 1.5);
      });

      test('responsive preset', () {
        final settings = StrategySettings.forFocusMode(FocusMode.responsive);

        expect(settings.urgentTaskBehavior, UrgentTaskBehavior.includeAll);
        expect(settings.taskUrgencyThresholdDays, 3);
        expect(settings.projectUrgencyThresholdDays, 7);
        expect(settings.urgencyBoostMultiplier, 2);
        expect(settings.enableNeglectWeighting, false);
        expect(settings.neglectLookbackDays, 7);
        expect(settings.neglectInfluence, 0.0);
        expect(settings.valuePriorityWeight, 0.5);
        expect(settings.taskPriorityBoost, 2);
        expect(settings.recencyPenalty, 0);
        expect(settings.startDateProximity, 1);
        expect(settings.overdueEmergencyMultiplier, 3);
      });

      test('personalized preset returns defaults', () {
        final settings = StrategySettings.forFocusMode(FocusMode.personalized);

        expect(settings, const StrategySettings());
      });
    });

    group('copyWith', () {
      test('copies with urgentTaskBehavior change', () {
        const settings = StrategySettings();

        final copied = settings.copyWith(
          urgentTaskBehavior: UrgentTaskBehavior.includeAll,
        );

        expect(copied.urgentTaskBehavior, UrgentTaskBehavior.includeAll);
        expect(
          copied.urgencyBoostMultiplier,
          settings.urgencyBoostMultiplier,
        );
      });

      test('copies with urgencyBoostMultiplier change', () {
        const settings = StrategySettings();

        final copied = settings.copyWith(urgencyBoostMultiplier: 2.5);

        expect(copied.urgencyBoostMultiplier, 2.5);
      });

      test('copies with enableNeglectWeighting change', () {
        const settings = StrategySettings();

        final copied = settings.copyWith(enableNeglectWeighting: true);

        expect(copied.enableNeglectWeighting, true);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = StrategySettings(urgencyBoostMultiplier: 1.5);
        const settings2 = StrategySettings(urgencyBoostMultiplier: 1.5);

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different urgentTaskBehavior are not equal', () {
        const settings1 = StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.ignore,
        );
        const settings2 = StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.includeAll,
        );

        expect(settings1, isNot(settings2));
      });
    });
  });

  group('DisplaySettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = DisplaySettings();

        expect(settings.showOrphanTaskCount, true);
        expect(settings.showProjectNextTask, true);
        expect(settings.gapWarningThresholdPercent, 15);
        expect(settings.sparklineWeeks, 4);
      });
    });

    group('copyWith', () {
      test('copies with showOrphanTaskCount change', () {
        const settings = DisplaySettings();

        final copied = settings.copyWith(showOrphanTaskCount: false);

        expect(copied.showOrphanTaskCount, false);
      });

      test('copies with sparklineWeeks change', () {
        const settings = DisplaySettings();

        final copied = settings.copyWith(sparklineWeeks: 8);

        expect(copied.sparklineWeeks, 8);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = DisplaySettings(sparklineWeeks: 6);
        const settings2 = DisplaySettings(sparklineWeeks: 6);

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different showOrphanTaskCount are not equal', () {
        const settings1 = DisplaySettings(showOrphanTaskCount: true);
        const settings2 = DisplaySettings(showOrphanTaskCount: false);

        expect(settings1, isNot(settings2));
      });
    });
  });
}
