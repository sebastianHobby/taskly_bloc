import 'package:powersync/powersync.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/services.dart';

final class PowerSyncInitialSyncService implements InitialSyncService {
  PowerSyncInitialSyncService(this._db)
    : _progress = _db.statusStream
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
    final status = await _db.statusStream.first;
    if (status.hasSynced ?? false) return;

    await _db.waitForFirstSync();
  }
}
