import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/presentation/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_list_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/value_chip.dart';

class ValuesListView extends StatelessWidget {
  const ValuesListView({
    required this.values,
    this.isSheetOpen,
    this.enableSwipeToDelete = true,
    super.key,
  });

  final List<Value> values;
  final ValueNotifier<bool>? isSheetOpen;
  final bool enableSwipeToDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final value in values)
          SwipeToDelete(
            itemKey: ValueKey(value.id),
            enabled: enableSwipeToDelete,
            confirmDismiss: () => showDeleteConfirmationDialog(
              context: context,
              title: 'Delete Value',
              itemName: value.name,
              description:
                  'This value will be removed from all tasks. This action cannot be undone.',
            ),
            onDismissed: () {
              context.read<ValueListBloc>().add(
                ValueListEvent.deleteValue(value: value),
              );
              showDeleteSnackBar(
                context: context,
                message: 'Value deleted',
              );
            },
            child: ListTile(
              title: Text(value.name),
              leading: ValueChip(value: value),
              onTap: () async {
                isSheetOpen?.value = true;
                Routing.toEntity(context, EntityType.value, value.id);
                isSheetOpen?.value = false;
              },
            ),
          ),
      ],
    );
  }
}
