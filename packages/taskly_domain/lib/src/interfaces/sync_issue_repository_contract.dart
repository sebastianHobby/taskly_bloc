import 'package:taskly_domain/src/telemetry/sync_anomaly.dart';
import 'package:taskly_domain/src/telemetry/sync_issue.dart';

abstract interface class SyncIssueRepositoryContract {
  Future<void> recordAnomaly(SyncAnomaly anomaly);

  Future<List<SyncIssue>> fetchOpen({int limit = 100});
}
