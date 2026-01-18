import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui.dart';

/// Temporary placeholder for the global `/inbox` route.
///
/// Package D will replace this with the real Inbox feed screen once the
/// new feed architecture is in place.
class InboxPlaceholderPage extends StatelessWidget {
  const InboxPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ErrorStateWidget(
            message:
                'Inbox not implemented yet.\n\n'
                'The new Inbox feed route exists, but the feed screen is not '
                'implemented yet.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                GoRouter.of(context).go(Routing.screenPath('someday')),
            child: const Text('Go to Anytime'),
          ),
        ],
      ),
    );
  }
}
