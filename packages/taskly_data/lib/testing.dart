/// Test-support entrypoint for `taskly_data`.
///
/// This library intentionally exposes low-level infrastructure pieces that are
/// needed by integration/e2e tests (e.g., the PowerSync/Supabase pipeline).
///
/// Production code should prefer:
/// - `package:taskly_data/data_stack.dart`
/// - `taskly_domain` contracts
library;

export 'data/id/id_generator.dart';
export 'data/infrastructure/drift/drift_database.dart';
export 'data/infrastructure/powersync/api_connector.dart';
export 'data/infrastructure/supabase/supabase.dart';

export 'data/repositories/auth_repository.dart';
export 'data/repositories/project_repository.dart';
export 'data/repositories/settings_repository.dart';
export 'data/repositories/task_repository.dart';
export 'data/repositories/value_repository.dart';

export 'data/attention/repositories/attention_repository_v2.dart';
export 'data/allocation/repositories/allocation_snapshot_repository.dart';

export 'data/features/analytics/repositories/analytics_repository_impl.dart';
export 'data/features/journal/repositories/journal_repository_impl.dart';
export 'data/features/notifications/repositories/pending_notifications_repository_impl.dart';

export 'data/repositories/repository_exceptions.dart';
