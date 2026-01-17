/// Maintenance operations for local/offline data.
///
/// This lives in the domain package as a contract so the app/presentation does
/// not need to know about the concrete sync implementation (PowerSync, etc).
abstract interface class LocalDataMaintenanceService {
  /// Disconnects from sync and clears all locally cached data.
  Future<void> clearLocalData();
}
