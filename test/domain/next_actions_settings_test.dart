import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings.dart';

void main() {
  group('NextActionsSettings serialization', () {
    test('includeInboxTasks true is preserved during JSON roundtrip', () {
      const settings = NextActionsSettings(
        tasksPerProject: 5,
      );

      final json = settings.toJson();
      final restored = NextActionsSettings.fromJson(json);

      expect(restored.includeInboxTasks, true);
      expect(restored.tasksPerProject, 5);
    });

    test('includeInboxTasks false is preserved during JSON roundtrip', () {
      const settings = NextActionsSettings(
        tasksPerProject: 3,
        includeInboxTasks: false,
      );

      final json = settings.toJson();
      final restored = NextActionsSettings.fromJson(json);

      expect(restored.includeInboxTasks, false);
      expect(restored.tasksPerProject, 3);
    });

    test('AppSettings with includeInboxTasks true roundtrips correctly', () {
      const nextActions = NextActionsSettings(
        tasksPerProject: 7,
      );
      const appSettings = AppSettings(nextActions: nextActions);

      final json = appSettings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.nextActions.includeInboxTasks, true);
      expect(restored.nextActions.tasksPerProject, 7);
    });
  });
}
