import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';

/// A preview widget showing allocation results for Focus screen builder.
///
/// Displays a summary of what tasks would be allocated with current settings:
/// - Total task count
/// - Category breakdown
/// - Warning if limit exceeded (Firefighter persona)
class AllocationPreviewWidget extends StatefulWidget {
  const AllocationPreviewWidget({
    required this.allocationOrchestrator,
    required this.persona,
    required this.maxTasks,
    this.sourceFilter,
    super.key,
  });

  /// The allocation orchestrator to use for preview.
  final AllocationOrchestrator allocationOrchestrator;

  /// Current persona selection.
  final AllocationPersona persona;

  /// Maximum tasks to allocate.
  final int maxTasks;

  /// Optional source filter for tasks.
  final TaskQuery? sourceFilter;

  @override
  State<AllocationPreviewWidget> createState() =>
      _AllocationPreviewWidgetState();
}

class _AllocationPreviewWidgetState extends State<AllocationPreviewWidget> {
  StreamSubscription<AllocationResult>? _subscription;
  AllocationResult? _result;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(AllocationPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.persona != widget.persona ||
        oldWidget.maxTasks != widget.maxTasks ||
        oldWidget.sourceFilter != widget.sourceFilter) {
      _loadPreview();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadPreview() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _subscription?.cancel();
    _subscription = widget.allocationOrchestrator.watchAllocation().listen(
      (result) {
        if (mounted) {
          setState(() {
            _result = result;
            _isLoading = false;
          });
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              _buildError(theme, colorScheme)
            else if (_isLoading)
              _buildLoading(theme)
            else if (_result != null)
              _buildPreviewContent(theme, colorScheme)
            else
              _buildEmpty(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Text(
      'Calculating allocation...',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Could not preview: $_error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Text(
      'No allocation data available',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPreviewContent(ThemeData theme, ColorScheme colorScheme) {
    final result = _result!;
    final l10n = context.l10n;
    final taskCount = result.allocatedTasks.length;
    // Firefighter persona may exceed limit due to urgent tasks
    final mayExceedLimit = widget.persona == AllocationPersona.firefighter;
    final exceedsLimit = mayExceedLimit && taskCount > widget.maxTasks;

    // Get persona display name
    final personaName = switch (widget.persona) {
      AllocationPersona.idealist => l10n.personaIdealist,
      AllocationPersona.reflector => l10n.personaReflector,
      AllocationPersona.realist => l10n.personaRealist,
      AllocationPersona.firefighter => l10n.personaFirefighter,
      AllocationPersona.custom => l10n.personaCustom,
    };

    // Build category breakdown
    final categoryBreakdown = _buildCategoryBreakdown(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task count summary
        Row(
          children: [
            Text(
              '$taskCount task${taskCount == 1 ? '' : 's'}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: exceedsLimit ? colorScheme.error : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '• $personaName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (exceedsLimit) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Exceeds limit of ${widget.maxTasks} due to urgent tasks',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (categoryBreakdown.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categoryBreakdown.entries.map((entry) {
              return Chip(
                label: Text('${entry.value} ${entry.key}'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],
        if (result.requiresValueSetup) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set up your values to see personalized allocation',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Map<String, int> _buildCategoryBreakdown(AllocationResult result) {
    final breakdown = <String, int>{};

    for (final allocatedTask in result.allocatedTasks) {
      // Get qualifying value name from task labels
      final valueLabels = allocatedTask.task.labels
          .where((l) => l.type == LabelType.value)
          .toList();

      final categoryName = valueLabels.isNotEmpty
          ? valueLabels.first.name
          : 'Uncategorized';

      breakdown[categoryName] = (breakdown[categoryName] ?? 0) + 1;
    }

    return breakdown;
  }
}
