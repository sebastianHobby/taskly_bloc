import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:taskly_core/logging.dart';

import 'package:taskly_bloc/core/performance/performance_thresholds.dart';
import 'package:taskly_bloc/core/performance/performance_trace_context.dart';

/// A single screen load trace focused on what the user perceives.
///
/// Lifecycle:
/// - start (navigation -> bloc load)
/// - mark loading emitted
/// - mark first data
/// - mark first paint
/// - end
final class ScreenPerformanceTrace {
  ScreenPerformanceTrace({
    required this.screenName,
    required this.screenId,
    required this.traceId,
    required this.routeSummary,
    bool enabled = kDebugMode,
  }) : _enabled = enabled,
       _startAt = enabled
           ? DateTime.now()
           : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  factory ScreenPerformanceTrace.disabled({
    required String screenName,
    required String screenId,
    required String traceId,
    required String routeSummary,
  }) {
    return ScreenPerformanceTrace(
      screenName: screenName,
      screenId: screenId,
      traceId: traceId,
      routeSummary: routeSummary,
      enabled: false,
    );
  }

  final String screenName;
  final String screenId;
  final String traceId;
  final String routeSummary;

  final bool _enabled;

  final DateTime _startAt;

  DateTime? _loadingEmittedAt;
  DateTime? _firstDataAt;
  DateTime? _firstPaintAt;

  bool _ended = false;

  void logStart() {
    if (!_enabled) return;
    developer.log(
      '📱 Screen: start "$screenName" (id=$screenId, trace=$traceId)',
      name: 'perf.screen',
    );
  }

  void markLoadingEmitted() {
    if (!_enabled) return;
    _loadingEmittedAt ??= DateTime.now();
    final ms = _loadingEmittedAt!.difference(_startAt).inMilliseconds;

    if (ms >= PerformanceThresholds.loadingEmitInfoMs) {
      talker.perf(
        'Screen "$screenName": loading emitted after ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    }
  }

  void markFirstData() {
    if (!_enabled) return;
    _firstDataAt ??= DateTime.now();
    final ms = _firstDataAt!.difference(_startAt).inMilliseconds;

    developer.log(
      '⏱️ Screen "$screenName": first data after ${ms}ms (trace=$traceId)',
      name: 'perf.screen.firstdata',
    );

    if (ms >= PerformanceThresholds.firstDataVerySlowMs) {
      talker.perf(
        'VERY SLOW Screen "$screenName": first data ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    } else if (ms >= PerformanceThresholds.firstDataSlowMs) {
      talker.perf(
        'Slow Screen "$screenName": first data ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    } else if (ms >= PerformanceThresholds.screenInfoMs) {
      talker.perf(
        'Screen "$screenName": first data ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    } else {
      talker.perf(
        'Screen "$screenName": first data ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    }
  }

  void markFirstPaint() {
    if (!_enabled) return;
    _firstPaintAt ??= DateTime.now();
    final ms = _firstPaintAt!.difference(_startAt).inMilliseconds;

    developer.log(
      '🎨 Screen "$screenName": first paint after ${ms}ms (trace=$traceId)',
      name: 'perf.screen.firstpaint',
      level: ms >= PerformanceThresholds.firstPaintSlowMs ? 900 : 800,
    );

    if (ms >= PerformanceThresholds.firstPaintSlowMs) {
      talker.perf(
        'Slow Screen "$screenName": first paint ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    } else if (ms >= PerformanceThresholds.firstPaintInfoMs) {
      talker.perf(
        'Screen "$screenName": first paint ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    } else {
      talker.perf(
        'Screen "$screenName": first paint ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    }
  }

  void endSuccess() {
    if (!_enabled) return;
    if (_ended) return;
    _ended = true;

    final firstPaintAt = _firstPaintAt;
    final ms = (firstPaintAt ?? DateTime.now())
        .difference(_startAt)
        .inMilliseconds;

    developer.log(
      '✅ Screen: "$screenName" ready in ${ms}ms '
      '(trace=$traceId, route=$routeSummary)',
      name: 'perf.screen',
      level: ms >= PerformanceThresholds.screenSlowMs ? 900 : 800,
    );

    if (ms >= PerformanceThresholds.screenSlowMs) {
      talker.perf(
        'Slow Screen "$screenName" load ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    } else if (ms >= PerformanceThresholds.screenInfoMs) {
      talker.perf(
        'Screen "$screenName" load ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    } else {
      talker.perf(
        'Screen "$screenName" load ${ms}ms (trace=$traceId)',
        category: 'screen',
      );
    }

    // Clear context if we're still the active trace.
    if (PerformanceTraceContext.instance.currentScreenTraceId == traceId) {
      PerformanceTraceContext.instance.currentScreenTraceId = null;
    }
  }

  void endError(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) return;
    if (_ended) return;
    _ended = true;

    talker.handle(
      error ?? FlutterError(message),
      stackTrace,
      '[Perf] Screen "$screenName" failed (trace=$traceId): $message',
    );

    if (PerformanceTraceContext.instance.currentScreenTraceId == traceId) {
      PerformanceTraceContext.instance.currentScreenTraceId = null;
    }
  }
}
