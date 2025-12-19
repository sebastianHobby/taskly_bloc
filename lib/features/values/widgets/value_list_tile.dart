import 'package:flutter/material.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
// imports intentionally minimal for this tile

class ValueListTile extends StatelessWidget {
  const ValueListTile({
    required this.value,
    required this.onTap,
    super.key,
  });

  final ValueTableData value;
  final void Function(ValueTableData) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(value),
      title: Text(
        value.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
