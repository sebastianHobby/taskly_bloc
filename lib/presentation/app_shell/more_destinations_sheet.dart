import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

Future<String?> showMoreDestinationsSheet({
  required BuildContext context,
  required List<NavigationDestinationVm> destinations,
  String? activeScreenId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _MoreDestinationsSheet(
      destinations: destinations,
      activeScreenId: activeScreenId,
    ),
  );
}

class _MoreDestinationsSheet extends StatefulWidget {
  const _MoreDestinationsSheet({
    required this.destinations,
    required this.activeScreenId,
  });

  final List<NavigationDestinationVm> destinations;
  final String? activeScreenId;

  @override
  State<_MoreDestinationsSheet> createState() => _MoreDestinationsSheetState();
}

class _MoreDestinationsSheetState extends State<_MoreDestinationsSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = widget.destinations
        .where((d) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return d.label.toLowerCase().contains(q);
        })
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'More',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search destinations',
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final dest = filtered[index];
                  final isActive = dest.screenId == widget.activeScreenId;
                  return ListTile(
                    leading: Icon(dest.icon),
                    title: Text(dest.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DestinationBadge(stream: dest.badgeStream),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check, color: colorScheme.primary),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(dest.screenId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationBadge extends StatelessWidget {
  const _DestinationBadge({required this.stream});

  final Stream<int>? stream;

  @override
  Widget build(BuildContext context) {
    if (stream == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return const SizedBox.shrink();
        return Badge(label: Text(count.toString()));
      },
    );
  }
}
