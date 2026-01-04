import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

/// Hero card showing focus strategy and overall progress.
///
/// Displays current allocation strategy, total task count, and progress.
/// Can be tapped to expand and show configuration hint.
class FocusHeroCard extends StatefulWidget {
  const FocusHeroCard({
    required this.result,
    this.userName,
    super.key,
  });

  final AllocationSectionResult result;
  final String? userName;

  @override
  State<FocusHeroCard> createState() => _FocusHeroCardState();
}

class _FocusHeroCardState extends State<FocusHeroCard> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? '🌅 Good Morning'
        : hour < 17
        ? '🌤️ Good Afternoon'
        : '🌙 Good Evening';

    final name = widget.userName;
    return name != null && name.isNotEmpty
        ? '$timeGreeting, $name'
        : timeGreeting;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: colorScheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _getGreeting(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
