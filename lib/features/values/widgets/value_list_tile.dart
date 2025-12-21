import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';

class ValueListTile extends StatelessWidget {
  const ValueListTile({
    required this.value,
    required this.onTap,
    super.key,
  });

  final ValueModel value;
  final void Function(ValueModel) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('value-${value.id}'),
      onTap: () => onTap(value),
      title: Text(
        value.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
