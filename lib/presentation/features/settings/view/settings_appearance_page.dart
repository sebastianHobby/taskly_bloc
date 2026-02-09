import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/widgets/accent_palette_gallery.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/theme/app_seed_palettes.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsAppearancePage extends StatelessWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appearanceTitle),
      ),
      body: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = state.settings;

          return ResponsiveBody(
            isExpandedLayout: context.isExpandedScreen,
            child: ListView(
              children: [
                _SettingsSectionPadding(
                  child: _ThemeModeCard(settings: settings),
                ),
                _SettingsSectionPadding(
                  child: _TextSizeCard(settings: settings),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeModeCard extends StatefulWidget {
  const _ThemeModeCard({required this.settings});

  final GlobalSettings settings;

  @override
  State<_ThemeModeCard> createState() => _ThemeModeCardState();
}

class _ThemeModeCardState extends State<_ThemeModeCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final label = _themeModeLabel(context.l10n, settings.themeMode);
    final tokens = TasklyTokens.of(context);

    return TasklySettingsCard(
      title: context.l10n.themeTitle,
      subtitle: context.l10n.themeSubtitle,
      summary: label,
      isExpanded: _isExpanded,
      onExpandedChanged: (next) => setState(() => _isExpanded = next),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.themeModeLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              DropdownButton<AppThemeMode>(
                value: settings.themeMode,
                items: [
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text(context.l10n.themeModeSystem),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text(context.l10n.themeModeLight),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text(context.l10n.themeModeDark),
                  ),
                ],
                onChanged: (themeMode) {
                  if (themeMode == null) return;
                  context.read<GlobalSettingsBloc>().add(
                    GlobalSettingsEvent.themeModeChanged(themeMode),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          Text(
            context.l10n.accentPaletteSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          AccentPaletteGallery(
            title: context.l10n.accentPaletteTitle,
            subtitle: context.l10n.accentPaletteSubtitle,
            palettes: AppSeedPalettes.focusedProductivity,
            selectedSeedArgb: settings.colorSchemeSeedArgb,
            onSelected: (palette) {
              context.read<GlobalSettingsBloc>().add(
                GlobalSettingsEvent.colorChanged(palette.seedArgb),
              );
            },
            padding: EdgeInsets.zero,
            showHeader: false,
          ),
        ],
      ),
    );
  }
}

class _TextSizeCard extends StatefulWidget {
  const _TextSizeCard({required this.settings});

  final GlobalSettings settings;

  static const double _min = 0.85;
  static const double _max = 1.25;

  @override
  State<_TextSizeCard> createState() => _TextSizeCardState();
}

class _TextSizeCardState extends State<_TextSizeCard> {
  late double _draftScale = widget.settings.textScaleFactor.clamp(
    _TextSizeCard._min,
    _TextSizeCard._max,
  );
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant _TextSizeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.settings.textScaleFactor.clamp(
      _TextSizeCard._min,
      _TextSizeCard._max,
    );
    if (next != _draftScale) {
      _draftScale = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _draftScale;
    final label = _textScaleLabel(scale);

    return TasklySettingsCard(
      title: context.l10n.textSizeTitle,
      subtitle: context.l10n.textSizeSubtitle,
      summary: label,
      isExpanded: _isExpanded,
      onExpandedChanged: (next) => setState(() => _isExpanded = next),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.textScaleLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          Slider(
            value: scale,
            min: _TextSizeCard._min,
            max: _TextSizeCard._max,
            divisions: 8,
            label: label,
            onChanged: (value) => setState(() {
              _draftScale = value;
            }),
            onChangeEnd: (value) {
              context.read<GlobalSettingsBloc>().add(
                GlobalSettingsEvent.textScaleChanged(value),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionPadding extends StatelessWidget {
  const _SettingsSectionPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        0,
      ),
      child: child,
    );
  }
}

String _themeModeLabel(AppLocalizations l10n, AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => l10n.themeModeSystem,
    AppThemeMode.light => l10n.themeModeLight,
    AppThemeMode.dark => l10n.themeModeDark,
  };
}

String _textScaleLabel(double scale) {
  return '${(scale * 100).round()}%';
}
