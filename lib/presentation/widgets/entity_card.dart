import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/entity_tap_handler.dart';

/// Generic card widget for displaying any entity type.
///
/// Uses [EntityTapHandler] mixin to provide consistent navigation
/// behavior with optional override via [onTap].
class EntityCard extends StatelessWidget with EntityTapHandler {
  /// Creates an EntityCard widget.
  ///
  /// Uses default navigation to entity detail screen unless [onTap]
  /// is provided (DR-007: Default onTap navigation).
  const EntityCard({
    required this.entityId,
    required this.entityType,
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// The unique identifier of the entity
  final String entityId;

  /// The type of entity (task, project, label, value)
  final String entityType;

  /// The title to display
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional leading widget
  final Widget? leading;

  /// Optional trailing widget
  final Widget? trailing;

  /// Optional custom tap handler (overrides default navigation)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: buildTapCallback(
          context,
          entityId: entityId,
          entityType: entityType,
          customOnTap: onTap,
        ),
      ),
    );
  }
}
