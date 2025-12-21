import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/features/labels/widgets/label_list_tile.dart';
import 'package:taskly_bloc/routing/routes.dart';

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
            await context.pushNamed(
              AppRouteName.labelDetail,
              pathParameters: {'labelId': label.id},
            );
            isSheetOpen?.value = false;
          },
        );
      },
    );
  }
}
