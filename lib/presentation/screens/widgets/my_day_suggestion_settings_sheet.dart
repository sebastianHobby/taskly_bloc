import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';

void openSuggestionSettingsSheet(
  BuildContext context, {
  required int dueWindowDays,
  required bool showAvailableToStart,
}) {
  var dueDays = dueWindowDays.clamp(1, 30);
  var showStarts = showAvailableToStart;
  final bloc = context.read<MyDayRitualBloc>();

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final cs = theme.colorScheme;

      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            final l10n = context.l10n;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myDaySuggestionSettingsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.myDaySuggestionSettingsBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.myDayDueSoonWindowLabel(dueDays),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: dueDays.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$dueDays',
                    onChanged: (value) {
                      final next = value.round().clamp(1, 30);
                      setState(() => dueDays = next);
                      bloc.add(MyDayRitualDueWindowDaysChanged(next));
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.myDayDueSoonWindowHelp(dueDays),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.myDayShowAvailableToStartSettingTitle),
                    subtitle: Text(
                      l10n.myDayShowAvailableToStartSettingSubtitle,
                    ),
                    value: showStarts,
                    onChanged: (value) {
                      setState(() => showStarts = value);
                      bloc.add(MyDayRitualShowAvailableToStartChanged(value));
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
