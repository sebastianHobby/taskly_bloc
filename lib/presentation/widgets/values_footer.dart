import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_ui/taskly_ui.dart';

/// A shared footer widget to display Primary and Secondary values for tasks and projects.
///
/// Follows the design spec:
/// - Primary Value: Solid chip
/// - Secondary Values: Outlined chips
class ValuesFooter extends StatelessWidget {
  const ValuesFooter({
    required this.primaryValue,
    this.secondaryValues = const [],
    super.key,
  });

  final Value? primaryValue;
  final List<Value> secondaryValues;

  @override
  Widget build(BuildContext context) {
    if (primaryValue == null && secondaryValues.isEmpty) {
      return const SizedBox.shrink();
    }

    final primary = primaryValue;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (primary != null)
          ValueChip(
            data: primary.toChipData(context),
            variant: ValueChipVariant.solid,
            iconOnly: false,
            // You might add rank here if available in context, or keep generic
          ),
        ...secondaryValues.map(
          (value) => ValueChip(
            data: value.toChipData(context),
            variant: ValueChipVariant.outlined,
            iconOnly: true,
          ),
        ),
      ],
    );
  }
}
