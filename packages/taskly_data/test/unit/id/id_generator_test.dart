@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_data/id.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('IdGenerator', () {
    testSafe('v4 ids do not require userId', () async {
      var userIdCalls = 0;
      final gen = IdGenerator(() {
        userIdCalls++;
        throw StateError('no user');
      });

      final id1 = gen.taskId();
      final id2 = gen.taskId();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(id2));
      expect(userIdCalls, 0);
    });

    testSafe('v5 ids require userId lazily', () async {
      var userIdCalls = 0;
      final gen = IdGenerator(() {
        userIdCalls++;
        return 'user-123';
      });

      final id1 = gen.valueId(name: 'Health');
      final id2 = gen.valueId(name: 'Health');
      final id3 = gen.valueId(name: 'Work');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(userIdCalls, greaterThanOrEqualTo(1));
    });

    testSafe('deterministic completion ids vary by date key', () async {
      final gen = IdGenerator.withUserId('u');

      final a = gen.taskCompletionId(
        taskId: 't1',
        occurrenceDate: DateTime(2025, 1, 10, 12, 30),
      );
      final b = gen.taskCompletionId(
        taskId: 't1',
        occurrenceDate: DateTime(2025, 1, 10, 1),
      );
      final c = gen.taskCompletionId(taskId: 't1', occurrenceDate: null);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    testSafe('table strategy registry matches expected sets', () async {
      expect(IdGenerator.isDeterministic('values'), isTrue);
      expect(IdGenerator.isDeterministic('tasks'), isFalse);

      expect(IdGenerator.isRandom('tasks'), isTrue);
      expect(IdGenerator.isRandom('values'), isFalse);
    });
  });
}
