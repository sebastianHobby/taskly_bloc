import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/telemetry.dart';

/// Global unexpected-error reporter.
///
/// Expected/user-actionable failures remain screen-owned.
/// Unexpected errors are logged with structured fields and surfaced as a
/// minimal snackbar (debug + prod) with throttling.
final class AppErrorReporter {
  AppErrorReporter({required GlobalKey<ScaffoldMessengerState> messengerKey})
    : _messengerKey = messengerKey;

  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  DateTime? _lastSnackAt;

  void reportUnexpected(
    Object error,
    StackTrace stackTrace, {
    OperationContext? context,
    String? message,
    Duration snackThrottle = const Duration(seconds: 3),
  }) {
    final fields = context?.toLogFields() ?? const <String, Object?>{};

    AppLog.handleStructured(
      'app.unexpected',
      message ?? 'Unexpected error',
      error,
      stackTrace,
      fields,
    );

    final now = DateTime.now();
    final last = _lastSnackAt;
    if (last != null && now.difference(last) < snackThrottle) return;
    _lastSnackAt = now;

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;

    final correlationId = context?.correlationId;

    final snackText = kDebugMode
        ? 'Unexpected error (${error.runtimeType})'
              '${correlationId == null ? '' : ' • $correlationId'}'
        : 'Something went wrong. Please try again.';

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(snackText)));
  }
}
