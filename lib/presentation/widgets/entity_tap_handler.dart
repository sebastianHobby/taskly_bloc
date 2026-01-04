import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';

/// Mixin providing consistent entity tap handling for widgets.
/// Use this when building entity list items or cards.
mixin EntityTapHandler {
  /// Build tap callback with optional override
  VoidCallback? buildTapCallback(
    BuildContext context, {
    required String entityId,
    required String entityType,
    VoidCallback? customOnTap,
  }) {
    return customOnTap ??
        Routing.onTapEntity(
          context,
          EntityType.fromString(entityType),
          entityId,
        );
  }
}
