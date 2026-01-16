import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_support_section_widgets.dart';

class AttentionBannerSectionRendererV2 extends StatelessWidget {
  const AttentionBannerSectionRendererV2({
    required this.data,
    super.key,
    this.title,
  });

  final AttentionBannerV2SectionResult data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final showReviews = data.reviewCount > 0;
    final showAlerts = data.alertsCount > 0;
    final showAny = showReviews || showAlerts;

    final width = MediaQuery.sizeOf(context).width;
    final useHorizontalScroll = width < 480;

    final showCriticalHint = data.criticalCount > 0;

    final strip = SupportSectionCard(
      title: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Routing.toScreenKey(context, data.overflowScreenKey);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_none,
                  color: scheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: useHorizontalScroll
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: _CollapsedChipsRow(
                              showReviews: showReviews,
                              showAlerts: showAlerts,
                              result: data,
                              overflowScreenKey: data.overflowScreenKey,
                            ),
                          )
                        : _CollapsedChipsRow(
                            showReviews: showReviews,
                            showAlerts: showAlerts,
                            result: data,
                            overflowScreenKey: data.overflowScreenKey,
                          ),
                  ),
                ),
                if (showCriticalHint) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${data.criticalCount} critical',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: showAny
          ? KeyedSubtree(key: const ValueKey('strip'), child: strip)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}

class _CollapsedChipsRow extends StatelessWidget {
  const _CollapsedChipsRow({
    required this.showReviews,
    required this.showAlerts,
    required this.result,
    required this.overflowScreenKey,
  });

  final bool showReviews;
  final bool showAlerts;
  final AttentionBannerV2SectionResult result;
  final String overflowScreenKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showReviews) ...[
          ActionChip(
            label: Text('Reviews • ${result.reviewCount}'),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Routing.toScreenKeyWithQuery(
                context,
                overflowScreenKey,
                queryParameters: const {'bucket': 'review'},
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        if (showAlerts) ...[
          ActionChip(
            label: Text('Alerts • ${result.alertsCount}'),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Routing.toScreenKeyWithQuery(
                context,
                overflowScreenKey,
                queryParameters: const {'bucket': 'warning'},
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}
