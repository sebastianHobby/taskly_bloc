import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/theme/app_seed_palettes.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Settings control that lets users pick an accent seed color from a curated
/// set, with a live preview.
class AccentPaletteGallery extends StatelessWidget {
  const AccentPaletteGallery({
    required this.title,
    required this.subtitle,
    required this.palettes,
    required this.selectedSeedArgb,
    required this.onSelected,
    this.padding,
    this.showHeader = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<ThemePaletteOption> palettes;
  final int selectedSeedArgb;
  final ValueChanged<ThemePaletteOption> onSelected;
  final EdgeInsetsGeometry? padding;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final selected = palettes.cast<ThemePaletteOption?>().firstWhere(
      (p) => p?.seedArgb == selectedSeedArgb,
      orElse: () => null,
    );

    final selectedScheme = (selected ?? palettes.first).schemeFor(brightness);

    final resolvedPadding =
        padding ??
        EdgeInsets.fromLTRB(
          TasklyTokens.of(context).spaceLg,
          TasklyTokens.of(context).spaceSm,
          TasklyTokens.of(context).spaceLg,
          0,
        );

    return Padding(
      padding: resolvedPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
          ],
          _PalettePreviewCard(colorScheme: selectedScheme),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 520 ? 3 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  for (final palette in palettes)
                    _PaletteCard(
                      palette: palette,
                      brightness: brightness,
                      isSelected: palette.seedArgb == selectedSeedArgb,
                      onTap: () => onSelected(palette),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PalettePreviewCard extends StatelessWidget {
  const _PalettePreviewCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final previewTheme = Theme.of(context).copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surface,
    );

    return Theme(
      data: previewTheme,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        TasklyTokens.of(context).radiusMd,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Expanded(
                    child: Text(
                      context.l10n.previewLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: null,
                    child: Text(context.l10n.actionLabel),
                  ),
                ],
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: TasklyTokens.of(context).spaceLg,
                  ),
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.bolt,
                      size: 14,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(context.l10n.listItemLabel),
                  subtitle: Text(context.l10n.supportingTextLabel),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(context.l10n.chipLabel),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  Chip(
                    label: Text(context.l10n.primaryLabel),
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.brightness,
    required this.isSelected,
    required this.onTap,
  });

  final ThemePaletteOption palette;
  final Brightness brightness;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = palette.schemeFor(brightness);
    final outline = Theme.of(context).colorScheme.outlineVariant;

    final borderColor = isSelected ? scheme.primary : outline;
    final borderWidth = isSelected ? 2.0 : 1.0;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              TasklyTokens.of(context).radiusMd,
            ),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Padding(
            padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        palette.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: scheme.primary,
                        size: 18,
                      ),
                  ],
                ),
                const Spacer(),
                _SwatchesRow(
                  swatches: [
                    scheme.primary,
                    scheme.secondary,
                    scheme.tertiary,
                    scheme.primaryContainer,
                    scheme.surfaceContainerHighest,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchesRow extends StatelessWidget {
  const _SwatchesRow({required this.swatches});

  final List<Color> swatches;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final color in swatches)
          Padding(
            padding: EdgeInsets.only(bottom: TasklyTokens.of(context).spaceSm),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
