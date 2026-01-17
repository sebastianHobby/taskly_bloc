/// Public entrypoint for Taskly's day-1 data stack.
///
/// This facade is the app's primary way to initialize:
/// - Supabase (auth + PostgREST)
/// - PowerSync (local sync DB)
/// - Drift AppDatabase (offline-first local source of truth)
/// - Post-auth maintenance (seeders / cleanup)
library;

export 'src/data_stack/taskly_data_stack.dart';
