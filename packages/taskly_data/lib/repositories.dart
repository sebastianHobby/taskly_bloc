/// Repository implementations entrypoint for `taskly_data`.
///
/// Prefer using `taskly_domain` repository *contracts* in production code.
/// This entrypoint exists for:
/// - app composition roots that need concrete implementations
/// - integration/e2e tests that intentionally exercise the data layer
library;

export 'src/repositories/auth_repository.dart';
export 'src/repositories/project_repository.dart';
export 'src/repositories/settings_repository.dart';
export 'src/repositories/task_repository.dart';
export 'src/repositories/value_repository.dart';

export 'src/repositories/query_stream_cache.dart';
export 'src/repositories/repository_helpers.dart';

export 'src/allocation/repositories/allocation_snapshot_repository.dart';
export 'src/attention/repositories/attention_repository_v2.dart';

export 'src/features/analytics/repositories/analytics_repository_impl.dart';
export 'src/features/analytics/services/analytics_service_impl.dart';

export 'src/features/journal/maintenance/journal_tracker_seeder.dart';
export 'src/features/journal/repositories/journal_repository_impl.dart';

export 'src/features/notifications/repositories/pending_notifications_repository_impl.dart';
export 'src/features/notifications/services/logging_notification_presenter.dart';
