import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/view/label_detail_view.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class AddLabelFab extends StatelessWidget {
  const AddLabelFab({
    required this.labelRepository,
    required this.initialType,
    required this.lockType,
    required this.tooltip,
    required this.heroTag,
    this.isSheetOpen,
    super.key,
  });

  final LabelRepositoryContract labelRepository;
  final LabelType initialType;
  final bool lockType;
  final String tooltip;
  final String heroTag;
  final ValueNotifier<bool>? isSheetOpen;

  @override
  Widget build(BuildContext fabContext) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSheetOpen ?? ValueNotifier<bool>(false),
      builder: (context, hidden, _) {
        if (hidden) return const SizedBox.shrink();
        return FloatingActionButton(
          tooltip: tooltip,
          onPressed: () async {
            isSheetOpen?.value = true;

            await showDetailModal<void>(
              context: fabContext,
              childBuilder: (modalSheetContext) => SafeArea(
                top: false,
                child: LabelDetailSheetPage(
                  labelRepository: labelRepository,
                  initialType: initialType,
                  lockType: lockType,
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
          heroTag: heroTag,
          child: const Icon(Icons.add),
        );
      },
    );
  }
}
