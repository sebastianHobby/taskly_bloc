@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  testSafe('SyncIssue stores required fields', () async {
    final issue = SyncIssue(
      id: 'issue-1',
      userId: 'user-1',
      status: SyncIssueStatus.open,
      severity: SyncIssueSeverity.error,
      category: SyncIssueCategory.schema,
      fingerprint: 'fp',
      issueCode: 'schema_not_found',
      title: 'Sync anomaly',
      message: 'Mismatch detected',
      details: const {'table': 'tasks'},
      firstSeenAt: DateTime.utc(2026, 2, 22, 10),
      lastSeenAt: DateTime.utc(2026, 2, 22, 11),
      occurrenceCount: 3,
      createdAt: DateTime.utc(2026, 2, 22, 10),
      updatedAt: DateTime.utc(2026, 2, 22, 11),
    );

    expect(issue.status, SyncIssueStatus.open);
    expect(issue.severity, SyncIssueSeverity.error);
    expect(issue.category, SyncIssueCategory.schema);
    expect(issue.occurrenceCount, 3);
    expect(issue.details['table'], 'tasks');
  });
}
