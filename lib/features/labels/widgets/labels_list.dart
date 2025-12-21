import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/view/label_detail_view.dart';
import 'package:taskly_bloc/features/labels/widgets/label_list_tile.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class LabelsListView extends StatelessWidget {
  const LabelsListView({
    required this.labels,
    required this.labelRepository,
    this.isSheetOpen,
    super.key,
  });

  final List<Label> labels;
  final LabelRepositoryContract labelRepository;
  final ValueNotifier<bool>? isSheetOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: labels.length,
      itemBuilder: (context, index) {
        final label = labels[index];
        return LabelListTile(
          label: label,
          onTap: (label) async {
            isSheetOpen?.value = true;
            await showDetailModal<void>(
              context: context,
              childBuilder: (modalSheetContext) => SafeArea(
                top: false,
                child: LabelDetailSheetPage(
                  labelId: label.id,
                  labelRepository: labelRepository,
                  onSuccess: (message) {
                    Navigator.of(modalSheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  onError: (errorMessage) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  },
                ),
              ),
              modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
            );

            isSheetOpen?.value = false;
          },
        );
      },
    );
  }
}
