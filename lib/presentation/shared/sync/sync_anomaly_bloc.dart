import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:taskly_domain/telemetry.dart';

sealed class SyncAnomalyEvent {
  const SyncAnomalyEvent();
}

final class SyncAnomalyReceived extends SyncAnomalyEvent {
  const SyncAnomalyReceived(this.anomaly);

  final SyncAnomaly anomaly;
}

@immutable
final class SyncAnomalyState {
  const SyncAnomalyState({this.lastAnomaly, this.sequence = 0});

  final SyncAnomaly? lastAnomaly;

  /// Monotonically increasing counter used for `listenWhen`.
  final int sequence;

  SyncAnomalyState copyWith({SyncAnomaly? lastAnomaly, int? sequence}) {
    return SyncAnomalyState(
      lastAnomaly: lastAnomaly ?? this.lastAnomaly,
      sequence: sequence ?? this.sequence,
    );
  }
}

/// Presentation-owned bridge that converts [SyncAnomalyStream] into BLoC state.
///
/// This keeps widgets from subscribing to cross-layer streams directly.
final class SyncAnomalyBloc extends Bloc<SyncAnomalyEvent, SyncAnomalyState> {
  SyncAnomalyBloc({required SyncAnomalyStream source})
    : _source = source,
      super(const SyncAnomalyState()) {
    on<SyncAnomalyReceived>(_onReceived);
    _subscription = _source.anomalies.listen(
      (a) => add(SyncAnomalyReceived(a)),
    );
  }

  final SyncAnomalyStream _source;
  late final StreamSubscription<SyncAnomaly> _subscription;

  void _onReceived(SyncAnomalyReceived event, Emitter<SyncAnomalyState> emit) {
    emit(
      state.copyWith(
        lastAnomaly: event.anomaly,
        sequence: state.sequence + 1,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
