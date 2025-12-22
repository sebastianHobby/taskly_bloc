import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/labels/widgets/label_list_tile.dart';
import 'package:taskly_bloc/routing/routes.dart';

class LabelsListView extends StatelessWidget {
  const LabelsListView({
    required this.labels,
    this.isSheetOpen,
    super.key,
  });

  final List<Label> labels;
  final ValueNotifier<bool>? isSheetOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final label in labels)
          LabelListTile(
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
      ],
    );
  }
}
