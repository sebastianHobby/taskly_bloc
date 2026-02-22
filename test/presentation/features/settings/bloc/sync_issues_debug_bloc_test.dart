@Tags(['unit', 'settings'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/sync_issues_debug_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

import '../../../../helpers/test_imports.dart';

class _MockSyncIssueRepository extends Mock
    implements SyncIssueRepositoryContract {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late _MockSyncIssueRepository repository;

  setUp(() {
    repository = _MockSyncIssueRepository();
  });

  blocTestSafe<SyncIssuesDebugBloc, SyncIssuesDebugState>(
    'loads issues on start',
    build: () {
      when(
        () => repository.fetchOpen(limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          SyncIssue(
            id: 'issue-1',
            userId: 'user-1',
            status: SyncIssueStatus.open,
            severity: SyncIssueSeverity.error,
            category: SyncIssueCategory.pipeline,
            fingerprint: 'fp-1',
            issueCode: 'schema_not_found',
            title: 'Sync anomaly',
            message: 'sync failed',
            details: const {},
            firstSeenAt: DateTime.utc(2026, 2, 1),
            lastSeenAt: DateTime.utc(2026, 2, 2),
            occurrenceCount: 1,
            createdAt: DateTime.utc(2026, 2, 1),
            updatedAt: DateTime.utc(2026, 2, 2),
          ),
        ],
      );
      return SyncIssuesDebugBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const SyncIssuesDebugStarted()),
    expect: () => [
      isA<SyncIssuesDebugState>().having((s) => s.loading, 'loading', true),
      isA<SyncIssuesDebugState>()
          .having((s) => s.loading, 'loading', false)
          .having((s) => s.issues.length, 'issues length', 1),
    ],
  );
}
