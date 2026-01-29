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

class _TextSizeSlider extends StatefulWidget {
  const _TextSizeSlider({required this.settings});

  final GlobalSettings settings;

  static const double _min = 0.85;
  static const double _max = 1.25;

  @override
  State<_TextSizeSlider> createState() => _TextSizeSliderState();
}

class _TextSizeSliderState extends State<_TextSizeSlider> {
  late double _draftScale = widget.settings.textScaleFactor.clamp(
    _TextSizeSlider._min,
    _TextSizeSlider._max,
  );

  @override
  void didUpdateWidget(covariant _TextSizeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.settings.textScaleFactor.clamp(
      _TextSizeSlider._min,
      _TextSizeSlider._max,
    );
    if (next != _draftScale) {
      _draftScale = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _draftScale;
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
                '${(scale * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          Slider(
            value: scale,
            min: _TextSizeSlider._min,
            max: _TextSizeSlider._max,
            divisions: 8,
            label: '${(scale * 100).round()}%',
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
