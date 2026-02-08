import 'package:flutter/material.dart';
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
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<DisplayDensity>(
        segments: const [
          ButtonSegment(
            value: DisplayDensity.standard,
            label: Text('Standard'),
          ),
          ButtonSegment(
            value: DisplayDensity.compact,
            label: Text('Compact'),
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
