@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/telemetry/sync_anomaly.dart';

void main() {
  testSafe('SyncAnomaly.debugSummary includes core fields', () async {
    final anomaly = SyncAnomaly(
      kind: SyncAnomalyKind.conflictResolvedWithRemote,
      occurredAt: DateTime.utc(2026, 1, 18),
      table: 'tasks',
      rowId: 't1',
      operation: 'put',
      reason: SyncAnomalyReason.schemaNotFound,
      remoteCode: '42',
      correlationId: 'cid-1',
    );

    final summary = anomaly.debugSummary();

    expect(summary, contains('conflictResolvedWithRemote'));
    expect(summary, contains('tasks/t1'));
    expect(summary, contains('put'));
    expect(summary, contains('schemaNotFound'));
    expect(summary, contains('code=42'));
    expect(summary, contains('cid=cid-1'));
  });

  testSafe('SyncAnomaly.debugSummary can omit correlation id', () async {
    final anomaly = SyncAnomaly(
      kind: SyncAnomalyKind.supabaseRejectedButLocalApplied,
      occurredAt: DateTime.utc(2026, 1, 18),
      table: 'projects',
      rowId: 'p1',
      correlationId: 'cid-2',
    );

    final summary = anomaly.debugSummary(includeCorrelationId: false);
    expect(summary, isNot(contains('cid=')));
  });

  testSafe('SyncAnomaly.toString includes kind and table', () async {
    final anomaly = SyncAnomaly(
      kind: SyncAnomalyKind.conflictResolvedWithLocal,
      occurredAt: DateTime.utc(2026, 1, 18),
      table: 'values',
      rowId: 'v1',
    );

    expect(
      anomaly.toString(),
      contains('kind=SyncAnomalyKind.conflictResolvedWithLocal'),
    );
    expect(anomaly.toString(), contains('table=values'));
  });
}
