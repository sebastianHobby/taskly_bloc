import 'package:meta/meta.dart';

/// Snapshot of the client sync lifecycle intended for UI gating.
///
/// This intentionally does not expose PowerSync SDK types.
@immutable
final class InitialSyncProgress {
  const InitialSyncProgress({
    required this.connected,
    required this.connecting,
    required this.downloading,
    required this.uploading,
    required this.hasSynced,
    this.downloadFraction,
    this.lastSyncedAt,
  });

  final bool connected;
  final bool connecting;
  final bool downloading;
  final bool uploading;

  /// True once the local DB has reached a first consistent sync checkpoint.
  final bool hasSynced;

  /// 0..1 when known.
  final double? downloadFraction;

  /// Last completed sync time when known.
  final DateTime? lastSyncedAt;
}

/// Exposes initial sync status and a completion signal.
///
/// The app uses this to gate first-time authenticated UX until the local
/// database is populated.
abstract interface class InitialSyncService {
  /// Emits snapshots of the sync lifecycle.
  ///
  /// Stream contract:
  /// - broadcast: **required** (multiple listeners may observe progress)
  /// - replay: implementation-defined (prefer replay-last for UI)
  /// - cold/hot: typically **hot** (backed by the sync runtime)
  Stream<InitialSyncProgress> get progress;

  /// Completes once the first full sync checkpoint is reached.
  Future<void> waitForFirstSync();
}
