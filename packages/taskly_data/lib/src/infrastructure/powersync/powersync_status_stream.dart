import 'package:powersync/powersync.dart';
import 'package:rxdart/rxdart.dart';

final Expando<ValueStream<SyncStatus>> _sharedStatusStreams = Expando();

ValueStream<SyncStatus> sharedPowerSyncStatusStream(
  PowerSyncDatabase database,
) {
  final cached = _sharedStatusStreams[database];
  if (cached != null) return cached;

  final shared = database.statusStream.shareValue();
  _sharedStatusStreams[database] = shared;
  return shared;
}
