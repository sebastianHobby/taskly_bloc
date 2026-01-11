import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_action.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_definition.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_type.dart';
import 'package:taskly_bloc/presentation/widgets/problem/problem_action_button.dart';

/// A card widget displaying a detected problem with available actions.
///
/// Shows the problem title, description, severity indicator, and action
/// buttons. Used in soft gates panels and workflow screens.
class ProblemCard extends StatelessWidget {
  /// Creates a problem card.
  const ProblemCard({
    required this.problemType,
    required this.entityName,
    required this.onAction,
    this.description,
    this.compact = false,
    super.key,
  });

  /// The type of problem being displayed.
  final ProblemType problemType;

  /// The name of the affected entity (task, project, etc.).
  final String entityName;

  /// Custom description override (uses definition description if null).
  final String? description;

  /// Callback when an action is selected.
  final void Function(ProblemAction action) onAction;

  /// Whether to display in compact mode (fewer details).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final definition = ProblemDefinition.forType(problemType);

    return Card(
      elevation: 0,
      color: _getSeverityBackgroundColor(definition.severity, colorScheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getSeverityBorderColor(definition.severity, colorScheme),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, definition),
            if (!compact) ...[
              const SizedBox(height: 8),
              _buildDescription(context, definition),
            ],
            const SizedBox(height: 12),
            _buildActions(context, definition),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProblemDefinition definition) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          _getIconData(definition.iconName),
          size: compact ? 18 : 22,
          color: _getSeverityIconColor(definition.severity, colorScheme),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                definition.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (entityName.isNotEmpty)
                Text(
                  entityName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        _buildSeverityBadge(context, definition.severity),
      ],
    );
  }

  Widget _buildDescription(
    BuildContext context,
    ProblemDefinition definition,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      description ?? definition.description,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActions(BuildContext context, ProblemDefinition definition) {
    if (definition.availableActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: definition.availableActions.take(compact ? 3 : 5).map((action) {
        return ProblemActionButton(
          action: action,
          onPressed: () => onAction(action),
          compact: compact,
        );
      }).toList(),
    );
  }

  Widget _buildSeverityBadge(BuildContext context, ProblemSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, color) = switch (severity) {
      ProblemSeverity.high => ('High', colorScheme.error),
      ProblemSeverity.medium => ('Medium', colorScheme.tertiary),
      ProblemSeverity.low => ('Low', colorScheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getSeverityBackgroundColor(
    ProblemSeverity severity,
    ColorScheme colorScheme,
  ) {
    return switch (severity) {
      ProblemSeverity.high => colorScheme.errorContainer.withValues(alpha: 0.3),
      ProblemSeverity.medium => colorScheme.tertiaryContainer.withValues(
        alpha: 0.3,
      ),
      ProblemSeverity.low => colorScheme.surfaceContainerHighest,
    };
  }

  Color _getSeverityBorderColor(
    ProblemSeverity severity,
    ColorScheme colorScheme,
  ) {
    return switch (severity) {
      ProblemSeverity.high => colorScheme.error.withValues(alpha: 0.3),
      ProblemSeverity.medium => colorScheme.tertiary.withValues(alpha: 0.3),
      ProblemSeverity.low => colorScheme.outlineVariant,
    };
  }

  Color _getSeverityIconColor(
    ProblemSeverity severity,
    ColorScheme colorScheme,
  ) {
    return switch (severity) {
      ProblemSeverity.high => colorScheme.error,
      ProblemSeverity.medium => colorScheme.tertiary,
      ProblemSeverity.low => colorScheme.outline,
    };
  }

  IconData _getIconData(String? iconName) {
    return switch (iconName) {
      'warning_amber' => Icons.warning_amber,
      'schedule' => Icons.schedule,
      'playlist_remove' => Icons.playlist_remove,
      'balance' => Icons.balance,
      'history' => Icons.history,
      _ => Icons.info_outline,
    };
  }
}
