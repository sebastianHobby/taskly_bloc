import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/app_seed_palettes.dart';

/// Settings control that lets users pick an accent seed color from a curated
/// set, with a live preview.
class AccentPaletteGallery extends StatelessWidget {
  const AccentPaletteGallery({
    required this.title,
    required this.subtitle,
    required this.palettes,
    required this.selectedSeedArgb,
    required this.onSelected,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<ThemePaletteOption> palettes;
  final int selectedSeedArgb;
  final ValueChanged<ThemePaletteOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final selected = palettes.cast<ThemePaletteOption?>().firstWhere(
      (p) => p?.seedArgb == selectedSeedArgb,
      orElse: () => null,
    );

    final selectedScheme = (selected ?? palettes.first).schemeFor(brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _PalettePreviewCard(colorScheme: selectedScheme),
          const SizedBox(height: 12),
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
          padding: const EdgeInsets.all(12),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: null,
                    child: const Text('Action'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.bolt,
                      size: 14,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: const Text('List item'),
                  subtitle: const Text('Supporting text'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: const Text('Chip'),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  Chip(
                    label: const Text('Primary'),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
            padding: const EdgeInsets.only(right: 8),
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
