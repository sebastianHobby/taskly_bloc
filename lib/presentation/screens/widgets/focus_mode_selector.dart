import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/presentation/screens/widgets/focus_mode_card.dart';

/// Horizontal selector for choosing a focus mode.
class FocusModeSelector extends StatelessWidget {
  const FocusModeSelector({
    required this.currentFocusMode,
    required this.onFocusModeSelected,
    super.key,
  });

  final FocusMode currentFocusMode;
  final void Function(FocusMode) onFocusModeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: FocusMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final focusMode = FocusMode.values[index];
          return SizedBox(
            width: 160,
            child: FocusModeCard(
              focusMode: focusMode,
              isSelected: focusMode == currentFocusMode,
              onTap: () => onFocusModeSelected(focusMode),
              isRecommended: focusMode == FocusMode.sustainable,
            ),
          );
        },
      ),
    );
  }
}
