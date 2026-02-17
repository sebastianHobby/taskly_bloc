import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/values_hero_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ValuesListView extends StatelessWidget {
  const ValuesListView({
    required this.items,
    this.isSheetOpen,
    super.key,
  });

  final List<ValueHeroStatsItem> items;
  final ValueNotifier<bool>? isSheetOpen;

  @override
  Widget build(BuildContext context) {
    AppLog.routineThrottledStructured(
      'values.list.build',
      const Duration(seconds: 2),
      'values.list',
      'render list',
      fields: <String, Object?>{'count': items.length},
    );

    final selection = context.read<SelectionBloc>();
    final tokens = TasklyTokens.of(context);
    selection.updateVisibleEntities(
      items
          .map(
            (item) => SelectionEntityMeta(
              key: SelectionKey(
                entityType: EntityType.value,
                entityId: item.value.id,
              ),
              displayName: item.value.name,
              canDelete: true,
            ),
          )
          .toList(growable: false),
    );

    final rows = [
      for (final item in items)
        () {
          final value = item.value;
          final key = SelectionKey(
            entityType: EntityType.value,
            entityId: value.id,
          );

          final selectionMode = selection.isSelectionMode;
          final isSelected = selection.isSelected(key);

          return TasklyRowSpec.value(
            key: 'value-${value.id}',
            data: _buildRowData(context, item),
            preset: selectionMode
                ? TasklyValueRowPreset.heroSelection(selected: isSelected)
                : const TasklyValueRowPreset.hero(),
            actions: TasklyValueRowActions(
              onTap: () async {
                if (selection.shouldInterceptTapAsSelection()) {
                  selection.handleEntityTap(key);
                  return;
                }
                isSheetOpen?.value = true;
                Routing.toEntity(context, EntityType.value, value.id);
                isSheetOpen?.value = false;
              },
              onLongPress: () {
                selection.enterSelectionMode(initialSelection: key);
              },
              onToggleSelected: () =>
                  selection.toggleSelection(key, extendRange: false),
            ),
          );
        }(),
    ];

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.content(
        sections: [
          TasklySectionSpec.standardList(
            id: 'values',
            rows: rows,
          ),
        ],
      ),
      entityRowPadding: EdgeInsets.symmetric(
        horizontal: tokens.sectionPaddingH,
      ),
    );
  }
}

TasklyValueRowData _buildRowData(
  BuildContext context,
  ValueHeroStatsItem item,
) {
  final value = item.value;
  final accentColor = ColorUtils.valueColorForTheme(context, value.color);
  final iconData = getIconDataFromName(value.iconName) ?? Icons.star;
  final hasCompletionData = item.completionCount > 0;
  final completionLabel = hasCompletionData
      ? context.l10n.valuesCompletionShareLabel(
          item.completionSharePercent.toStringAsFixed(0),
        )
      : null;
  final completionSubLabel = context.l10n.valuesCompletionShareSubtitle;

  final emptyTitle = context.l10n.valuesCompletionEmptyTitle;
  final emptySubtitle = context.l10n.valuesCompletionEmptySubtitle;

  final metrics = <TasklyValueRowMetric>[];
  if (item.activeTaskCount > 0) {
    metrics.add(
      TasklyValueRowMetric(
        label: context.l10n.tasksTitle,
        value: item.activeTaskCount.toString(),
      ),
    );
  }
  if (item.activeProjectCount > 0) {
    metrics.add(
      TasklyValueRowMetric(
        label: context.l10n.projectsTitle,
        value: item.activeProjectCount.toString(),
      ),
    );
  }

  return TasklyValueRowData(
    id: value.id,
    title: value.name,
    icon: iconData,
    accentColor: accentColor,
    primaryStatLabel: completionLabel,
    primaryStatSubLabel: hasCompletionData ? completionSubLabel : null,
    emptyStatTitle: hasCompletionData ? null : emptyTitle,
    emptyStatSubtitle: hasCompletionData ? null : emptySubtitle,
    metrics: metrics,
  );
}
