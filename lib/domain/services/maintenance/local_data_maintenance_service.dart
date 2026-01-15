import 'package:powersync/powersync.dart' show PowerSyncDatabase;

/// Wraps local PowerSync maintenance operations.
class LocalDataMaintenanceService {
  LocalDataMaintenanceService({required PowerSyncDatabase database})
    : _database = database;

  final PowerSyncDatabase _database;

  /// Disconnects from sync and clears all locally cached data.
  Future<void> clearLocalData() async {
    await _database.disconnect();
    await _database.disconnectedAndClear();
  }
}
