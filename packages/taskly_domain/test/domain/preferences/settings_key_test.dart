@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/preferences/model/page_key.dart';
import 'package:taskly_domain/src/preferences/model/settings_key.dart';

void main() {
  testSafe('SettingsKey singleton keys compare by name', () async {
    const a = SettingsKey.global;
    const b = SettingsKey.global;

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a.toString(), 'SettingsKey.global');
  });

  testSafe(
    'SettingsKey keyed keys include subKey in equality and toString',
    () async {
      final a = SettingsKey.pageSort(PageKey.tasksInbox);
      final b = SettingsKey.pageSort(PageKey.tasksInbox);
      final c = SettingsKey.pageSort(PageKey.tasksToday);
      final d = SettingsKey.pageDisplay(PageKey.projectOverview);
      final e = SettingsKey.pageDisplay(PageKey.projectOverview);
      final f = SettingsKey.pageJournalFilters(PageKey.journal);
      final g = SettingsKey.pageJournalFilters(PageKey.journal);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('(tasks_inbox)'));
      expect(d, equals(e));
      expect(d.toString(), contains('(project_overview)'));
      expect(f, equals(g));
      expect(f.toString(), contains('(journal)'));
    },
  );
}
