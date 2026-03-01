import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/journal.dart';

enum JournalTrackerValueState { normal, warn, goalHit }

final class JournalTrackerFormattedValue {
  const JournalTrackerFormattedValue({
    required this.text,
    required this.valueText,
    required this.hasValue,
    required this.state,
  });

  final String text;
  final String valueText;
  final bool hasValue;
  final JournalTrackerValueState state;
}

final class JournalTrackerValueFormatter {
  const JournalTrackerValueFormatter._();

  static JournalTrackerFormattedValue format({
    required AppLocalizations l10n,
    required String label,
    required TrackerDefinition? definition,
    required Object? rawValue,
    required Map<String, Map<String, String>> choiceLabelsByTrackerId,
  }) {
    final hasValue = _hasValue(rawValue);
    final valueText = hasValue
        ? _formatValueText(
            l10n: l10n,
            definition: definition,
            rawValue: rawValue,
            choiceLabelsByTrackerId: choiceLabelsByTrackerId,
          )
        : l10n.journalNotSetLabel;
    final state = _resolveState(
      definition: definition,
      rawValue: rawValue,
      hasValue: hasValue,
    );
    return JournalTrackerFormattedValue(
      text: '$label: $valueText',
      valueText: valueText,
      hasValue: hasValue,
      state: state,
    );
  }

  static bool _hasValue(Object? rawValue) {
    return switch (rawValue) {
      null => false,
      final String v => v.trim().isNotEmpty,
      _ => true,
    };
  }

  static String _formatValueText({
    required AppLocalizations l10n,
    required TrackerDefinition? definition,
    required Object? rawValue,
    required Map<String, Map<String, String>> choiceLabelsByTrackerId,
  }) {
    if (rawValue == null) return l10n.journalNotSetLabel;
    if (rawValue is bool) return rawValue ? l10n.yesLabel : l10n.noLabel;

    final valueType = (definition?.valueType ?? '').trim().toLowerCase();
    if ((valueType == 'choice' || valueType == 'single_choice') &&
        rawValue is String) {
      final key = rawValue.trim();
      final trackerId = definition?.id;
      if (trackerId != null && key.isNotEmpty) {
        return choiceLabelsByTrackerId[trackerId]?[key] ?? key;
      }
      return key;
    }

    final number = _toDouble(rawValue);
    if (number != null) {
      final unit = (definition?.unitKind ?? '').trim();
      final numeric = _formatNumber(number);
      return unit.isEmpty ? numeric : '$numeric $unit';
    }

    final value = '$rawValue'.trim();
    return value.isEmpty ? l10n.journalNotSetLabel : value;
  }

  static JournalTrackerValueState _resolveState({
    required TrackerDefinition? definition,
    required Object? rawValue,
    required bool hasValue,
  }) {
    if (!hasValue) return JournalTrackerValueState.warn;
    final targetRaw = definition?.goal['target'];
    final target = _toDouble(targetRaw);
    final current = _toDouble(rawValue);
    if (target != null && target > 0 && current != null && current >= target) {
      return JournalTrackerValueState.goalHit;
    }
    return JournalTrackerValueState.normal;
  }

  static double? _toDouble(Object? value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return null;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}
