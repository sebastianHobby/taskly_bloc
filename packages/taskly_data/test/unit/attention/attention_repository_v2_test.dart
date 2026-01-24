@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:matcher/matcher.dart' as matcher;
import 'package:taskly_data/src/attention/repositories/attention_repository_v2.dart';
import 'package:taskly_domain/attention.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AttentionRepositoryV2', () {
    testSafe('upsertRule inserts and updates rules', () async {
      final db = createAutoClosingDb();
      final repo = AttentionRepositoryV2(db: db);

      final rule = AttentionRule(
        id: 'r1',
        ruleKey: 'rule.key',
        bucket: AttentionBucket.action,
        evaluator: 'eval',
        evaluatorParams: const {'a': 1},
        severity: AttentionSeverity.warning,
        displayConfig: const {'b': 2},
        resolutionActions: const ['reviewed'],
        active: true,
        source: AttentionEntitySource.userCreated,
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      );

      await repo.upsertRule(rule);

      final fetched = await repo.getRuleById('r1');
      expect(fetched, matcher.isNotNull);
      expect(fetched!.ruleKey, equals('rule.key'));

      await repo.updateRuleActive('r1', false);
      final active = await repo.watchActiveRules().first;
      expect(active, isEmpty);
    });

    testSafe('updateRuleSeverity and evaluator params', () async {
      final db = createAutoClosingDb();
      final repo = AttentionRepositoryV2(db: db);

      final rule = AttentionRule(
        id: 'r1',
        ruleKey: 'rule.key',
        bucket: AttentionBucket.review,
        evaluator: 'eval',
        evaluatorParams: const {'a': 1},
        severity: AttentionSeverity.info,
        displayConfig: const {'b': 2},
        resolutionActions: const ['reviewed'],
        active: true,
        source: AttentionEntitySource.userCreated,
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      );

      await repo.upsertRule(rule);

      await repo.updateRuleSeverity('r1', AttentionSeverity.critical);
      await repo.updateRuleEvaluatorParams('r1', const {'a': 2});

      final fetched = await repo.getRuleById('r1');
      expect(fetched!.severity, equals(AttentionSeverity.critical));
      expect(fetched.evaluatorParams['a'], equals(2));
    });

    testSafe('recordResolution and getLatestResolution', () async {
      final db = createAutoClosingDb();
      final repo = AttentionRepositoryV2(db: db);

      final resolution = AttentionResolution(
        id: 'res1',
        ruleId: 'r1',
        entityId: 'task-1',
        entityType: AttentionEntityType.task,
        resolvedAt: DateTime.utc(2025, 1, 2),
        resolutionAction: AttentionResolutionAction.reviewed,
        createdAt: DateTime.utc(2025, 1, 2),
        actionDetails: const {'x': 1},
      );

      await repo.recordResolution(resolution);

      final latest = await repo.getLatestResolution('r1', 'task-1');
      expect(latest, matcher.isNotNull);
      expect(latest!.resolutionAction, AttentionResolutionAction.reviewed);
    });

    testSafe('upsertRuntimeState and getRuntimeState', () async {
      final db = createAutoClosingDb();
      final repo = AttentionRepositoryV2(db: db);

      final state = AttentionRuleRuntimeState(
        id: 's1',
        ruleId: 'r1',
        entityType: AttentionEntityType.project,
        entityId: 'project-1',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        stateHash: 'hash',
      );

      await repo.upsertRuntimeState(state);

      final fetched = await repo.getRuntimeState(
        ruleId: 'r1',
        entityType: AttentionEntityType.project,
        entityId: 'project-1',
      );

      expect(fetched, matcher.isNotNull);
      expect(fetched!.stateHash, equals('hash'));
    });

    testSafe('getRuntimeState validates entity pairs', () async {
      final db = createAutoClosingDb();
      final repo = AttentionRepositoryV2(db: db);

      expect(
        () => repo.getRuntimeState(
          ruleId: 'r1',
          entityType: AttentionEntityType.task,
          entityId: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
