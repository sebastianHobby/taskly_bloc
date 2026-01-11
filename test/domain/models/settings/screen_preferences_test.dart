import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';

void main() {
  group('ScreenPreferences', () {
    group('constructor', () {
      test('creates with default values', () {
        const prefs = ScreenPreferences();

        expect(prefs.sortOrder, isNull);
        expect(prefs.isActive, true);
      });

      test('creates with custom values', () {
        const prefs = ScreenPreferences(
          sortOrder: 5,
          isActive: false,
        );

        expect(prefs.sortOrder, 5);
        expect(prefs.isActive, false);
      });

      test('creates with only sortOrder', () {
        const prefs = ScreenPreferences(sortOrder: 10);

        expect(prefs.sortOrder, 10);
        expect(prefs.isActive, true);
      });

      test('creates with only isActive', () {
        const prefs = ScreenPreferences(isActive: false);

        expect(prefs.sortOrder, isNull);
        expect(prefs.isActive, false);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'sortOrder': 3,
          'isActive': false,
        };

        final prefs = ScreenPreferences.fromJson(json);

        expect(prefs.sortOrder, 3);
        expect(prefs.isActive, false);
      });

      test('parses empty JSON with defaults', () {
        final prefs = ScreenPreferences.fromJson(const {});

        expect(prefs.sortOrder, isNull);
        expect(prefs.isActive, true);
      });

      test('parses null sortOrder', () {
        final json = {'sortOrder': null};

        final prefs = ScreenPreferences.fromJson(json);

        expect(prefs.sortOrder, isNull);
      });

      test('parses null isActive as true', () {
        final json = {'isActive': null};

        final prefs = ScreenPreferences.fromJson(json);

        expect(prefs.isActive, true);
      });

      test('parses only sortOrder', () {
        final json = {'sortOrder': 7};

        final prefs = ScreenPreferences.fromJson(json);

        expect(prefs.sortOrder, 7);
        expect(prefs.isActive, true);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const prefs = ScreenPreferences(
          sortOrder: 5,
          isActive: false,
        );

        final json = prefs.toJson();

        expect(json['sortOrder'], 5);
        expect(json['isActive'], false);
      });

      test('omits null sortOrder', () {
        const prefs = ScreenPreferences(isActive: true);

        final json = prefs.toJson();

        expect(json.containsKey('sortOrder'), false);
        expect(json['isActive'], true);
      });

      test('round-trips through JSON with sortOrder', () {
        const original = ScreenPreferences(
          sortOrder: 10,
          isActive: false,
        );

        final json = original.toJson();
        final restored = ScreenPreferences.fromJson(json);

        expect(restored, original);
      });

      test('round-trips through JSON without sortOrder', () {
        const original = ScreenPreferences(isActive: true);

        final json = original.toJson();
        final restored = ScreenPreferences.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const prefs = ScreenPreferences(
          sortOrder: 5,
          isActive: false,
        );

        final copied = prefs.copyWith();

        expect(copied, prefs);
      });

      test('copies with sortOrder change', () {
        const prefs = ScreenPreferences(sortOrder: 1);

        final copied = prefs.copyWith(sortOrder: 99);

        expect(copied.sortOrder, 99);
        expect(copied.isActive, prefs.isActive);
      });

      test('copies with isActive change', () {
        const prefs = ScreenPreferences();

        final copied = prefs.copyWith(isActive: false);

        expect(copied.isActive, false);
      });

      test('copies with both changes', () {
        const prefs = ScreenPreferences();

        final copied = prefs.copyWith(
          sortOrder: 42,
          isActive: false,
        );

        expect(copied.sortOrder, 42);
        expect(copied.isActive, false);
      });
    });

    group('equality', () {
      test('equal preferences are equal', () {
        const prefs1 = ScreenPreferences(sortOrder: 5, isActive: true);
        const prefs2 = ScreenPreferences(sortOrder: 5, isActive: true);

        expect(prefs1, prefs2);
        expect(prefs1.hashCode, prefs2.hashCode);
      });

      test('null sortOrder equals null sortOrder', () {
        const prefs1 = ScreenPreferences(isActive: true);
        const prefs2 = ScreenPreferences(isActive: true);

        expect(prefs1, prefs2);
      });

      test('different sortOrder are not equal', () {
        const prefs1 = ScreenPreferences(sortOrder: 1);
        const prefs2 = ScreenPreferences(sortOrder: 2);

        expect(prefs1, isNot(prefs2));
      });

      test('different isActive are not equal', () {
        const prefs1 = ScreenPreferences(isActive: true);
        const prefs2 = ScreenPreferences(isActive: false);

        expect(prefs1, isNot(prefs2));
      });

      test('null vs non-null sortOrder are not equal', () {
        const prefs1 = ScreenPreferences(sortOrder: null);
        const prefs2 = ScreenPreferences(sortOrder: 0);

        expect(prefs1, isNot(prefs2));
      });

      test('identical returns true for same instance', () {
        const prefs = ScreenPreferences();

        expect(prefs == prefs, true);
      });
    });

    group('toString', () {
      test('returns formatted string with all values', () {
        const prefs = ScreenPreferences(sortOrder: 5, isActive: false);

        expect(
          prefs.toString(),
          'ScreenPreferences(sortOrder: 5, isActive: false)',
        );
      });

      test('returns formatted string with null sortOrder', () {
        const prefs = ScreenPreferences(isActive: true);

        expect(
          prefs.toString(),
          'ScreenPreferences(sortOrder: null, isActive: true)',
        );
      });
    });
  });
}
