import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:taskly_bloc/bootstrap/debug_dump.dart';
import 'package:taskly_core/logging.dart';

void installGlobalErrorCapture() {
  FlutterError.onError = (details) {
    final routeSummary = appRouteObserver.currentRouteSummary;
    final signature =
        'FlutterError:${details.exceptionAsString()}|route:$routeSummary';

    final message = StringBuffer()
      ..writeln('Flutter framework error: ${details.exceptionAsString()}')
      ..writeln('route: $routeSummary')
      ..writeln('library: ${details.library ?? "<null>"}')
      ..writeln('context: ${details.context ?? "<null>"}')
      ..writeln('silent: ${details.silent}')
      ..writeln('--- FlutterErrorDetails ---')
      ..writeln(details.toString());

    talker.handle(
      details.exception,
      details.stack,
      message.toString(),
    );

    maybeDumpDebugTreesToTalker(
      source: 'FlutterError.onError',
      signature: signature,
      routeSummary: routeSummary,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final routeSummary = appRouteObserver.currentRouteSummary;
    talker.handle(
      error,
      stack,
      'Uncaught platform error\nroute: $routeSummary',
    );

    maybeDumpDebugTreesToTalker(
      source: 'PlatformDispatcher.onError',
      signature: 'PlatformError:$error|route:$routeSummary',
      routeSummary: routeSummary,
    );
    return !talker.failFastPolicy.enabled;
  };
}

Future<void> runWithBootstrapErrorCapture(
  Future<void> Function() action,
) async {
  await (runZonedGuarded<Future<void>>(
        action,
        (error, stack) {
          final routeSummary = appRouteObserver.currentRouteSummary;
          talker.handle(
            error,
            stack,
            'Uncaught zone error\nroute: $routeSummary',
          );

          maybeDumpDebugTreesToTalker(
            source: 'runZonedGuarded',
            signature: 'ZoneError:$error|route:$routeSummary',
            routeSummary: routeSummary,
          );
        },
      ) ??
      Future<void>.value());
}
