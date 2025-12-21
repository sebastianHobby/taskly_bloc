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

  Color _colorFromHexOrFallback(String? hex) {
    final normalized = (hex ?? '').replaceAll('#', '');
    if (normalized.length != 6) return Colors.black;
    return Color(int.parse('FF$normalized', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHexOrFallback(label.color);
    return ListTile(
      key: Key('label-${label.id}'),
      onTap: () => onTap(label),
      leading: Icon(Icons.label_outline, color: color),
      title: Text(
        label.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
