import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_tile_model_mapper.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ValuesListView extends StatelessWidget {
  const ValuesListView({
    required this.values,
    this.isSheetOpen,
    super.key,
  });

  final List<Value> values;
  final ValueNotifier<bool>? isSheetOpen;

  @override
  Widget build(BuildContext context) {
    AppLog.warnThrottledStructured(
      'values.list.build',
      const Duration(seconds: 2),
      'values.list',
      'render list',
      fields: <String, Object?>{'count': values.length},
    );

    final selection = context.read<SelectionCubit>();
    final tokens = TasklyTokens.of(context);
    selection.updateVisibleEntities(
      values
          .map(
            (v) => SelectionEntityMeta(
              key: SelectionKey(entityType: EntityType.value, entityId: v.id),
              displayName: v.name,
              canDelete: true,
            ),
          )
          .toList(growable: false),
    );

    final rows = [
      for (final value in values)
        () {
          final key = SelectionKey(
            entityType: EntityType.value,
            entityId: value.id,
          );

          final selectionMode = selection.isSelectionMode;
          final isSelected = selection.isSelected(key);

          return TasklyRowSpec.value(
            key: 'value-${value.id}',
            data: value.toRowData(context),
            preset: selectionMode
                ? TasklyValueRowPreset.bulkSelection(selected: isSelected)
                : const TasklyValueRowPreset.standard(),
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
