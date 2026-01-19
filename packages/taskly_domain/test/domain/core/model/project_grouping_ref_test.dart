@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/model/project_grouping_ref.dart';

void main() {
  testSafe('ProjectGroupingRef.inbox is identified as inbox', () async {
    const ref = ProjectGroupingRef.inbox();

    expect(ref.isInbox, isTrue);
    expect(ref.projectId, isNull);
    expect(ref.stableKey, 'inbox');
  });

  testSafe(
    'ProjectGroupingRef.project exposes projectId and stableKey',
    () async {
      const ref = ProjectGroupingRef.project(projectId: 'p1');

      expect(ref.isInbox, isFalse);
      expect(ref.projectId, 'p1');
      expect(ref.stableKey, 'p1');
    },
  );

  testSafe(
    'ProjectGroupingRef.fromProjectId trims and maps empty to inbox',
    () async {
      final inbox = ProjectGroupingRef.fromProjectId('  ');
      final project = ProjectGroupingRef.fromProjectId('  p2  ');

      expect(inbox, isA<InboxProjectGroupingRef>());
      expect(project, const ProjectProjectGroupingRef(projectId: 'p2'));
    },
  );
}
