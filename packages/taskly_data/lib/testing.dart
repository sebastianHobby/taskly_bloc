/// Test-support entrypoint for `taskly_data`.
///
/// This library intentionally exposes low-level infrastructure pieces that are
/// needed by integration/e2e tests (e.g., the PowerSync/Supabase pipeline).
///
/// Production code should prefer:
/// - `package:taskly_data/data_stack.dart`
/// - `taskly_domain` contracts
library;

export 'src/id/id_generator.dart';
export 'src/infrastructure/drift/drift_database.dart';
export 'src/infrastructure/powersync/api_connector.dart';
export 'src/infrastructure/powersync/schema.dart';
export 'src/infrastructure/powersync/upload_data_normalizer.dart';
export 'src/infrastructure/supabase/supabase.dart';

export 'src/infrastructure/drift/converters/date_only_string_converter.dart';
export 'src/infrastructure/drift/converters/json_converters.dart';

export 'src/mappers/drift_to_domain.dart';

export 'src/repositories/auth_repository.dart';
export 'src/repositories/project_repository.dart';
export 'src/repositories/settings_repository.dart';
export 'src/repositories/task_repository.dart';
export 'src/repositories/value_repository.dart';
export 'src/repositories/query_stream_cache.dart';
export 'src/repositories/repository_helpers.dart';

export 'src/attention/repositories/attention_repository_v2.dart';

export 'src/features/analytics/repositories/analytics_repository_impl.dart';
export 'src/features/analytics/services/analytics_service_impl.dart';
export 'src/features/journal/repositories/journal_repository_impl.dart';
export 'src/features/journal/maintenance/journal_tracker_seeder.dart';
export 'src/features/notifications/repositories/pending_notifications_repository_impl.dart';
export 'src/features/notifications/services/logging_notification_presenter.dart';

export 'src/repositories/repository_exceptions.dart';
