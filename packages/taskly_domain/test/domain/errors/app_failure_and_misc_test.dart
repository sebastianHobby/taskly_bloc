@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_scope.dart';

void main() {
  testSafe(
    'app failures expose kind, uiMessage, toString and reporting flag',
    () async {
      final failures = <AppFailure>[
        const AuthFailure(),
        const UnauthorizedFailure(),
        const ForbiddenFailure(),
        const InputValidationFailure(),
        const NotFoundFailure(),
        const NetworkFailure(),
        const TimeoutFailure(),
        const RateLimitedFailure(),
        const StorageFailure(),
      UnknownFailure(cause: StateError('x')),
      ];

      for (final f in failures) {
        expect(f.uiMessage(), isNotEmpty);
        expect(f.toString(), contains('AppFailure('));
      }
      expect(const UnknownFailure().reportAsUnexpected, isTrue);
      expect(const AuthFailure(message: 'm').uiMessage(), 'm');
    },
  );

  testSafe(
    'value draft factories and copyWith retain expected fields',
    () async {
      final value = Value(
        id: 'v1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Health',
        color: '#123456',
        priority: ValuePriority.high,
        iconName: 'star',
      );
      final empty = ValueDraft.empty();
      final fromValue = ValueDraft.fromValue(value);
      final copied = fromValue.copyWith(name: 'Updated');

      expect(empty.color, '#000000');
      expect(fromValue.name, 'Health');
      expect(fromValue.priority, ValuePriority.high);
      expect(copied.name, 'Updated');
      expect(copied.iconName, 'star');
    },
  );

  testSafe(
    'system attention rule registry returns expected templates',
    () async {
      final all = SystemAttentionRules.all;
      expect(all, hasLength(4));
      expect(SystemAttentionRules.getByKey('problem_task_stale'), isNotNull);
      expect(SystemAttentionRules.getByKey('missing'), isNull);
      expect(
        SystemAttentionRules.problemProjectDeadlineRisk.evaluatorParams,
        containsPair('predicate', 'dueSoonManyUnscheduledTasks'),
      );
      expect(SystemAttentionRules.problemRoutineSupport.sortOrder, 45);
    },
  );

  testSafe('scheduled scope classes preserve payloads', () async {
    const global = GlobalScheduledScope();
    const project = ProjectScheduledScope(projectId: 'p1');
    const value = ValueScheduledScope(valueId: 'v1');

    expect(global, isA<ScheduledScope>());
    expect(project.projectId, 'p1');
    expect(value.valueId, 'v1');
  });
}
