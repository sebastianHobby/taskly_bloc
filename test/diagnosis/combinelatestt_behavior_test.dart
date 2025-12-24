import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

/// Test to understand combineLatest2 behavior
void main() {
  test(
    'combineLatest2 emits when either stream emits (after both emit once)',
    () async {
      final stream1Controller = StreamController<int>.broadcast();
      final stream2Controller = StreamController<String>.broadcast();

      final emissions = <String>[];

      final combined = Rx.combineLatest2<int, String, String>(
        stream1Controller.stream,
        stream2Controller.stream,
        (a, b) => '$a-$b',
      );

      final subscription = combined.listen(emissions.add);

      // Emit from stream1 first
      print('Emitting from stream1: 1');
      stream1Controller.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      print('Emissions after stream1: ${emissions.length}'); // Should be 0

      // Emit from stream2 - NOW combineLatest2 should emit
      print('Emitting from stream2: A');
      stream2Controller.add('A');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      print('Emissions: $emissions'); // Should be ['1-A']

      // Now emit from stream2 again - should emit new combined value
      print('Emitting from stream2: B');
      stream2Controller.add('B');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      print('Emissions: $emissions'); // Should be ['1-A', '1-B']

      // Emit from stream1 - should also emit
      print('Emitting from stream1: 2');
      stream1Controller.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      print('Emissions: $emissions'); // Should be ['1-A', '1-B', '2-B']

      await subscription.cancel();
      await stream1Controller.close();
      await stream2Controller.close();

      expect(emissions, ['1-A', '1-B', '2-B']);
    },
  );

  test('combineLatest2 with async* generators', () async {
    Stream<int> stream1() async* {
      yield 1;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      yield 2;
    }

    Stream<String> stream2() async* {
      yield 'A';
      await Future<void>.delayed(const Duration(milliseconds: 100));
      yield 'B';
    }

    final emissions = <String>[];

    final combined = Rx.combineLatest2<int, String, String>(
      stream1(),
      stream2(),
      (a, b) => '$a-$b',
    );

    final subscription = combined.listen((value) {
      print('Combined emission: $value');
      emissions.add(value);
    });

    await Future<void>.delayed(const Duration(milliseconds: 200));

    print('Final emissions: $emissions');

    await subscription.cancel();

    // Should have: 1-A (initial), 2-A (stream1 emits 2), 2-B (stream2 emits B)
    expect(emissions.length, greaterThanOrEqualTo(2));
  });
}
