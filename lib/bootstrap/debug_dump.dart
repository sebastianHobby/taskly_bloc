import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:taskly_core/logging.dart';

DateTime? _lastDebugDumpAt;
String? _lastDebugDumpSignature;

const _debugDumpThrottleWindow = Duration(seconds: 5);

String _captureDebugPrintOutput(void Function() action) {
  final buffer = StringBuffer();
  final previousDebugPrint = debugPrint;

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null) return;
    buffer.writeln(message);
    previousDebugPrint(message, wrapWidth: wrapWidth);
  };

  try {
    action();
  } catch (e, s) {
    buffer
      ..writeln('--- debug dump threw ---')
      ..writeln(e)
      ..writeln(s);
  } finally {
    debugPrint = previousDebugPrint;
  }

  return buffer.toString();
}

String _truncateForLog(String text, {int maxChars = 120000}) {
  if (text.length <= maxChars) return text;

  const headChars = 90000;
  const tailChars = 25000;
  final head = text.substring(0, headChars);
  final tail = text.substring(text.length - tailChars);
  return '$head\n\n--- TRUNCATED (${text.length} chars total) ---\n\n$tail';
}

void maybeDumpDebugTreesToTalker({
  required String source,
  required String signature,
  required String routeSummary,
}) {
  if (!kDebugMode) return;

  final now = DateTime.now();
  final shouldThrottle =
      _lastDebugDumpAt != null &&
      _lastDebugDumpSignature == signature &&
      now.difference(_lastDebugDumpAt!) < _debugDumpThrottleWindow;

  if (shouldThrottle) return;

  _lastDebugDumpAt = now;
  _lastDebugDumpSignature = signature;

  final appDump = _captureDebugPrintOutput(debugDumpApp);
  talker.warning(
    _truncateForLog(
      '--- debugDumpApp ($source) ---\nroute: $routeSummary\n\n$appDump',
    ),
  );

  // Post-frame dump is usually more reliable for constraint/size issues.
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderDump = _captureDebugPrintOutput(debugDumpRenderTree);
      talker.warning(
        _truncateForLog(
          '--- debugDumpRenderTree ($source, post-frame) ---\n'
          'route: $routeSummary\n\n$renderDump',
        ),
      );
    });
  } catch (_) {
    // If bindings aren't available for some reason, fall back to immediate.
    final renderDump = _captureDebugPrintOutput(debugDumpRenderTree);
    talker.warning(
      _truncateForLog(
        '--- debugDumpRenderTree ($source, immediate) ---\n'
        'route: $routeSummary\n\n$renderDump',
      ),
    );
  }
}
