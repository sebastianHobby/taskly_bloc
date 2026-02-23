import 'dart:async';
import 'dart:io';

import '../helpers/test_imports.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_core/logging.dart';

void main() {
  group('TalkerFailFastPolicy additional coverage', () {
    testSafe('forTests disables fail-fast', () async {
      final policy = TalkerFailFastPolicy.forTests();
      expect(policy.enabled, isFalse);
    });

    testSafe(
      'allowlisted platform/network exceptions do not fail fast',
      () async {
        const policy = TalkerFailFastPolicy(enabled: true);
        expect(
          policy.shouldFailFastFor(const SocketException('offline')),
          isFalse,
        );
        expect(policy.shouldFailFastFor(TimeoutException('timeout')), isFalse);
      },
    );

    testSafe('TasklyTalker.error does not throw when error is null', () async {
      final backend = TasklyTalker(
        Talker(),
        failFastPolicy: const TalkerFailFastPolicy(
          enabled: true,
          messagePrefixes: <String>['Operation Failed:'],
        ),
      );

      expect(
        () => backend.error('Operation Failed: save', null, StackTrace.empty),
        returnsNormally,
      );
    });
  });
}
