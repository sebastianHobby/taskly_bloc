import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// Default timeout for total test duration.
///
/// Flutter's `@Timeout` only triggers on inactivity; this is a hard timeout.
const Duration kDefaultTestTimeout = Duration(seconds: 30);

@isTest
void testWidgetsSafe(
  String description,
  Future<void> Function(WidgetTester) callback, {
  Duration timeout = kDefaultTestTimeout,
  bool skip = false,
  dynamic tags,
}) {
  testWidgets(description, skip: skip, tags: tags, (tester) async {
    await callback(tester).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'Test "$description" exceeded ${timeout.inSeconds}s total duration. '
          'Check for: pumpAndSettle() with streams, unclosed subscriptions, '
          'or infinite animations.',
          timeout,
        );
      },
    );
  });
}

@isTest
void testSafe(
  String description,
  Future<void> Function() callback, {
  Duration timeout = kDefaultTestTimeout,
  bool skip = false,
  dynamic tags,
}) {
  test(description, skip: skip, tags: tags, () async {
    await callback().timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'Test "$description" exceeded ${timeout.inSeconds}s total duration. '
          'Check for unresolved futures or infinite streams.',
          timeout,
        );
      },
    );
  });
}
