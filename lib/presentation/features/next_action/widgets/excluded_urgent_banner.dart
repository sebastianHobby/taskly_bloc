import 'package:flutter/material.dart';

/// Banner for displaying excluded urgent tasks warning
class ExcludedUrgentBanner extends StatelessWidget {
  const ExcludedUrgentBanner({
    required this.count,
    required this.onDismiss,
    required this.onReview,
    super.key,
  });

  final int count;
  final VoidCallback onDismiss;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count urgent excluded',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Text(
                    'Tasks need attention',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onReview,
              child: const Text('Review'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
