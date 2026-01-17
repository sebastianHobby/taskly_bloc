import 'package:flutter/material.dart';
import 'package:taskly_domain/domain/attention/model/attention_item.dart';
import 'package:taskly_domain/domain/attention/model/attention_resolution.dart';
import 'package:taskly_domain/domain/attention/model/attention_rule.dart';

class SupportSectionCard extends StatelessWidget {
  const SupportSectionCard({
    required this.title,
    required this.child,
    super.key,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title?.trim();
    final hasTitle = effectiveTitle != null && effectiveTitle.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasTitle) ...[
              Text(
                effectiveTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class AttentionItemTile extends StatelessWidget {
  const AttentionItemTile({
    required this.item,
    super.key,
    this.leading,
  });

  final AttentionItem item;
  final Widget? leading;

  String? _entityDisplayName() {
    final metadata = item.metadata;
    if (metadata == null) return null;

    final explicit = metadata['entity_display_name'];
    if (explicit is String && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }

    final key = switch (item.entityType) {
      AttentionEntityType.task => 'task_name',
      AttentionEntityType.project => 'project_name',
      AttentionEntityType.value => 'value_name',
      AttentionEntityType.journal => null,
      AttentionEntityType.tracker => null,
      AttentionEntityType.reviewSession => null,
    };

    if (key == null) return null;
    final v = metadata[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  (IconData, String)? _entityBadge() {
    return switch (item.entityType) {
      AttentionEntityType.task => (Icons.check_box_outlined, 'Task'),
      AttentionEntityType.project => (Icons.folder_outlined, 'Project'),
      AttentionEntityType.value => (Icons.flag_outlined, 'Value'),
      AttentionEntityType.journal => null,
      AttentionEntityType.tracker => null,
      AttentionEntityType.reviewSession => null,
    };
  }

  List<String> _detailLines() {
    final raw = item.metadata?['detail_lines'];
    if (raw is! List) return const <String>[];
    return raw.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entityName = _entityDisplayName();
    final entityBadge = _entityBadge();
    final detailLines = _detailLines();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          leading ?? SeverityIcon(severity: item.severity),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entityName != null && entityBadge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(
                          entityBadge.$1,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${entityBadge.$2} • $entityName',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                for (final line in detailLines)
                  Text(
                    line,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewItemTile extends StatelessWidget {
  const ReviewItemTile({required this.item, super.key});

  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        Icons.rate_review_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        item.title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: item.description.isNotEmpty ? Text(item.description) : null,
    );
  }
}

class SeverityIcon extends StatelessWidget {
  const SeverityIcon({required this.severity, super.key});

  final AttentionSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (severity) {
      AttentionSeverity.critical => (
        Icons.error,
        Theme.of(context).colorScheme.error,
      ),
      AttentionSeverity.warning => (
        Icons.warning_amber,
        Colors.orange,
      ),
      AttentionSeverity.info => (
        Icons.info_outline,
        Theme.of(context).colorScheme.primary,
      ),
    };

    return Icon(icon, size: 20, color: color);
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({
    required this.count,
    required this.color,
    required this.label,
    super.key,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
