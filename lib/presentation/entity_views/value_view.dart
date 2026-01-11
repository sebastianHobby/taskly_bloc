import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/value_stats.dart' as domain;
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/enhanced_value_card.dart';

/// The canonical, entity-level value UI entrypoint.
///
/// This starts as a delegating wrapper and is migrated into the
/// `ValueView` implementation in later phases.
class ValueView extends StatelessWidget {
  const ValueView({
    required this.value,
    this.rank,
    this.stats,
    this.onTap,
    this.compact = false,
    this.notRankedMessage,
    this.showDragHandle = false,
    super.key,
  });

  final Value value;
  final domain.ValueStats? stats;
  final int? rank;
  final VoidCallback? onTap;
  final bool compact;
  final String? notRankedMessage;
  final bool showDragHandle;

  ValueStats? get _presentationStats {
    final s = stats;
    if (s == null) return null;

    return ValueStats(
      targetPercent: s.targetPercent,
      actualPercent: s.actualPercent,
      taskCount: s.taskCount,
      projectCount: s.projectCount,
      weeklyTrend: s.weeklyTrend,
      gapWarningThreshold: s.gapWarningThreshold,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return EnhancedValueCard.compact(
        value: value,
        rank: rank,
        stats: _presentationStats,
        onTap: onTap,
        notRankedMessage: notRankedMessage,
        showDragHandle: showDragHandle,
      );
    }

    return EnhancedValueCard(
      value: value,
      rank: rank,
      stats: _presentationStats,
      onTap: onTap,
      compact: compact,
      notRankedMessage: notRankedMessage,
      showDragHandle: showDragHandle,
    );
  }
}
