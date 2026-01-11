import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/trigger_config.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_creator_page.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_run_page.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';

/// Page displaying a list of workflow definitions.
///
/// Users can view, edit, delete, and create new workflow definitions
/// from this page.
class WorkflowListPage extends StatefulWidget {
  const WorkflowListPage({
    required this.userId,
    super.key,
  });

  /// The current user's ID for creating workflows.
  final String userId;

  @override
  State<WorkflowListPage> createState() => _WorkflowListPageState();
}

class _WorkflowListPageState extends State<WorkflowListPage> {
  late final WorkflowRepositoryContract _workflowRepository;

  @override
  void initState() {
    super.initState();
    _workflowRepository = getIt<WorkflowRepositoryContract>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Workflows'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'About Workflows',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<WorkflowDefinition>>(
        stream: _workflowRepository.watchWorkflowDefinitions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final workflows = snapshot.data!;

          if (workflows.isEmpty) {
            return _EmptyView(
              onCreateTapped: () => _navigateToCreator(context),
            );
          }

          return _WorkflowListView(
            workflows: workflows,
            onWorkflowTapped: (workflow) => _navigateToCreator(
              context,
              existingWorkflow: workflow,
            ),
            onRunTapped: (workflow) => _runWorkflow(context, workflow),
            onDeleteTapped: (workflow) => _confirmDelete(context, workflow),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreator(context),
        icon: const Icon(Icons.add),
        label: const Text('New Workflow'),
      ),
    );
  }

  Future<void> _navigateToCreator(
    BuildContext context, {
    WorkflowDefinition? existingWorkflow,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => WorkflowCreatorPage(
          workflowRepository: _workflowRepository,
          userId: widget.userId,
          existingWorkflow: existingWorkflow,
        ),
      ),
    );

    // Show success message if workflow was saved
    if ((result ?? false) && mounted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingWorkflow != null
                ? 'Workflow updated successfully'
                : 'Workflow created successfully',
          ),
        ),
      );
    }
  }

  void _runWorkflow(BuildContext context, WorkflowDefinition workflow) {
    // Navigate to workflow run page
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => WorkflowRunPage(definition: workflow),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WorkflowDefinition workflow,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workflow'),
        content: Text(
          'Are you sure you want to delete "${workflow.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _workflowRepository.deleteWorkflowDefinition(workflow.id);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${workflow.name}"')),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Review Workflows'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review workflows help you regularly review and maintain your tasks, '
                'projects, and labels.',
              ),
              SizedBox(height: 16),
              Text(
                'Each workflow consists of one or more steps. Each step reviews '
                'a specific type of item based on filters you define.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Workflows can be triggered:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('â€¢ Manually - start when you want'),
              Text('â€¢ On Schedule - daily, weekly, etc.'),
              Text('â€¢ Based on Conditions - items not reviewed recently'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Empty View
// =============================================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreateTapped});

  final VoidCallback onCreateTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.loop,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Workflows Yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first workflow to start organizing\n'
              'your regular reviews.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateTapped,
              icon: const Icon(Icons.add),
              label: const Text('Create Workflow'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Error View
// =============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Workflow List View
// =============================================================================

class _WorkflowListView extends StatelessWidget {
  const _WorkflowListView({
    required this.workflows,
    required this.onWorkflowTapped,
    required this.onRunTapped,
    required this.onDeleteTapped,
  });

  final List<WorkflowDefinition> workflows;
  final void Function(WorkflowDefinition) onWorkflowTapped;
  final void Function(WorkflowDefinition) onRunTapped;
  final void Function(WorkflowDefinition) onDeleteTapped;

  @override
  Widget build(BuildContext context) {
    // Separate system and custom workflows
    final systemWorkflows = workflows.where((w) => w.isSystem).toList();
    final customWorkflows = workflows.where((w) => !w.isSystem).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 88), // Space for FAB
      children: [
        if (customWorkflows.isNotEmpty) ...[
          _SectionHeader(
            title: 'My Workflows',
            count: customWorkflows.length,
          ),
          ...customWorkflows.map(
            (w) => _WorkflowTile(
              workflow: w,
              onTap: () => onWorkflowTapped(w),
              onRun: () => onRunTapped(w),
              onDelete: () => onDeleteTapped(w),
              isEditable: true,
            ),
          ),
        ],
        if (systemWorkflows.isNotEmpty) ...[
          _SectionHeader(
            title: 'System Workflows',
            count: systemWorkflows.length,
          ),
          ...systemWorkflows.map(
            (w) => _WorkflowTile(
              workflow: w,
              onTap: () => onWorkflowTapped(w),
              onRun: () => onRunTapped(w),
              onDelete: null, // Can't delete system workflows
              isEditable: false,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Section Header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Workflow Tile
// =============================================================================

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({
    required this.workflow,
    required this.onTap,
    required this.onRun,
    required this.onDelete,
    required this.isEditable,
  });

  final WorkflowDefinition workflow;
  final VoidCallback onTap;
  final VoidCallback onRun;
  final VoidCallback? onDelete;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = FormBuilderIconPicker.getIconData(workflow.iconName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: isEditable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ?? Icons.loop,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workflow.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!workflow.isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Inactive',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (workflow.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        workflow.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _WorkflowMetadata(workflow: workflow),
                  ],
                ),
              ),

              // Actions
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Run button
                  IconButton.filledTonal(
                    onPressed: workflow.isActive ? onRun : null,
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Run workflow',
                    visualDensity: VisualDensity.compact,
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(height: 4),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      color: theme.colorScheme.error,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Workflow Metadata
// =============================================================================

class _WorkflowMetadata extends StatelessWidget {
  const _WorkflowMetadata({required this.workflow});

  final WorkflowDefinition workflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        // Step count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_list_numbered,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${workflow.steps.length} ${workflow.steps.length == 1 ? 'step' : 'steps'}',
              style: textStyle,
            ),
          ],
        ),

        // Trigger info
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTriggerIcon(workflow.triggerConfig),
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _getTriggerLabel(workflow.triggerConfig),
              style: textStyle,
            ),
          ],
        ),

        // Last completed (if available)
        if (workflow.lastCompletedAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatLastCompleted(workflow.lastCompletedAt!),
                style: textStyle,
              ),
            ],
          ),
      ],
    );
  }

  IconData _getTriggerIcon(TriggerConfig? config) {
    if (config == null) return Icons.touch_app;

    return config.when(
      schedule: (_, __) => Icons.schedule,
      notReviewedSince: (_) => Icons.history,
      manual: () => Icons.touch_app,
    );
  }

  String _getTriggerLabel(TriggerConfig? config) {
    if (config == null) return 'Manual';

    return config.when(
      schedule: (String rrule, _) => _describeRrule(rrule),
      notReviewedSince: (int days) => 'After $days days',
      manual: () => 'Manual',
    );
  }

  String _describeRrule(String rrule) {
    // Simple RRULE parsing for display
    if (rrule.contains('FREQ=DAILY')) {
      return 'Daily';
    } else if (rrule.contains('FREQ=WEEKLY')) {
      if (rrule.contains('BYDAY=MO,TU,WE,TH,FR')) {
        return 'Weekdays';
      }
      return 'Weekly';
    } else if (rrule.contains('FREQ=MONTHLY')) {
      return 'Monthly';
    } else if (rrule.contains('FREQ=YEARLY')) {
      return 'Yearly';
    }
    return 'Scheduled';
  }

  String _formatLastCompleted(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
