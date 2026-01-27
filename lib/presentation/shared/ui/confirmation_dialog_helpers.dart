import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Builds the delete confirmation content with a highlighted item name.
Widget buildDeleteConfirmationContent(
  BuildContext context, {
  required String itemName,
  String? description,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final l10n = context.l10n;

  const token = '__ITEM_NAME__';
  final template = l10n.deleteConfirmationQuestion(token);
  final parts = template.split(token);

  final before = parts.length == 2 ? parts.first : template;
  final after = parts.length == 2 ? parts.last : '';

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(text: before),
            TextSpan(
              text: itemName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            TextSpan(text: after),
          ],
        ),
      ),
      if (description != null) ...[
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}
