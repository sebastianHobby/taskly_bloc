import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';

@immutable
class AttentionBannerState {
  const AttentionBannerState({
    required this.isLoading,
    required this.actionCount,
    required this.reviewCount,
    required this.criticalCount,
    required this.warningCount,
    required this.infoCount,
    required this.previewItems,
    required this.errorMessage,
  });

  const AttentionBannerState.loading()
    : isLoading = true,
      actionCount = 0,
      reviewCount = 0,
      criticalCount = 0,
      warningCount = 0,
      infoCount = 0,
      previewItems = const <AttentionItem>[],
      errorMessage = null;

  final bool isLoading;
  final int actionCount;
  final int reviewCount;
  final int criticalCount;
  final int warningCount;
  final int infoCount;
  final List<AttentionItem> previewItems;
  final String? errorMessage;

  int get totalCount => actionCount + reviewCount;

  AttentionBannerState copyWith({
    bool? isLoading,
    int? actionCount,
    int? reviewCount,
    int? criticalCount,
    int? warningCount,
    int? infoCount,
    List<AttentionItem>? previewItems,
    String? errorMessage,
  }) {
    return AttentionBannerState(
      isLoading: isLoading ?? this.isLoading,
      actionCount: actionCount ?? this.actionCount,
      reviewCount: reviewCount ?? this.reviewCount,
      criticalCount: criticalCount ?? this.criticalCount,
      warningCount: warningCount ?? this.warningCount,
      infoCount: infoCount ?? this.infoCount,
      previewItems: previewItems ?? this.previewItems,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttentionBannerState &&
            other.isLoading == isLoading &&
            other.actionCount == actionCount &&
            other.reviewCount == reviewCount &&
            other.criticalCount == criticalCount &&
            other.warningCount == warningCount &&
            other.infoCount == infoCount &&
            listEquals(other.previewItems, previewItems) &&
            other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    isLoading,
    actionCount,
    reviewCount,
    criticalCount,
    warningCount,
    infoCount,
    Object.hashAll(previewItems),
    errorMessage,
  );
}

/// Global banner state for attention counts.
///
/// Design intent: a single bloc instance powers the attention banner anywhere
/// it is shown. Individual screens can only show/hide the banner surface.
class AttentionBannerBloc extends Cubit<AttentionBannerState> {
  AttentionBannerBloc({
    required AttentionEngineContract engine,
    int previewLimit = 2,
  }) : _engine = engine,
       _previewLimit = previewLimit,
       super(const AttentionBannerState.loading()) {
    _start();
  }

  static const String overflowScreenKey = 'review_inbox';

  final AttentionEngineContract _engine;
  final int _previewLimit;

  StreamSubscription<List<AttentionItem>>? _sub;

  static const AttentionQuery _query = AttentionQuery(
    buckets: {AttentionBucket.action, AttentionBucket.review},
  );

  void _start() {
    _sub?.cancel();
    _sub = _engine
        .watch(_query)
        .listen(
          _onItems,
          onError: (Object e, _) {
            emit(
              state.copyWith(
                isLoading: false,
                previewItems: const <AttentionItem>[],
                errorMessage: e.toString(),
              ),
            );
          },
        );
  }

  void _onItems(List<AttentionItem> items) {
    final actionCount = items
        .where((i) => i.bucket == AttentionBucket.action)
        .length;
    final reviewCount = items
        .where((i) => i.bucket == AttentionBucket.review)
        .length;

    final criticalCount = items
        .where((i) => i.severity == AttentionSeverity.critical)
        .length;
    final warningCount = items
        .where((i) => i.severity == AttentionSeverity.warning)
        .length;
    final infoCount = items.length - criticalCount - warningCount;

    emit(
      state.copyWith(
        isLoading: false,
        actionCount: actionCount,
        reviewCount: reviewCount,
        criticalCount: criticalCount,
        warningCount: warningCount,
        infoCount: infoCount,
        previewItems: items.take(_previewLimit).toList(growable: false),
        errorMessage: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
