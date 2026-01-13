import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';

import 'package:taskly_bloc/core/performance/performance_trace_context.dart';
import 'package:taskly_bloc/core/performance/screen_performance_trace.dart';

/// Central entry point for performance logging.
///
/// This focuses on user-visible metrics like screen load times.
class PerformanceLogger {
  ScreenPerformanceTrace? _activeScreenTrace;

  ScreenPerformanceTrace startScreenTrace({
    required String screenName,
    required String screenId,
  }) {
    if (!kDebugMode) {
      return ScreenPerformanceTrace.disabled(
        screenName: screenName,
        screenId: screenId,
        traceId: 'disabled',
        routeSummary: PerformanceTraceContext.instance.currentRouteSummary,
      );
    }

    final ctx = PerformanceTraceContext.instance;

    final traceId = ctx.newTraceId('screen');
    ctx.currentScreenTraceId = traceId;

    final trace = ScreenPerformanceTrace(
      screenName: screenName,
      screenId: screenId,
      traceId: traceId,
      routeSummary: ctx.currentRouteSummary,
    )..logStart();

    _activeScreenTrace = trace;
    return trace;
  }

  /// Marks first paint for the current screen trace (if any).
  ///
  /// Intended to be called via `addPostFrameCallback` when the screen first
  /// transitions to a loaded UI.
  void markFirstPaint() {
    final trace = _activeScreenTrace;
    if (trace == null) return;

    // Only mark once.
    trace.markFirstPaint();
    trace.endSuccess();

    if (identical(_activeScreenTrace, trace)) {
      _activeScreenTrace = null;
    }
  }

  /// Creates a span for ad-hoc timing.
  PerfSpan startSpan(String name, {Map<String, Object?> tags = const {}}) {
    if (!kDebugMode) return PerfSpan.disabled(name: name, tags: tags);
    return PerfSpan._(name: name, tags: tags);
  }
}

/// Timing span for profiling specific operations.
///
/// Use `try/finally` to ensure [end] is called.
final class PerfSpan {
  PerfSpan._({required this.name, required this.tags})
    : _enabled = true,
      _startAt = DateTime.now();

  PerfSpan.disabled({required this.name, required this.tags})
    : _enabled = false,
      _startAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  final String name;
  final Map<String, Object?> tags;

  final DateTime _startAt;
  final bool _enabled;
  bool _ended = false;

  void end({String? message}) {
    if (!_enabled) return;
    if (_ended) return;
    _ended = true;

    final ms = DateTime.now().difference(_startAt).inMilliseconds;
    final traceId = PerformanceTraceContext.instance.currentTraceId;

    developer.log(
      '⏱️ Span "$name": ${ms}ms '
      '(trace=${traceId ?? "-"}, tags=$tags${message == null ? "" : ", msg=$message"})',
      name: 'perf.span',
      level: 800,
    );

    // Keep Talker output high-signal; log only if slow.
    if (ms >= 500) {
      talker.perf(
        'Span "$name" slow: ${ms}ms (trace=${traceId ?? "-"})',
        category: 'span',
      );
    }
  }
}
