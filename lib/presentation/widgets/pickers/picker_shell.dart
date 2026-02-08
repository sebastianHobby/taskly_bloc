import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class PickerShell extends StatelessWidget {
  const PickerShell({
    required this.title,
    required this.child,
    this.headerContent,
    this.searchField,
    this.footer,
    this.onClose,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? headerContent;
  final Widget? searchField;
  final Widget? footer;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceSm,
          ),
          child: Row(
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        if (headerContent != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              0,
              tokens.spaceLg,
              tokens.spaceSm,
            ),
            child: headerContent,
          ),
        if (searchField != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              0,
              tokens.spaceLg,
              tokens.spaceMd,
            ),
            child: searchField,
          ),
        const Divider(height: 1),
        Flexible(child: child),
        if (footer != null)
          Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: footer,
          ),
      ],
    );
  }
}
