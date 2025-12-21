import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/view/value_detail_view.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';

class AddValueFab extends StatelessWidget {
  const AddValueFab({
    required this.valueRepository,
    this.isSheetOpen,
    super.key,
  });

  final ValueRepositoryContract valueRepository;
  final ValueNotifier<bool>? isSheetOpen;

  @override
  Widget build(BuildContext fabContext) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSheetOpen ?? ValueNotifier<bool>(false),
      builder: (context, hidden, _) {
        if (hidden) return const SizedBox.shrink();
        return FloatingActionButton(
          tooltip: fabContext.l10n.createValueTooltip,
          onPressed: () async {
            isSheetOpen?.value = true;
            await showDetailModal<void>(
              context: fabContext,
              childBuilder: (modalSheetContext) => SafeArea(
                top: false,
                child: ValueDetailSheetPage(
                  valueRepository: valueRepository,
                  onSuccess: (message) {
                    Navigator.of(modalSheetContext).pop();
                    ScaffoldMessenger.of(fabContext).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  onError: (errorMessage) {
                    ScaffoldMessenger.of(fabContext).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  },
                ),
              ),
              modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
            );

            isSheetOpen?.value = false;
          },
          heroTag: 'create_value_fab',
          child: const Icon(Icons.add),
        );
      },
    );
  }
}
