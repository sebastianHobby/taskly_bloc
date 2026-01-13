import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_source.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';

void main() {
  group('ScreenDefinition', () {
    final now = DateTime(2024, 1, 1);

    test('creates with required fields', () {
      final screen = ScreenDefinition(
        id: 'screen-1',
        screenKey: 'inbox',
        name: 'Inbox',
        createdAt: now,
        updatedAt: now,
      );

      expect(screen.id, 'screen-1');
      expect(screen.screenKey, 'inbox');
      expect(screen.name, 'Inbox');
    });

    test('defaults optional fields', () {
      final screen = ScreenDefinition(
        id: 'screen-1',
        screenKey: 'test',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      expect(screen.sections, isEmpty);
      expect(screen.screenSource, ScreenSource.userDefined);
      expect(screen.chrome, ScreenChrome.empty);
      expect(screen.chrome.iconName, isNull);
    });

    test('round-trips through JSON', () {
      final original = ScreenDefinition(
        id: 'screen-123',
        screenKey: 'inbox',
        name: 'Inbox',
        createdAt: now,
        updatedAt: now,
        screenSource: ScreenSource.systemTemplate,
        chrome: const ScreenChrome(iconName: 'inbox'),
        sections: const [
          SectionRef(templateId: SectionTemplateId.taskListV2, params: {}),
        ],
      );

      final restored = ScreenDefinition.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.chrome.iconName, 'inbox');
      expect(restored.sections, hasLength(1));
    });
  });
}
