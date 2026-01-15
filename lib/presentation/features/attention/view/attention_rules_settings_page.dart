import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_rules_cubit.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';

/// Settings page for managing attention rules.
///
/// Allows users to view and toggle system attention rules.
/// User-created rules are out of scope for v1.
class AttentionRulesSettingsPage extends StatelessWidget {
  const AttentionRulesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttentionRulesCubit>(
      create: (_) => getIt<AttentionRulesCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attention Rules'),
        ),
        body: BlocListener<AttentionRulesCubit, AttentionRulesState>(
          listenWhen: (prev, next) => next is AttentionRulesError,
          listener: (context, state) {
            if (state case AttentionRulesError(:final message)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
          child: const _AttentionRulesBody(),
        ),
      ),
    );
  }
}

class _AttentionRulesBody extends StatelessWidget {
  const _AttentionRulesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttentionRulesCubit, AttentionRulesState>(
      builder: (context, state) {
        return switch (state) {
          AttentionRulesLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AttentionRulesError(:final message) => Center(
            child: Text(message),
          ),
          AttentionRulesLoaded(:final rules) => _RulesList(rules: rules),
        };
      },
    );
  }
}

class _RulesList extends StatelessWidget {
  const _RulesList({required this.rules});

  final List<AttentionRule> rules;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const Center(
        child: Text('No attention rules configured'),
      );
    }

    // Group rules by bucket/evaluator.
    final reviewRules = rules
        .where((r) => r.bucket == AttentionBucket.review)
        .toList(growable: false);

    final actionRules = rules
        .where((r) => r.bucket == AttentionBucket.action)
        .toList(growable: false);

    final allocationRules = actionRules
        .where((r) => r.evaluator == 'allocation_snapshot_task_v1')
        .toList(growable: false);

    final problemRules = actionRules
        .where((r) => r.evaluator != 'allocation_snapshot_task_v1')
        .toList(growable: false);

    return ResponsiveBody(
      child: ListView(
        children: [
          if (problemRules.isNotEmpty) ...[
            _SectionHeader(title: 'Problem Detection'),
            _SectionDescription(
              description:
                  'Detect tasks and projects that need attention due to being '
                  'overdue, stale, or idle.',
            ),
            ...problemRules.map((rule) => _RuleTile(rule: rule)),
          ],
          if (reviewRules.isNotEmpty) ...[
            _SectionHeader(title: 'Periodic Reviews'),
            _SectionDescription(
              description:
                  'Scheduled reminders to review your tasks, projects, and values.',
            ),
            ...reviewRules.map((rule) => _RuleTile(rule: rule)),
          ],
          if (allocationRules.isNotEmpty) ...[
            _SectionHeader(title: 'Allocation Alerts'),
            _SectionDescription(
              description:
                  "Warnings when tasks should be in your day allocation but aren't.",
            ),
            ...allocationRules.map((rule) => _RuleTile(rule: rule)),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionDescription extends StatelessWidget {
  const _SectionDescription({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        description,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule});

  final AttentionRule rule;

  @override
  Widget build(BuildContext context) {
    final displayConfig = rule.displayConfig;
    final title = displayConfig['title'] as String? ?? rule.ruleKey;
    final description = displayConfig['description'] as String?;

    return SwitchListTile(
      value: rule.active,
      onChanged: (_) {
        context.read<AttentionRulesCubit>().toggleRule(rule);
      },
      title: Text(title),
      subtitle: description != null
          ? Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      secondary: _SeverityIcon(severity: rule.severity),
    );
  }
}

class _SeverityIcon extends StatelessWidget {
  const _SeverityIcon({required this.severity});

  final AttentionSeverity severity;

  @override
  Widget build(BuildContext context) {
    // Use theme colors to respect the app's design system.
    final colorScheme = Theme.of(context).colorScheme;

    return switch (severity) {
      AttentionSeverity.critical => Icon(
        Icons.error,
        color: colorScheme.error,
      ),
      AttentionSeverity.warning => Icon(
        Icons.warning,
        color: colorScheme.tertiary,
      ),
      AttentionSeverity.info => Icon(
        Icons.info,
        color: colorScheme.primary,
      ),
    };
  }
}
