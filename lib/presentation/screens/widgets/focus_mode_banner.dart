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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semanticsLabel =
        'Current focus mode: ${focusMode.displayName}. ${focusMode.tagline}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Semantics(
        container: true,
        label: semanticsLabel,
        button: true,
        child: Tooltip(
          message: 'Open Focus Setup',
          child: Material(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _FocusModeIcon(focusMode: focusMode),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            focusMode.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            focusMode.tagline,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
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
      FocusMode.intentional => Icons.gps_fixed,
      FocusMode.sustainable => Icons.tune,
      FocusMode.responsive => Icons.bolt,
      FocusMode.personalized => Icons.tune,
    };

    return CircleAvatar(
      child: Icon(icon),
    );
  }
}
