import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsLanguageRegionPage extends StatelessWidget {
  const SettingsLanguageRegionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language & Region'),
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
                _LanguageSelector(settings: settings),
                _HomeTimeZoneSelector(settings: settings),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Language'),
      subtitle: const Text('Select your preferred language'),
      trailing: DropdownButton<String?>(
        value: settings.localeCode,
        items: const [
          DropdownMenuItem(
            child: Text('System'),
          ),
          DropdownMenuItem(
            value: 'en',
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: 'es',
            child: Text('Español'),
          ),
        ],
        onChanged: (localeCode) {
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.localeChanged(localeCode),
          );
        },
      ),
    );
  }
}

class _HomeTimeZoneSelector extends StatelessWidget {
  const _HomeTimeZoneSelector({required this.settings});

  final GlobalSettings settings;

  static const int _minOffsetMinutes = -12 * 60;
  static const int _maxOffsetMinutes = 14 * 60;
  static const int _stepMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<int>>[];
    for (
      var offset = _minOffsetMinutes;
      offset <= _maxOffsetMinutes;
      offset += _stepMinutes
    ) {
      items.add(
        DropdownMenuItem<int>(
          value: offset,
          child: Text(_formatOffset(offset)),
        ),
      );
    }

    return ListTile(
      title: const Text('Home Timezone'),
      subtitle: const Text(
        'Fixed day boundary for "today" and My Day planning',
      ),
      trailing: DropdownButton<int>(
        value: settings.homeTimeZoneOffsetMinutes,
        items: items,
        onChanged: (offsetMinutes) {
          if (offsetMinutes == null) return;
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.homeTimeZoneOffsetChanged(offsetMinutes),
          );
        },
      ),
    );
  }

  String _formatOffset(int offsetMinutes) {
    final sign = offsetMinutes >= 0 ? '+' : '-';
    final abs = offsetMinutes.abs();
    final hours = abs ~/ 60;
    final minutes = abs % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return minutes == 0 ? 'GMT$sign$hh' : 'GMT$sign$hh:$mm';
  }
}
