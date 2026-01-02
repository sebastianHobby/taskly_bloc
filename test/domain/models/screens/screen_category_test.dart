import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';

void main() {
  group('ScreenCategory', () {
    test('has three values', () {
      expect(ScreenCategory.values.length, 3);
    });

    test('workspace is a valid value', () {
      expect(ScreenCategory.workspace, isA<ScreenCategory>());
    });

    test('wellbeing is a valid value', () {
      expect(ScreenCategory.wellbeing, isA<ScreenCategory>());
    });

    test('settings is a valid value', () {
      expect(ScreenCategory.settings, isA<ScreenCategory>());
    });

    group('displayName', () {
      test('returns Workspace for workspace', () {
        expect(ScreenCategory.workspace.displayName, 'Workspace');
      });

      test('returns Wellbeing for wellbeing', () {
        expect(ScreenCategory.wellbeing.displayName, 'Wellbeing');
      });

      test('returns Settings for settings', () {
        expect(ScreenCategory.settings.displayName, 'Settings');
      });
    });
  });
}
