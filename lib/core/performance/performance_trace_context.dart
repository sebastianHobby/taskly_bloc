import 'dart:async';

import 'package:flutter/widgets.dart';

/// Process-global correlation context for performance logs.
///
/// This is intentionally lightweight and decoupled from DI so it can be used
/// from navigator observers and low-level layers.
final class PerformanceTraceContext {
  PerformanceTraceContext._();

  static final PerformanceTraceContext instance = PerformanceTraceContext._();

  static int _counter = 0;

  String? _navigationTraceId;
  String? _routeSummary;

  /// A screen trace id for the *currently loading* (or most recently started)
  /// screen.
  ///
  /// This is used to correlate events across layers without threading IDs
  /// through every method signature.
  String? currentScreenTraceId;

  String? get currentNavigationTraceId => _navigationTraceId;

  String get currentRouteSummary => _routeSummary ?? '<unknown>';

  /// Returns the best available trace id for correlating log lines.
  ///
  /// Prefer screen trace when present; otherwise fall back to navigation trace.
  String? get currentTraceId => currentScreenTraceId ?? _navigationTraceId;

  String newTraceId(String prefix) {
    final n = ++_counter;
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$ts-$n';
  }

  void onRouteChanged(Route<dynamic>? route) {
    _navigationTraceId = newTraceId('nav');
    _routeSummary = _describeRoute(route);

    // Clear screen trace; the next screen load should set it.
    currentScreenTraceId = null;
  }

  String _describeRoute(Route<dynamic>? route) {
    if (route == null) return '<null>';

    final settings = route.settings;
    final name = settings.name;
    final args = settings.arguments;

    return '${route.runtimeType}(name=${name ?? "<null>"}, args=${_formatArgs(args)})';
  }

  String _formatArgs(Object? args) {
    if (args == null) return '<null>';

    final typeName = args.runtimeType.toString();
    final text = args.toString();
    const maxLen = 240;
    final truncated = text.length <= maxLen
        ? text
        : '${text.substring(0, maxLen)}…';

    return '$typeName:$truncated';
  }
}

/// Runs [callback] in a microtask so it is safe to call from observers.
Future<void> scheduleMicrotask(VoidCallback callback) async {
  await Future<void>.microtask(callback);
}
