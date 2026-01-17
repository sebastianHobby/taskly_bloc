import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_domain/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_domain/domain/attention/model/attention_item.dart';
import 'package:taskly_domain/domain/attention/model/attention_rule.dart';
import 'package:taskly_domain/domain/attention/query/attention_query.dart';

class AttentionBellState {
  const AttentionBellState({
    required this.totalCount,
    required this.criticalCount,
    required this.warningCount,
    required this.isLoading,
    required this.error,
  });

  factory AttentionBellState.loading() => const AttentionBellState(
    totalCount: 0,
    criticalCount: 0,
    warningCount: 0,
    isLoading: true,
    error: null,
  );

  factory AttentionBellState.data({
    required int totalCount,
    required int criticalCount,
    required int warningCount,
  }) {
    return AttentionBellState(
      totalCount: totalCount,
      criticalCount: criticalCount,
      warningCount: warningCount,
      isLoading: false,
      error: null,
    );
  }

  final int totalCount;
  final int criticalCount;
  final int warningCount;

  final bool isLoading;
  final Object? error;
}

class AttentionBellCubit extends Cubit<AttentionBellState> {
  AttentionBellCubit({required AttentionEngineContract engine})
    : _engine = engine,
      super(AttentionBellState.loading()) {
    _sub = _engine
        .watch(
          const AttentionQuery(
            buckets: {AttentionBucket.action, AttentionBucket.review},
          ),
        )
        .listen(_onItems, onError: _onError);
  }

  final AttentionEngineContract _engine;
  StreamSubscription<List<AttentionItem>>? _sub;

  void _onItems(List<AttentionItem> items) {
    final criticalCount = items
        .where((i) => i.severity == AttentionSeverity.critical)
        .length;
    final warningCount = items
        .where((i) => i.severity == AttentionSeverity.warning)
        .length;

    emit(
      AttentionBellState.data(
        totalCount: items.length,
        criticalCount: criticalCount,
        warningCount: warningCount,
      ),
    );
  }

  void _onError(Object error, StackTrace stackTrace) {
    emit(
      AttentionBellState(
        totalCount: state.totalCount,
        criticalCount: state.criticalCount,
        warningCount: state.warningCount,
        isLoading: false,
        error: error,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }
}
