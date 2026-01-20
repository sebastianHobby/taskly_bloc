import 'package:powersync/powersync.dart';
import 'package:taskly_domain/services.dart';

final class PowerSyncInitialSyncService implements InitialSyncService {
  PowerSyncInitialSyncService(this._db);

  final PowerSyncDatabase _db;

  @override
  Stream<InitialSyncProgress> get progress {
    return _db.statusStream.map((status) {
      final progress = status.downloadProgress;
      final fraction = progress?.downloadedFraction;

      return InitialSyncProgress(
        connected: status.connected,
        connecting: status.connecting,
        downloading: status.downloading,
        uploading: status.uploading,
        hasSynced: status.hasSynced ?? false,
        downloadFraction: fraction,
        lastSyncedAt: status.lastSyncedAt,
      );
    });
  }

  @override
  Future<void> waitForFirstSync() async {
    final status = await _db.statusStream.first;
    if (status.hasSynced ?? false) return;

    await _db.waitForFirstSync();
  }
}
