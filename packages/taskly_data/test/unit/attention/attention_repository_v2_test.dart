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

    testSafe('watch rules by bucket(s), key lookup, and delete', () async {
      final db = createAutoClosingDb();
      final repo = AttentionRepositoryV2(db: db);

      await repo.upsertRule(
        AttentionRule(
          id: 'ra',
          ruleKey: 'rule.action',
          bucket: AttentionBucket.action,
          evaluator: 'eval',
          evaluatorParams: const {'x': 1},
          severity: AttentionSeverity.info,
          displayConfig: const {'a': 1},
          resolutionActions: const ['reviewed'],
          active: true,
          source: AttentionEntitySource.systemTemplate,
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
        ),
      );
      await repo.upsertRule(
        AttentionRule(
          id: 'rr',
          ruleKey: 'rule.review',
          bucket: AttentionBucket.review,
          evaluator: 'eval',
          evaluatorParams: const {'x': 2},
          severity: AttentionSeverity.warning,
          displayConfig: const {'b': 2},
          resolutionActions: const ['skipped'],
          active: true,
          source: AttentionEntitySource.imported,
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
        ),
      );

      final actionOnly = await repo
          .watchRulesByBucket(AttentionBucket.action)
          .first;
      expect(actionOnly.map((r) => r.id).toList(), ['ra']);

      final both = await repo.watchRulesByBuckets([
        AttentionBucket.action,
        AttentionBucket.review,
      ]).first;
      expect(both.length, 2);

      final byKey = await repo.getRuleByKey('rule.review');
      expect(byKey?.id, 'rr');

      await repo.deleteRule('rr');
      expect(await repo.getRuleById('rr'), isNull);
    });

    testSafe('resolution streams and update path are mapped', () async {
      final db = createAutoClosingDb();
      final repo = AttentionRepositoryV2(db: db);

      final r1 = AttentionResolution(
        id: 'res-1',
        ruleId: 'rule-1',
        entityId: 'project-1',
        entityType: AttentionEntityType.project,
        resolvedAt: DateTime.utc(2025, 1, 2, 10),
        resolutionAction: AttentionResolutionAction.snoozed,
        createdAt: DateTime.utc(2025, 1, 2, 10),
        actionDetails: const {'mins': 30},
      );
      await repo.recordResolution(r1);

      // Same id triggers update path.
      final r1Updated = r1.copyWith(
        resolutionAction: AttentionResolutionAction.dismissed,
        actionDetails: const {'reason': 'done'},
      );
      await repo.recordResolution(r1Updated);

      final byRule = await repo.watchResolutionsForRule('rule-1').first;
      final byEntity = await repo
          .watchResolutionsForEntity(
            'project-1',
            AttentionEntityType.project,
          )
          .first;
      final latest = await repo.getLatestResolution('rule-1', 'project-1');

      expect(
        byRule.single.resolutionAction,
        AttentionResolutionAction.dismissed,
      );
      expect(byEntity.single.actionDetails?['reason'], 'done');
      expect(latest?.resolutionAction, AttentionResolutionAction.dismissed);
    });

    testSafe(
      'runtime state watch/update/global and validation paths',
      () async {
        final db = createAutoClosingDb();
        final repo = AttentionRepositoryV2(db: db);

        final state = AttentionRuleRuntimeState(
          id: 'state-1',
          ruleId: 'rule-1',
          entityType: AttentionEntityType.task,
          entityId: 'task-1',
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
          stateHash: 'h1',
        );
        await repo.upsertRuntimeState(state);
        await repo.upsertRuntimeState(state.copyWith(stateHash: 'h2'));

        final watched = await repo.watchRuntimeStateForRule('rule-1').first;
        expect(watched.single.stateHash, 'h2');

        final globalState = AttentionRuleRuntimeState(
          id: 'state-global',
          ruleId: 'rule-global',
          entityType: null,
          entityId: null,
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
          stateHash: 'g1',
        );
        await repo.upsertRuntimeState(globalState);

        final fetchedGlobal = await repo.getRuntimeState(
          ruleId: 'rule-global',
          entityType: null,
          entityId: null,
        );
        expect(fetchedGlobal?.stateHash, 'g1');

        await expectLater(
          () => repo.upsertRuntimeState(
            globalState.copyWith(entityType: null, entityId: 'bad'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    testSafe(
      'runtime state parser accepts legacy reviewSession token',
      () async {
        final db = createAutoClosingDb();
        final repo = AttentionRepositoryV2(db: db);

        await db.customStatement(
          '''
            INSERT INTO attention_rule_runtime_state
              (id, rule_id, entity_type, entity_id, state_hash, metadata, created_at, updated_at)
            VALUES
              (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            'legacy-review-session',
            'legacy-rule',
            'reviewSession',
            'session-1',
            'legacy',
            '{}',
            DateTime.utc(2025, 1, 1).toIso8601String(),
            DateTime.utc(2025, 1, 1).toIso8601String(),
          ],
        );

        final states = await repo.watchRuntimeStateForRule('legacy-rule').first;
        expect(states.single.entityType, AttentionEntityType.reviewSession);
      },
    );
  });
}
