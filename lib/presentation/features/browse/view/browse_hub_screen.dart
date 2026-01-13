import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_query_builder.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

class BrowseHubScreen extends StatelessWidget {
  const BrowseHubScreen({super.key});

  // L4: compact bottom bar shows first 4 system screens.
  static const int _compactBottomBarVisibleCount = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final systemScreens = SystemScreenDefinitions.navigationScreens;
    final hiddenSystemKeys = systemScreens
        .take(_compactBottomBarVisibleCount)
        .map((s) => s.screenKey)
        .toSet();

    final systemTiles = systemScreens
        .where((s) => !hiddenSystemKeys.contains(s.screenKey))
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.browseTitle,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: null,
                  icon: const Icon(Icons.search_rounded),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).searchFieldLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final tile in systemTiles.map(_BrowseTileVm.fromSystem))
                  _BrowseTile(
                    tile: tile,
                    backgroundColor: _tileColor(
                      colorScheme,
                      tile.screenKey,
                    ),
                    onTap: () => context.go(Routing.screenPath(tile.screenKey)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _tileColor(ColorScheme colorScheme, String screenKey) {
    return switch (screenKey) {
      'projects' => colorScheme.secondaryContainer,
      'values' => colorScheme.tertiaryContainer,
      'statistics' => colorScheme.primaryContainer,
      'settings' => colorScheme.surfaceContainerHighest,
      _ => colorScheme.surfaceContainerHigh,
    };
  }
}

class _BrowseTileVm {
  _BrowseTileVm({
    required this.screenKey,
    required this.title,
    required this.icon,
    required this.badgeStream,
  });

  factory _BrowseTileVm.fromSystem(ScreenDefinition screen) {
    final iconSet = const NavigationIconResolver().resolve(
      screenId: screen.screenKey,
      iconName: screen.chrome.iconName,
    );

    final badgeStream = NavigationBadgeService(
      taskRepository: getIt<TaskRepositoryContract>(),
      projectRepository: getIt<ProjectRepositoryContract>(),
      screenQueryBuilder: getIt<ScreenQueryBuilder>(),
    ).badgeStreamFor(screen);

    return _BrowseTileVm(
      screenKey: screen.screenKey,
      title: screen.name,
      icon: iconSet.icon,
      badgeStream: badgeStream,
    );
  }

  final String screenKey;
  final String title;
  final IconData icon;
  final Stream<int>? badgeStream;
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.tile,
    required this.backgroundColor,
    required this.onTap,
  });

  final _BrowseTileVm tile;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: backgroundColor,
                child: Icon(tile.icon, color: colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tile.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _TileCountBadge(stream: tile.badgeStream),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileCountBadge extends StatelessWidget {
  const _TileCountBadge({required this.stream});

  final Stream<int>? stream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return const SizedBox.shrink();
        return Text(
          count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}
