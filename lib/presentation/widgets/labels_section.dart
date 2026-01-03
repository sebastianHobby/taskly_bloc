import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/truncated_label_chips.dart';
import 'package:taskly_bloc/presentation/widgets/value_chip.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A section displaying labels and values in list tiles.
///
/// Shows values first (with optional ranks) in a prominent row,
/// then labels below in a more compact style.
/// Returns an empty widget if no labels are provided.
class LabelsSection extends StatelessWidget {
  const LabelsSection({
    required this.labels,
    this.valueRanks,
    this.padding = const EdgeInsets.only(top: 8),
    super.key,
  });

  /// The labels to display.
  final List<Label> labels;

  /// Optional map of value label IDs to their rank (1-based).
  /// When provided, values will display their rank badge.
  final Map<String, int>? valueRanks;

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
          // Values row - uses ValueChip for enhanced visual prominence
          if (valueLabels.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: valueLabels.map((label) {
                final rank = valueRanks?[label.id];
                return ValueChip(
                  label: label,
                  rank: rank,
                );
              }).toList(),
            ),
          // Spacing between values and labels
          if (valueLabels.isNotEmpty && typeLabels.isNotEmpty)
            const SizedBox(height: 6),
          // Labels row - uses standard LabelChip
          if (typeLabels.isNotEmpty) TruncatedLabelChips(labels: typeLabels),
        ],
      ),
    );
  }
}
