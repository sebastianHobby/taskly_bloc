import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

const Duration kDefaultTestTimeout = Duration(seconds: 30);

@isTest
void testSafe(
  String description,
  Future<void> Function() callback, {
  Duration timeout = kDefaultTestTimeout,
  bool skip = false,
  dynamic tags,
}) {
  test(
    description,
    skip: skip,
    tags: tags,
    () async {
      await callback().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Test "$description" exceeded ${timeout.inSeconds}s total duration.',
            timeout,
          );
        },
      );
    },
  );
}
