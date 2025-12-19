import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/view/value_detail_view.dart';
import 'package:taskly_bloc/features/values/widgets/value_list_tile.dart';

class ValuesListView extends StatelessWidget {
  const ValuesListView({
    required this.values,
    required this.valueRepository,
    super.key,
  });

  final List<ValueTableData> values;
  final ValueRepository valueRepository;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: values.length,
      itemBuilder: (context, index) {
        final v = values[index];
        return ValueListTile(
          value: v,
          onTap: (value) async {
            late PersistentBottomSheetController controller;
            controller = Scaffold.of(context).showBottomSheet(
              (ctx) => Material(
                color: Theme.of(ctx).colorScheme.surface,
                child: SafeArea(
                  top: false,
                  child: ValueDetailSheetPage(
                    valueId: value.id,
                    valueRepository: valueRepository,
                    onSuccess: (message) {
                      controller.close();
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
              ),
              elevation: 8,
            );
          },
        );
      },
    );
  }
}
