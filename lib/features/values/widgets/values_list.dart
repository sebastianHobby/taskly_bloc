import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/view/value_detail_view.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/features/values/widgets/value_list_tile.dart';

class ValuesListView extends StatelessWidget {
  const ValuesListView({
    required this.values,
    required this.valueRepository,
    this.isSheetOpen,
    super.key,
  });

  final List<ValueTableData> values;
  final ValueRepository valueRepository;
  final ValueNotifier<bool>? isSheetOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: values.length,
      itemBuilder: (context, index) {
        final v = values[index];
        return ValueListTile(
          value: v,
          onTap: (value) async {
            isSheetOpen?.value = true;
            await showDetailModal<void>(
              context: context,
              childBuilder: (modalSheetContext) => SafeArea(
                top: false,
                child: ValueDetailSheetPage(
                  valueId: value.id,
                  valueRepository: valueRepository,
                  onSuccess: (message) {
                    Navigator.of(modalSheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  onError: (errorMessage) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $errorMessage')),
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
