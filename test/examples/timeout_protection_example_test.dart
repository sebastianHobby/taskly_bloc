/// Timeout protection demonstration tests.
///
/// These tests demonstrate various timeout scenarios and how to protect against them.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bloc_test_helpers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Timeout Protection Examples -', () {
    group('Vulnerable patterns (will timeout correctly) -', () {
      testWidgetsWithTimeout(
        'Continuous pumping should timeout after 2 seconds',
        timeout: const Duration(seconds: 2),
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Test'))),
          );

          // This will timeout because total duration exceeds 2 seconds
          // Even though we're "active" (pumping frames)
          try {
            for (var i = 0; i < 1000; i++) {
              await tester.pump();
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
            fail('Should have timed out before reaching here');
          } on TimeoutException catch (e) {
            expect(e.message, contains('exceeded total duration limit'));
            // Test passes - timeout worked correctly!
          }
        },
      );

      testWidgets(
        'StreamBuilder with continuous emissions should timeout',
        (tester) async {
          final streamController = StreamController<int>.broadcast();
          addTearDown(streamController.close);

          await tester.pumpWidget(
            MaterialApp(
              home: StreamBuilder<int>(
                stream: streamController.stream,
                builder: (context, snapshot) =>
                    Text('Value: ${snapshot.data ?? 0}'),
              ),
            ),
          );

          // Keep emitting values to continuously schedule frames
          final timer = Timer.periodic(
            const Duration(milliseconds: 50),
            (timer) {
              if (!streamController.isClosed) {
                streamController.add(DateTime.now().millisecondsSinceEpoch);
              } else {
                timer.cancel();
              }
            },
          );
          addTearDown(timer.cancel);

          // pumpAndSettleSafe should timeout in 2 seconds
          // instead of running for 10 minutes
          try {
            await tester.pumpAndSettleSafe();
            fail('Should have timed out');
          }
          // FlutterError is intentionally caught to verify timeout works
          // ignore: avoid_catching_errors
          on FlutterError catch (e) {
            expect(e.message, contains('timed out'));
            // Test passes - timeout protection worked!
          }
        },
      );

      test('Unclosed stream should be caught by tearDown', () async {
        final streamController = StreamController<int>.broadcast();

        // CRITICAL: Always use addTearDown for cleanup
        // This ensures cleanup happens even if test fails
        addTearDown(() async {
          if (!streamController.isClosed) {
            await streamController.close();
          }
        });

        final emissions = <int>[];
        final subscription = streamController.stream.listen(emissions.add);
        addTearDown(() async => subscription.cancel());

        // Add some values
        streamController.add(1);
        streamController.add(2);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(emissions, [1, 2]);

        // tearDown will close the stream even if we don't explicitly do it
      });

      testWidgets(
        'Future.delayed in pump(Duration) can block indefinitely',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Test'))),
          );

          // Schedule a long timer
          Future<void>.delayed(const Duration(minutes: 10), () {});

          // This CAN block waiting for that timer in FakeAsync
          // Use pump() without duration instead
          try {
            // This is the WRONG pattern
            await tester
                .pump(const Duration(seconds: 5))
                .timeout(const Duration(seconds: 1));
            fail('Should have timed out');
          } on TimeoutException {
            // Timeout protection worked!
          }
        },
      );
    });

    group('Safe patterns (recommended) -', () {
      testWidgetsWithTimeout(
        'Using pumpForStream for BLoC widgets',
        timeout: const Duration(seconds: 5),
        (tester) async {
          final streamController = StreamController<int>.broadcast();
          addTearDown(streamController.close);

          await tester.pumpWidget(
            MaterialApp(
              home: StreamBuilder<int>(
                stream: streamController.stream,
                builder: (context, snapshot) =>
                    Text('Value: ${snapshot.data ?? 0}'),
              ),
            ),
          );

          streamController.add(42);

          // SAFE: Fixed number of frames, no blocking
          await tester.pumpForStream();

          expect(find.text('Value: 42'), findsOneWidget);
        },
      );

      testWidgetsWithTimeout(
        'Using pump() without duration for active streams',
        timeout: const Duration(seconds: 5),
        (tester) async {
          final streamController = StreamController<int>.broadcast();
          addTearDown(streamController.close);

          await tester.pumpWidget(
            MaterialApp(
              home: StreamBuilder<int>(
                stream: streamController.stream,
                builder: (context, snapshot) =>
                    Text('Value: ${snapshot.data ?? 0}'),
              ),
            ),
          );

          streamController.add(99);

          // SAFE: Multiple pump() calls without duration
          for (var i = 0; i < 10; i++) {
            await tester.pump();
          }

          expect(find.text('Value: 99'), findsOneWidget);
        },
      );

      testWidgetsWithTimeout(
        'pumpUntilFound with timeout',
        timeout: const Duration(seconds: 5),
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Initial'))),
          );

          // Simulate async content loading
          Future<void>.delayed(const Duration(milliseconds: 500), () {
            // In real app, this would trigger a rebuild
          });

          // SAFE: Built-in timeout
          final found = await tester.pumpUntilFound(
            find.text('Loaded'),
          );

          // Returns false if not found (doesn't hang)
          expect(found, isFalse);
        },
      );

      test('Using waitForStreamEmissions with timeout', () async {
        final streamController = StreamController<int>.broadcast();
        addTearDown(streamController.close);

        // SAFE: Has timeout parameter
        final futureEmissions = waitForStreamEmissions(
          streamController.stream,
          count: 3,
          timeout: const Duration(seconds: 2),
        );

        streamController.add(1);
        streamController.add(2);
        streamController.add(3);

        final emissions = await futureEmissions;
        expect(emissions, [1, 2, 3]);
      });

      test('Using addTearDown for guaranteed cleanup', () async {
        final streamController = StreamController<int>.broadcast();
        StreamSubscription<int>? subscription;

        // Setup cleanup FIRST
        addTearDown(() async {
          await subscription?.cancel();
          if (!streamController.isClosed) {
            await streamController.close();
          }
        });

        // Now set up the test
        subscription = streamController.stream.listen((_) {});

        streamController.add(1);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Cleanup happens automatically via tearDown
        expect(streamController.hasListener, isTrue);
      });
    });

    group('Timeout configuration examples -', () {
      testWidgetsWithTimeout(
        'Default 30-second timeout',
        // Uses kDefaultTestTimeout (30s)
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Quick test'))),
          );
          expect(find.text('Quick test'), findsOneWidget);
        },
      );

      testWidgetsWithTimeout(
        'Custom longer timeout for complex test',
        timeout: const Duration(seconds: 60),
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Complex test'))),
          );
          // Complex operations that genuinely need more time
          await Future<void>.delayed(const Duration(milliseconds: 100));
          expect(find.text('Complex test'), findsOneWidget);
        },
      );

      testWidgetsIntegration(
        'Integration test with 45-second timeout',
        // Uses kIntegrationTestTimeout (45s)
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Integration'))),
          );
          expect(find.text('Integration'), findsOneWidget);
        },
      );
    });
  });
}
