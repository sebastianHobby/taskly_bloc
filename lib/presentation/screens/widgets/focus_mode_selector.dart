import 'package:flutter/material.dart';
import 'package:taskly_domain/allocation.dart';
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
    const modes = <FocusMode>[FocusMode.sustainable, FocusMode.responsive];

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final focusMode = modes[index];
          return SizedBox(
            width: 320,
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
