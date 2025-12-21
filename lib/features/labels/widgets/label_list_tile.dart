import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';

class LabelListTile extends StatelessWidget {
  const LabelListTile({
    required this.label,
    required this.onTap,
    super.key,
  });

  final Label label;
  final void Function(Label) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('label-${label.id}'),
      onTap: () => onTap(label),
      title: Text(
        label.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
