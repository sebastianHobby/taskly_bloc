import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/value_chip.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A section displaying values in list tiles.
///
/// Shows values with optional ranks in a prominent row.
/// Returns an empty widget if no values are provided.
class ValuesSection extends StatelessWidget {
  const ValuesSection({
    required this.values,
    this.valueRanks,
    this.padding = const EdgeInsets.only(top: 8),
    super.key,
  });

  /// The values to display.
  final List<Value> values;

  /// Optional map of value IDs to their rank (1-based).
  /// When provided, values will display their rank badge.
  final Map<String, int>? valueRanks;

  /// Padding around the section.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: values.map((value) {
          final rank = valueRanks?[value.id];
          return ValueChip(
            value: value,
            rank: rank,
          );
        }).toList(),
      ),
    );
  }
}
