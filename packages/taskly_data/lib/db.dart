/// Drift database entrypoint for `taskly_data`.
///
/// This is intentionally small: production code should prefer repository
/// contracts and [TasklyDataStack] over direct DB access.
library;

export 'src/infrastructure/drift/drift_database.dart';
