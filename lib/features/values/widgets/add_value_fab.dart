import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/view/value_detail_view.dart';

class AddValueFab extends StatelessWidget {
  const AddValueFab({required this.valueRepository, super.key});

  final ValueRepository valueRepository;

  @override
  Widget build(BuildContext fabContext) {
    return FloatingActionButton(
      tooltip: 'Create value',
      onPressed: () async {
        late PersistentBottomSheetController controller;
        controller = Scaffold.of(fabContext).showBottomSheet(
          (ctx) => Material(
            color: Theme.of(ctx).colorScheme.surface,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: ValueDetailSheetPage(
                valueRepository: valueRepository,
                onSuccess: (message) {
                  controller.close();
                  ScaffoldMessenger.of(fabContext).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                },
                onError: (errorMessage) {
                  ScaffoldMessenger.of(fabContext).showSnackBar(
                    SnackBar(content: Text('Error: $errorMessage')),
                  );
                },
              ),
            ),
          ),
        );
      },
      heroTag: 'create_value_fab',
      child: const Icon(Icons.add),
    );
  }
}
