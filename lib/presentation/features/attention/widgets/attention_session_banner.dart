import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/attention/model/attention_session_banner_vm.dart';

class AttentionSessionBanner extends StatelessWidget {
  const AttentionSessionBanner({
    required this.vm,
    required this.onReview,
    required this.onDismiss,
    super.key,
  });

  final AttentionSessionBannerVm vm;
  final VoidCallback onReview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (icon, accentColor) = switch (vm.severity) {
      AttentionSessionBannerSeverity.critical => (
        Icons.error_outline,
        scheme.error,
      ),
      AttentionSessionBannerSeverity.warning => (
        Icons.warning_amber_outlined,
        scheme.secondary,
      ),
    };

    return Semantics(
      container: true,
      label: switch (vm.severity) {
        AttentionSessionBannerSeverity.critical =>
          'Critical items need attention.',
        AttentionSessionBannerSeverity.warning => 'Items need attention.',
      },
      child: Material(
        color: scheme.surface.withValues(alpha: 0),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.40)),
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Review what needs your attention.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onReview,
                child: const Text('Review'),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
