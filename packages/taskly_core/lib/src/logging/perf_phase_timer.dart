import 'package:flutter/foundation.dart';

import 'package:taskly_core/logging_internal.dart';

/// Lightweight phase-based timing helper.
///
/// Designed for coarse, low-overhead "what part is slow?" diagnostics.
/// Logs only in non-release builds.
class PerfPhaseTimer {
  PerfPhaseTimer(
    this.label, {
    required this.category,
    this.slowPhaseThresholdMs = 50,
    this.slowTotalThresholdMs = 100,
  }) : _total = Stopwatch()..start();

  final String label;
  final String category;

  /// Logs individual phases at/above this threshold.
  final int slowPhaseThresholdMs;

  /// Logs a summary when total time reaches/exceeds this threshold.
  final int slowTotalThresholdMs;

  final Stopwatch _total;
  final Map<String, int> _phaseMs = <String, int>{};

  T phase<T>(String name, T Function() action) {
    if (kReleaseMode) {
      return action();
    }

    final sw = Stopwatch()..start();
    final result = action();
    sw.stop();
    _phaseMs[name] = (_phaseMs[name] ?? 0) + sw.elapsedMilliseconds;
    return result;
  }

  void finish() {
    if (kReleaseMode) return;

    _total.stop();
    final totalMs = _total.elapsedMilliseconds;
    if (totalMs <= 0) return;

    final slowPhases = _phaseMs.entries
        .where((e) => e.value >= slowPhaseThresholdMs)
        .toList(growable: false);

    if (totalMs < slowTotalThresholdMs && slowPhases.isEmpty) return;

    final phaseSummary = _phaseMs.entries
        .map((e) => '${e.key}=${e.value}ms')
        .join(', ');

    talker.perf(
      '⏱️ $label phases: total=${totalMs}ms${phaseSummary.isEmpty ? '' : ' ($phaseSummary)'}',
      category: category,
    );

    for (final p in slowPhases) {
      talker.perf(
        '⚠️ $label slow phase: ${p.key} ${p.value}ms',
        category: category,
      );
    }
  }
}
