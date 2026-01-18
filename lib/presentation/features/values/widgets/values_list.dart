import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/ui/confirmation_dialog_helpers.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_list_bloc.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/widgets/value_chip.dart';
import 'package:taskly_ui/taskly_ui.dart';

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
            deleteLabel: context.l10n.deleteLabel,
            confirmDismiss: () => ConfirmationDialog.show(
              context,
              title: context.l10n.deleteValue,
              confirmLabel: context.l10n.deleteLabel,
              cancelLabel: context.l10n.cancelLabel,
              isDestructive: true,
              icon: Icons.delete_outline_rounded,
              iconColor: Theme.of(context).colorScheme.error,
              iconBackgroundColor: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.3),
              content: buildDeleteConfirmationContent(
                context,
                itemName: value.name,
                description: context.l10n.deleteValueCascadeDescription,
              ),
            ),
            onDismissed: () {
              context.read<ValueListBloc>().add(
                ValueListEvent.deleteValue(value: value),
              );
              showDeleteSnackBar(
                context: context,
                message: context.l10n.valueDeletedSuccessfully,
              );
            },
            child: ListTile(
              title: Text(value.name),
              leading: ValueChip(
                data: value.toChipData(context),
                variant: ValueChipVariant.outlined,
                iconOnly: true,
              ),
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
