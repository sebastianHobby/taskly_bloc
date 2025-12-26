import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/truncated_label_chips.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A section displaying labels and values in list tiles.
///
/// Shows values first, then labels, with proper spacing.
/// Returns an empty widget if no labels are provided.
class LabelsSection extends StatelessWidget {
  const LabelsSection({
    required this.labels,
    this.padding = const EdgeInsets.only(top: 8),
    super.key,
  });

  /// The labels to display.
  final List<Label> labels;

  /// Padding around the section.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final valueLabels = labels.where((l) => l.type == LabelType.value).toList();
    final typeLabels = labels.where((l) => l.type == LabelType.label).toList();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (valueLabels.isNotEmpty) TruncatedLabelChips(labels: valueLabels),
          if (valueLabels.isNotEmpty && typeLabels.isNotEmpty)
            const SizedBox(height: 4),
          if (typeLabels.isNotEmpty) TruncatedLabelChips(labels: typeLabels),
        ],
      ),
    );
  }
}
