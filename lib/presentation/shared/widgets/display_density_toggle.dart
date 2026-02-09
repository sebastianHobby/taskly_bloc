import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/preferences.dart';

class DisplayDensityToggle extends StatelessWidget {
  const DisplayDensityToggle({
    required this.density,
    required this.onChanged,
    super.key,
  });

  final DisplayDensity density;
  final ValueChanged<DisplayDensity> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<DisplayDensity>(
        segments: [
          ButtonSegment(
            value: DisplayDensity.standard,
            label: Text(l10n.displayDensityStandard),
          ),
          ButtonSegment(
            value: DisplayDensity.compact,
            label: Text(l10n.displayDensityCompact),
          ),
        ],
        selected: {density},
        onSelectionChanged: (selection) {
          if (selection.isEmpty) return;
          onChanged(selection.first);
        },
      ),
    );
  }
}
