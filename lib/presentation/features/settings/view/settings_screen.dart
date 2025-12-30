import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/presentation/widgets/color_picker/color_picker_field.dart';

/// Settings screen for global app configuration.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepositoryContract _settingsRepo =
      getIt<SettingsRepositoryContract>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: StreamBuilder<GlobalSettings>(
        stream: _settingsRepo.watchGlobalSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          return ListView(
            children: [
              _buildSection(
                title: 'Appearance',
                children: [
                  _buildThemeModeSelector(settings),
                  _buildColorPicker(settings),
                  _buildTextSizeSlider(settings),
                ],
              ),
              _buildSection(
                title: 'Language & Region',
                children: [
                  _buildLanguageSelector(settings),
                  _buildDateFormatSelector(settings),
                ],
              ),
              _buildSection(
                title: 'Advanced',
                children: [
                  _buildResetButton(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildThemeModeSelector(GlobalSettings settings) {
    return ListTile(
      title: const Text('Theme Mode'),
      subtitle: const Text('Choose between light, dark, or system theme'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode, size: 16),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 16),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto, size: 16),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (Set<ThemeMode> newSelection) async {
          final updated = settings.copyWith(themeMode: newSelection.first);
          await _settingsRepo.saveGlobalSettings(updated);
        },
      ),
    );
  }

  Widget _buildColorPicker(GlobalSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ColorPickerField(
        color: settings.colorSchemeSeed,
        onColorChanged: (color) async {
          final updated = settings.copyWith(colorSchemeSeed: color);
          await _settingsRepo.saveGlobalSettings(updated);
        },
        label: 'Theme Color',
        showMaterialName: true,
      ),
    );
  }

  Widget _buildTextSizeSlider(GlobalSettings settings) {
    return ListTile(
      title: const Text('Text Size'),
      subtitle: Slider(
        value: settings.textScaleFactor,
        min: 0.8,
        max: 1.4,
        divisions: 6,
        label: '${(settings.textScaleFactor * 100).round()}%',
        onChanged: (value) async {
          final updated = settings.copyWith(textScaleFactor: value);
          await _settingsRepo.saveGlobalSettings(updated);
        },
      ),
      trailing: Text(
        '${(settings.textScaleFactor * 100).round()}%',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildLanguageSelector(GlobalSettings settings) {
    return ListTile(
      title: const Text('Language'),
      subtitle: const Text('Select your preferred language'),
      trailing: DropdownButton<Locale?>(
        value: settings.locale,
        items: const [
          DropdownMenuItem(
            child: Text('System'),
          ),
          DropdownMenuItem(
            value: Locale('en'),
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: Locale('es'),
            child: Text('Español'),
          ),
        ],
        onChanged: (locale) async {
          final updated = settings.copyWith(locale: locale);
          await _settingsRepo.saveGlobalSettings(updated);
        },
      ),
    );
  }

  Widget _buildDateFormatSelector(GlobalSettings settings) {
    final patterns = [
      DateFormatPatterns.short,
      DateFormatPatterns.medium,
      DateFormatPatterns.long,
      DateFormatPatterns.full,
    ];

    return ListTile(
      title: const Text('Date Format'),
      subtitle: Text(_getDateFormatExample(settings.dateFormatPattern)),
      trailing: DropdownButton<String>(
        value: settings.dateFormatPattern,
        items: patterns.map((pattern) {
          return DropdownMenuItem(
            value: pattern,
            child: Text(_getDateFormatLabel(pattern)),
          );
        }).toList(),
        onChanged: (pattern) async {
          if (pattern != null) {
            final updated = settings.copyWith(dateFormatPattern: pattern);
            await _settingsRepo.saveGlobalSettings(updated);
          }
        },
      ),
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: _showResetConfirmation,
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await _settingsRepo.saveGlobalSettings(const GlobalSettings());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }

  String _getDateFormatLabel(String pattern) {
    switch (pattern) {
      case DateFormatPatterns.short:
        return 'Short';
      case DateFormatPatterns.medium:
        return 'Medium';
      case DateFormatPatterns.long:
        return 'Long';
      case DateFormatPatterns.full:
        return 'Full';
      default:
        return 'Custom';
    }
  }

  String _getDateFormatExample(String pattern) {
    final now = DateTime(2025, 12, 30);
    final formatter = DateFormatPatterns.getFormat(pattern);
    return 'Example: ${formatter.format(now)}';
  }
}
