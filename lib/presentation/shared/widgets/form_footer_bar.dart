import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class FormFooterBar extends StatelessWidget {
  const FormFooterBar({
    required this.submitLabel,
    required this.onSubmit,
    required this.submitEnabled,
    this.leading,
    super.key,
  });

  final String submitLabel;
  final VoidCallback onSubmit;
  final bool submitEnabled;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final leadingWidget = leading;
    final rowChildren = <Widget>[
      if (leadingWidget != null) ...[
        Expanded(child: leadingWidget),
        SizedBox(width: tokens.spaceMd),
      ] else
        const Spacer(),
      FilledButton(
        onPressed: submitEnabled ? onSubmit : null,
        child: Text(submitLabel),
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg3,
        tokens.spaceMd,
        tokens.spaceLg3,
        tokens.spaceLg3,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(children: rowChildren),
    );
  }
}
