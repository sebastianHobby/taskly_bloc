import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/widgets/value_list_tile.dart';
import 'package:taskly_bloc/routing/routes.dart';

class ValuesListView extends StatelessWidget {
  const ValuesListView({
    required this.values,
    required this.valueRepository,
    this.isSheetOpen,
    super.key,
  });

  final List<ValueModel> values;
  final ValueRepositoryContract valueRepository;
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
            await context.pushNamed(
              AppRouteName.valueDetail,
              pathParameters: {'valueId': value.id},
            );
            isSheetOpen?.value = false;
          },
        );
      },
    );
  }
}
