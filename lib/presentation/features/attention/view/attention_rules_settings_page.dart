import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/interfaces/attention_repository_contract.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';

/// Settings page for managing attention rules.
///
/// Allows users to view and toggle system attention rules.
/// User-created rules are out of scope for v1.
class AttentionRulesSettingsPage extends StatefulWidget {
  const AttentionRulesSettingsPage({
    required this.attentionRepository,
    super.key,
  });

  final AttentionRepositoryContract attentionRepository;

  @override
  State<AttentionRulesSettingsPage> createState() =>
      _AttentionRulesSettingsPageState();
}

class _AttentionRulesSettingsPageState
    extends State<AttentionRulesSettingsPage> {
  AttentionRepositoryContract get _repo => widget.attentionRepository;

  List<AttentionRule> _rules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRules());
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rules = await _repo.watchAllRules().first;
      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRule(AttentionRule rule) async {
    try {
      await _repo.updateRuleActive(rule.id, !rule.active);
      await _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating rule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attention Rules'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading rules: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRules,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_rules.isEmpty) {
      return const Center(
        child: Text('No attention rules configured'),
      );
    }

    // Group rules by type
    final problemRules = _rules
        .where((r) => r.ruleType == AttentionRuleType.problem)
        .toList();
    final reviewRules = _rules
        .where((r) => r.ruleType == AttentionRuleType.review)
        .toList();
    final allocationRules = _rules
        .where((r) => r.ruleType == AttentionRuleType.allocationWarning)
        .toList();

    return ResponsiveBody(
      child: ListView(
        children: [
          if (problemRules.isNotEmpty) ...[
            _buildSectionHeader(context, 'Problem Detection'),
            _buildRuleDescription(
              context,
              'Detect tasks and projects that need attention due to being '
              'overdue, stale, or idle.',
            ),
            ...problemRules.map(_buildRuleTile),
          ],
          if (reviewRules.isNotEmpty) ...[
            _buildSectionHeader(context, 'Periodic Reviews'),
            _buildRuleDescription(
              context,
              'Scheduled reminders to review your tasks, projects, and values.',
            ),
            ...reviewRules.map(_buildRuleTile),
          ],
          if (allocationRules.isNotEmpty) ...[
            _buildSectionHeader(context, 'Allocation Alerts'),
            _buildRuleDescription(
              context,
              "Warnings when tasks should be in your day allocation but aren't.",
            ),
            ...allocationRules.map(_buildRuleTile),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildRuleDescription(BuildContext context, String description) {
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

  Widget _buildRuleTile(AttentionRule rule) {
    final displayConfig = rule.displayConfig;
    final title = displayConfig['title'] as String? ?? rule.ruleKey;
    final description = displayConfig['description'] as String?;

    return SwitchListTile(
      value: rule.active,
      onChanged: (_) => _toggleRule(rule),
      title: Text(title),
      subtitle: description != null
          ? Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      secondary: _buildSeverityIcon(rule.severity),
    );
  }

  Widget _buildSeverityIcon(AttentionSeverity severity) {
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
