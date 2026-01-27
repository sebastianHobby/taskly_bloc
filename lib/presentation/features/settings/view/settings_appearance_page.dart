import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/widgets/accent_palette_gallery.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/theme/app_seed_palettes.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsAppearancePage extends StatelessWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
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
                _ThemeModeSelector(settings: settings),
                _AccentPalettePicker(settings: settings),
                _TextSizeSlider(settings: settings),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Theme'),
      subtitle: const Text('Light, dark, or system'),
      trailing: DropdownButton<AppThemeMode>(
        value: settings.themeMode,
        items: const [
          DropdownMenuItem(
            value: AppThemeMode.system,
            child: Text('System'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.light,
            child: Text('Light'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.dark,
            child: Text('Dark'),
          ),
        ],
        onChanged: (themeMode) {
          if (themeMode == null) return;
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.themeModeChanged(themeMode),
          );
        },
      ),
    );
  }
}

class _AccentPalettePicker extends StatelessWidget {
  const _AccentPalettePicker({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return AccentPaletteGallery(
      title: 'Accent palette',
      subtitle: 'Pick a focused productivity theme',
      palettes: AppSeedPalettes.focusedProductivity,
      selectedSeedArgb: settings.colorSchemeSeedArgb,
      onSelected: (palette) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.colorChanged(palette.seedArgb),
        );
      },
    );
  }
}

class _TextSizeSlider extends StatelessWidget {
  const _TextSizeSlider({required this.settings});

  final GlobalSettings settings;

  static const double _min = 0.85;
  static const double _max = 1.25;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceSm,
        TasklyTokens.of(context).spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Text size',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${(settings.textScaleFactor * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          Slider(
            value: settings.textScaleFactor.clamp(_min, _max),
            min: _min,
            max: _max,
            divisions: 8,
            label: '${(settings.textScaleFactor * 100).round()}%',
            onChanged: (value) {
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
