import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
  static const _searchDebounce = Duration(milliseconds: 300);

  final Debouncer _searchDebouncer = Debouncer(_searchDebounce);
  String _query = '';

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    _searchDebouncer.schedule(() {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final filtered = widget.destinations
        .where((d) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return d.label.toLowerCase().contains(q);
        })
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.sectionPaddingH,
          tokens.spaceSm,
          tokens.sectionPaddingH,
          tokens.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.moreLabel,
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
            SizedBox(height: tokens.spaceSm),
            TextField(
              onChanged: _handleSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: context.l10n.searchDestinationsHint,
              ),
            ),
            SizedBox(height: tokens.spaceMd),
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
                        if (isActive) ...[
                          SizedBox(width: tokens.spaceSm),
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
