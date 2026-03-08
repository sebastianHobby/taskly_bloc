import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/taskly_sheet_chrome.dart';

class TasklyFormSheet extends StatelessWidget {
  const TasklyFormSheet({
    required this.child,
    required this.preset,
    this.title,
    this.padding,
    super.key,
  });

  final String? title;
  final Widget child;
  final TasklyFormPreset preset;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.8;
        return Padding(
          padding: padding ?? EdgeInsets.all(tokens.spaceXl),
          child: TasklySheetChrome(
            variant: TasklySheetVariant.standard,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: tokens.spaceXl),
                    ],
                    Flexible(
                      child: SingleChildScrollView(
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
