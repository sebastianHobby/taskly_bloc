@Tags(['unit'])
library;

import 'dart:async';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/shared/sync/sync_anomaly_bloc.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late _FakeSyncAnomalyStream _source;

  blocTestSafe<SyncAnomalyBloc, SyncAnomalyState>(
    'updates state when anomalies are received',
    build: () {
      _source = _FakeSyncAnomalyStream();
      addTearDown(_source.close);
      return SyncAnomalyBloc(source: _source);
    },
    act: (bloc) {
      _source.emit(
        SyncAnomaly(
          kind: SyncAnomalyKind.supabaseRejectedButLocalApplied,
          occurredAt: DateTime.utc(2025, 1, 15),
          table: 'tasks',
          rowId: 'task-1',
        ),
      );
    },
    expect: () => [
      isA<SyncAnomalyState>()
          .having((s) => s.sequence, 'sequence', 1)
          .having((s) => s.lastAnomaly?.rowId, 'rowId', 'task-1'),
    ],
  );
}

final class _FakeSyncAnomalyStream implements SyncAnomalyStream {
  final TestStreamController<SyncAnomaly> _controller =
      TestStreamController<SyncAnomaly>();

  @override
  Stream<SyncAnomaly> get anomalies => _controller.stream;

  void emit(SyncAnomaly anomaly) => _controller.emit(anomaly);

  Future<void> close() => _controller.close();
}
