@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/preferences/model/page_key.dart';

void main() {
  testSafe('PageKey.fromKey returns matching enum', () async {
    expect(PageKey.fromKey('tasks_inbox'), PageKey.tasksInbox);
    expect(PageKey.fromKey('project_overview'), PageKey.projectOverview);
  });

  testSafe('PageKey.fromKey throws on unknown key', () async {
    expect(() => PageKey.fromKey('nope'), throwsArgumentError);
  });
}
