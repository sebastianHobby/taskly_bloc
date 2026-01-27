import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class NotFoundRoutePage extends StatelessWidget {
  const NotFoundRoutePage({
    super.key,
    this.message,
    this.details,
  });

  final String? message;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final text = message?.trim().isNotEmpty ?? false
        ? message!.trim()
        : 'Page not found';

    if (details != null && details!.trim().isNotEmpty) {
      AppLog.routineThrottled(
        'routing.not_found.details',
        const Duration(seconds: 5),
        'routing',
        'NotFound details: ${details!.trim()}',
      );
    }

    return Padding(
      padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.warning_amber_rounded,
            title: text,
            description: 'This page does not exist.',
            actionLabel: 'Go Home',
            onAction: () =>
                GoRouter.of(context).go(Routing.screenPath('my_day')),
          ),
        ),
      ),
    );
  }
}
