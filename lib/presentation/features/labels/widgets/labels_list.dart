import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/presentation/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/label_list_tile.dart';
import 'package:taskly_bloc/core/routing/routes.dart';

class LabelsListView extends StatelessWidget {
  const LabelsListView({
    required this.labels,
    this.isSheetOpen,
    this.enableSwipeToDelete = true,
    super.key,
  });

  final List<Label> labels;
  final ValueNotifier<bool>? isSheetOpen;
  final bool enableSwipeToDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final label in labels)
          SwipeToDelete(
            itemKey: ValueKey(label.id),
            enabled: enableSwipeToDelete,
            confirmDismiss: () => showDeleteConfirmationDialog(
              context: context,
              title:
                  'Delete ${label.type == LabelType.label ? 'Label' : 'Value'}',
              itemName: label.name,
              description:
                  'This ${label.type == LabelType.label ? 'label' : 'value'} will be removed from all tasks. This action cannot be undone.',
            ),
            onDismissed: () {
              context.read<LabelOverviewBloc>().add(
                LabelOverviewEvent.deleteLabel(label: label),
              );
              showDeleteSnackBar(
                context: context,
                message:
                    '${label.type == LabelType.label ? 'Label' : 'Value'} deleted',
              );
            },
            child: LabelListTile(
              label: label,
              onTap: (label) async {
                isSheetOpen?.value = true;
                await context.pushNamed(
                  AppRouteName.labelDetail,
                  pathParameters: {'labelId': label.id},
                );
                isSheetOpen?.value = false;
              },
            ),
          ),
      ],
    );
  }
}
