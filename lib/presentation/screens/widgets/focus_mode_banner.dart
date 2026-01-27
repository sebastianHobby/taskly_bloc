import 'package:flutter/material.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
    final tokens = TasklyTokens.of(context);
    final semanticsLabel =
        'Current focus mode: ${focusMode.displayName}. ${focusMode.tagline}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceMd,
        tokens.spaceLg,
        tokens.spaceSm,
      ),
      child: Semantics(
        container: true,
        label: semanticsLabel,
        button: true,
        child: Tooltip(
          message: 'Open Focus Setup',
          child: Material(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceLg,
                  vertical: tokens.spaceMd,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _FocusModeIcon(focusMode: focusMode),
                    SizedBox(width: tokens.spaceSm),
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
                          SizedBox(height: TasklyTokens.of(context).spaceSm),
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
                    SizedBox(width: tokens.spaceSm),
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
