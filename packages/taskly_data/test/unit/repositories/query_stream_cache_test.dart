@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'dart:async';

import 'package:taskly_data/testing.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('QueryStreamCache', () {
    testSafe('getOrCreate returns cached instance for same key', () async {
      final cache = QueryStreamCache<String, int>(maxEntries: 3);

      var createCalls = 0;
      Stream<int> create() {
        createCalls++;
        return Stream<int>.value(1);
      }

      final s1 = cache.getOrCreate('k', create);
      final s2 = cache.getOrCreate('k', create);

      expect(identical(s1, s2), isTrue);
      expect(createCalls, 1);
    });

    testSafe('evicts least-recently-used entries', () async {
      final cache = QueryStreamCache<int, int>(maxEntries: 2);

      cache.getOrCreate(1, () => Stream<int>.value(1));
      cache.getOrCreate(2, () => Stream<int>.value(2));

      // Touch 1 so 2 becomes least-recent.
      expect(cache.get(1), isNotNull);

      cache.getOrCreate(3, () => Stream<int>.value(3));

      expect(cache.containsKey(1), isTrue);
      expect(cache.containsKey(2), isFalse);
      expect(cache.containsKey(3), isTrue);
    });

    testSafe('shared stream emits values to listeners', () async {
      final cache = QueryStreamCache<String, int>(maxEntries: 1);

      final controller = autoTearDown(
        StreamController<int>.broadcast(),
        (c) async => c.close(),
      );

      final stream = cache.getOrCreate('k', () => controller.stream);

      final values = <int>[];
      final sub = autoCancel(stream.listen(values.add));

      controller.add(10);
      controller.add(20);

      // Allow async stream microtasks to flush.
      await Future<void>.delayed(const Duration(milliseconds: 1));

      await sub.cancel();

      expect(values, containsAllInOrder([10, 20]));
    });
  });
}
