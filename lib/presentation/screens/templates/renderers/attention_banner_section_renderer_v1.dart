import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_bloc.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

class AttentionBannerSectionRendererV1 extends StatelessWidget {
  const AttentionBannerSectionRendererV1({
    super.key,
    this.title,
  });
  final String? title;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AttentionBannerBloc>().state;
    final total = state.totalCount;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: LinearProgressIndicator(),
      );
    }

    final badges = <Widget>[];
    if (state.criticalCount > 0) {
      badges.add(
        CountBadge(
          count: state.criticalCount,
          color: scheme.error,
          label: 'Critical',
        ),
      );
    }
    if (state.warningCount > 0) {
      badges.add(
        CountBadge(
          count: state.warningCount,
          color: Colors.orange,
          label: 'Warning',
        ),
      );
    }
    if (state.infoCount > 0) {
      badges.add(
        CountBadge(
          count: state.infoCount,
          color: scheme.primary,
          label: 'Info',
        ),
      );
    }

    return SupportSectionCard(
      title: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Attention',
            child: Semantics(
              label: 'Attention',
              child: Icon(
                total == 0
                    ? Icons.check_circle_outline
                    : Icons.notifications_none,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: state.errorMessage != null
                ? Text(
                    'Attention unavailable',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : badges.isEmpty
                ? Text(
                    'All clear',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: badges,
                  ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: () => Routing.toScreenKey(
              context,
              AttentionBannerBloc.overflowScreenKey,
            ),
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Attention'),
          ),
        ],
      ),
    );
  }
}
