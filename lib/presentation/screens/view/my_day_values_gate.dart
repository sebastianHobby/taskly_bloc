import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

class MyDayValuesGate extends StatelessWidget {
  const MyDayValuesGate({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.empty(
        empty: TasklyEmptyStateSpec(
          icon: Icons.star_border,
          title: l10n.myDayUnlockSuggestionsTitle,
          description: l10n.myDayUnlockSuggestionsBody,
          actionLabel: l10n.myDayStartSetupLabel,
          onAction: () => Routing.toScreenKey(context, 'values'),
        ),
      ),
    );
  }
}
