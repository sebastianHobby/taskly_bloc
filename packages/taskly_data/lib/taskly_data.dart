/// Taskly data package public API.
///
/// Best practice for this repo: keep `taskly_data`'s public API small.
///
/// - The app should initialize the data stack through the facade and depend on
///   `taskly_domain` contracts for everything else.
/// - Infrastructure and implementation details (Supabase/PowerSync/Drift,
///   repository implementations, mappers) should not be part of the public API.
library;

export 'data_stack.dart';
export 'db.dart';
export 'id.dart';
export 'repository_exceptions.dart';
export 'sync.dart';
