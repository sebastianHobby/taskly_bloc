import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_snapshot_coordinator.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';

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

  Future<void> _showQuickSwitch(BuildContext context) async {
    final chosen = await _pickFocusMode(context);
    if (!context.mounted) return;
    if (chosen == null || chosen == focusMode) return;

    final confirmed = await _confirmSwitch(context, chosen);
    if (!context.mounted) return;
    if (!confirmed) return;

    final settingsRepo = getIt<SettingsRepositoryContract>();
    final current = await settingsRepo.load<AllocationConfig>(
      SettingsKey.allocation,
    );

    final updated = current.copyWith(
      focusMode: chosen,
      hasSelectedFocusMode: true,
    );

    await settingsRepo.save(SettingsKey.allocation, updated);
    getIt<AllocationSnapshotCoordinator>().requestRefreshNow(
      AllocationSnapshotRefreshReason.manual,
    );
  }

  Future<FocusMode?> _pickFocusMode(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    if (isMobile) {
      return showModalBottomSheet<FocusMode>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final mode in FocusMode.values)
                  ListTile(
                    leading: _FocusModeIcon(focusMode: mode),
                    title: Text(mode.displayName),
                    trailing: mode == focusMode
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(mode),
                  ),
              ],
            ),
          );
        },
      );
    }

    return showDialog<FocusMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch focus mode'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in FocusMode.values)
                ListTile(
                  leading: _FocusModeIcon(focusMode: mode),
                  title: Text(mode.displayName),
                  trailing: mode == focusMode ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(mode),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmSwitch(BuildContext context, FocusMode mode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch focus mode?'),
        content: Text(
          "Switch to ${mode.displayName}? This will update today's list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Semantics(
        container: true,
        label: 'Current focus mode: ${focusMode.displayName}',
        child: Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _FocusModeIcon(focusMode: focusMode),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Focus mode: ${focusMode.displayName}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showQuickSwitch(context),
                    child: const Text('Switch'),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
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
