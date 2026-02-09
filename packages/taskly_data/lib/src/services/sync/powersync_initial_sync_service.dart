import 'package:powersync/powersync.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_data/src/infrastructure/powersync/powersync_status_stream.dart';

final class PowerSyncInitialSyncService implements InitialSyncService {
  PowerSyncInitialSyncService(this._db)
    : _progress = sharedPowerSyncStatusStream(_db)
          .map((status) {
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
          })
          // Shared + replay-last so multiple UI listeners can attach safely.
          .shareValue();

  final PowerSyncDatabase _db;

  final ValueStream<InitialSyncProgress> _progress;

  @override
  Stream<InitialSyncProgress> get progress {
    return _progress;
  }

  @override
  Future<void> waitForFirstSync() async {
    final initial = await _progress.first;
    if (initial.hasSynced) return;

    await _db.waitForFirstSync();
  }
}
