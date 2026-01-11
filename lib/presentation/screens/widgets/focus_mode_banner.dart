import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';

/// Banner showing the currently selected focus mode.
///
/// Tapping the banner should open the Focus Setup wizard.
class FocusModeBanner extends StatelessWidget {
  const FocusModeBanner({
    required this.focusMode,
    required this.onTap,
    super.key,
  });

  final FocusMode focusMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        button: true,
        label: 'Current focus mode: ${focusMode.displayName}',
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ListTile(
              leading: _FocusModeIcon(focusMode: focusMode),
              title: Text(focusMode.displayName),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusModeIcon extends StatelessWidget {
  const _FocusModeIcon({required this.focusMode});

  final FocusMode focusMode;

  @override
  Widget build(BuildContext context) {
    final icon = switch (focusMode) {
      FocusMode.intentional => Icons.center_focus_strong,
      FocusMode.sustainable => Icons.eco,
      FocusMode.responsive => Icons.bolt,
      FocusMode.personalized => Icons.tune,
    };

    return CircleAvatar(
      child: Icon(icon),
    );
  }
}
