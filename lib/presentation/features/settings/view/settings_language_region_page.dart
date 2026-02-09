import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsLanguageRegionPage extends StatelessWidget {
  const SettingsLanguageRegionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsLanguageRegionSection),
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
                  child: _LanguageCard(settings: settings),
                ),
                _SettingsSectionPadding(
                  child: _HomeTimeZoneCard(settings: settings),
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

class _LanguageCard extends StatefulWidget {
  const _LanguageCard({required this.settings});

  final GlobalSettings settings;

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final label = _languageLabel(context, settings.localeCode);

    return TasklySettingsCard(
      title: context.l10n.settingsLanguage,
      subtitle: context.l10n.settingsLanguageSubtitle,
      summary: label,
      isExpanded: _isExpanded,
      onExpandedChanged: (next) => setState(() => _isExpanded = next),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: settings.localeCode,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              child: Text(context.l10n.settingsLanguageSystem),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text(context.l10n.settingsLanguageEnglish),
            ),
            DropdownMenuItem(
              value: 'es',
              child: Text(context.l10n.settingsLanguageSpanish),
            ),
          ],
          onChanged: (localeCode) {
            context.read<GlobalSettingsBloc>().add(
              GlobalSettingsEvent.localeChanged(localeCode),
            );
          },
        ),
      ),
    );
  }
}

class _HomeTimeZoneCard extends StatefulWidget {
  const _HomeTimeZoneCard({required this.settings});

  final GlobalSettings settings;

  @override
  State<_HomeTimeZoneCard> createState() => _HomeTimeZoneCardState();
}

class _HomeTimeZoneCardState extends State<_HomeTimeZoneCard> {
  bool _isExpanded = false;

  static const int _minOffsetMinutes = -12 * 60;
  static const int _maxOffsetMinutes = 14 * 60;
  static const int _stepMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
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

    return TasklySettingsCard(
      title: context.l10n.settingsHomeTimeZone,
      subtitle: context.l10n.settingsHomeTimeZoneSubtitle,
      summary: _formatOffset(settings.homeTimeZoneOffsetMinutes),
      isExpanded: _isExpanded,
      onExpandedChanged: (next) => setState(() => _isExpanded = next),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: settings.homeTimeZoneOffsetMinutes,
          isExpanded: true,
          items: items,
          onChanged: (offsetMinutes) {
            if (offsetMinutes == null) return;
            context.read<GlobalSettingsBloc>().add(
              GlobalSettingsEvent.homeTimeZoneOffsetChanged(offsetMinutes),
            );
          },
        ),
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

String _languageLabel(BuildContext context, String? localeCode) {
  return switch (localeCode) {
    null => context.l10n.settingsLanguageSystem,
    'en' => context.l10n.settingsLanguageEnglish,
    'es' => context.l10n.settingsLanguageSpanish,
    _ => context.l10n.settingsLanguageSystem,
  };
}
