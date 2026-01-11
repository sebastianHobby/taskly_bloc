import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/models/page_display_settings.dart';

void main() {
  group('PageDisplaySettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = PageDisplaySettings();

        expect(settings.hideCompleted, true);
        expect(settings.completedSectionCollapsed, false);
        expect(settings.showNextActionsBanner, true);
      });

      test('creates with custom values', () {
        const settings = PageDisplaySettings(
          hideCompleted: false,
          completedSectionCollapsed: true,
          showNextActionsBanner: false,
        );

        expect(settings.hideCompleted, false);
        expect(settings.completedSectionCollapsed, true);
        expect(settings.showNextActionsBanner, false);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'hideCompleted': false,
          'completedSectionCollapsed': true,
          'showNextActionsBanner': false,
        };

        final settings = PageDisplaySettings.fromJson(json);

        expect(settings.hideCompleted, false);
        expect(settings.completedSectionCollapsed, true);
        expect(settings.showNextActionsBanner, false);
      });

      test('parses empty JSON with defaults', () {
        final settings = PageDisplaySettings.fromJson({});

        expect(settings.hideCompleted, true);
        expect(settings.completedSectionCollapsed, false);
        expect(settings.showNextActionsBanner, true);
      });

      test('parses null values with defaults', () {
        final json = {
          'hideCompleted': null,
          'completedSectionCollapsed': null,
          'showNextActionsBanner': null,
        };

        final settings = PageDisplaySettings.fromJson(json);

        expect(settings.hideCompleted, true);
        expect(settings.completedSectionCollapsed, false);
        expect(settings.showNextActionsBanner, true);
      });

      test('parses partial JSON', () {
        final json = {'hideCompleted': false};

        final settings = PageDisplaySettings.fromJson(json);

        expect(settings.hideCompleted, false);
        expect(settings.completedSectionCollapsed, false);
        expect(settings.showNextActionsBanner, true);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const settings = PageDisplaySettings(
          hideCompleted: false,
          completedSectionCollapsed: true,
          showNextActionsBanner: false,
        );

        final json = settings.toJson();

        expect(json['hideCompleted'], false);
        expect(json['completedSectionCollapsed'], true);
        expect(json['showNextActionsBanner'], false);
      });

      test('round-trips through JSON', () {
        const original = PageDisplaySettings(
          hideCompleted: false,
          completedSectionCollapsed: true,
          showNextActionsBanner: false,
        );

        final json = original.toJson();
        final restored = PageDisplaySettings.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const settings = PageDisplaySettings(
          hideCompleted: false,
          completedSectionCollapsed: true,
        );

        final copied = settings.copyWith();

        expect(copied, settings);
      });

      test('copies with hideCompleted change', () {
        const settings = PageDisplaySettings(hideCompleted: true);

        final copied = settings.copyWith(hideCompleted: false);

        expect(copied.hideCompleted, false);
        expect(
          copied.completedSectionCollapsed,
          settings.completedSectionCollapsed,
        );
      });

      test('copies with completedSectionCollapsed change', () {
        const settings = PageDisplaySettings();

        final copied = settings.copyWith(completedSectionCollapsed: true);

        expect(copied.completedSectionCollapsed, true);
      });

      test('copies with showNextActionsBanner change', () {
        const settings = PageDisplaySettings();

        final copied = settings.copyWith(showNextActionsBanner: false);

        expect(copied.showNextActionsBanner, false);
      });

      test('copies with multiple changes', () {
        const settings = PageDisplaySettings();

        final copied = settings.copyWith(
          hideCompleted: false,
          completedSectionCollapsed: true,
          showNextActionsBanner: false,
        );

        expect(copied.hideCompleted, false);
        expect(copied.completedSectionCollapsed, true);
        expect(copied.showNextActionsBanner, false);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = PageDisplaySettings(
          hideCompleted: false,
          completedSectionCollapsed: true,
        );
        const settings2 = PageDisplaySettings(
          hideCompleted: false,
          completedSectionCollapsed: true,
        );

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different hideCompleted are not equal', () {
        const settings1 = PageDisplaySettings(hideCompleted: true);
        const settings2 = PageDisplaySettings(hideCompleted: false);

        expect(settings1, isNot(settings2));
      });

      test('different completedSectionCollapsed are not equal', () {
        const settings1 = PageDisplaySettings(completedSectionCollapsed: false);
        const settings2 = PageDisplaySettings(completedSectionCollapsed: true);

        expect(settings1, isNot(settings2));
      });

      test('different showNextActionsBanner are not equal', () {
        const settings1 = PageDisplaySettings(showNextActionsBanner: true);
        const settings2 = PageDisplaySettings(showNextActionsBanner: false);

        expect(settings1, isNot(settings2));
      });
    });
  });
}
