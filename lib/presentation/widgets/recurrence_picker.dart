import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rrule/rrule.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// A user-friendly widget for configuring recurring dates using RRULE format.
///
/// This widget provides an intuitive UI for creating iCalendar RRULE strings
/// for defining recurring patterns (daily, weekly, monthly, yearly).
class RecurrencePicker extends StatefulWidget {
  const RecurrencePicker({
    required this.initialRRule,
    required this.initialRepeatFromCompletion,
    required this.initialSeriesEnded,
    super.key,
  });

  final String? initialRRule;
  final bool initialRepeatFromCompletion;
  final bool initialSeriesEnded;

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  RecurrenceFrequency _frequency = RecurrenceFrequency.none;
  int _interval = 1;
  int? _count;
  DateTime? _until;
  final Set<int> _byWeekDay = {};
  late TextEditingController _intervalController;
  RruleL10n? _rruleL10n;

  late bool _repeatFromCompletion;
  late bool _seriesEnded;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(text: _interval.toString());
    _parseRRule(widget.initialRRule);

    _repeatFromCompletion = widget.initialRepeatFromCompletion;
    _seriesEnded = widget.initialSeriesEnded;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_initializeL10n());
  }

  Future<void> _initializeL10n() async {
    final locale = Localizations.localeOf(context);
    final next = locale.languageCode == 'es'
        ? await RruleL10nEs.create()
        : await RruleL10nEn.create();
    if (!mounted) return;
    setState(() {
      _rruleL10n = next;
    });
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  void _parseRRule(String? rruleString) {
    if (rruleString == null || rruleString.isEmpty) {
      _frequency = RecurrenceFrequency.none;
      return;
    }

    try {
      final recurrenceRule = RecurrenceRule.fromString(rruleString);

      // Parse frequency
      _frequency = switch (recurrenceRule.frequency) {
        Frequency.daily => RecurrenceFrequency.daily,
        Frequency.weekly => RecurrenceFrequency.weekly,
        Frequency.monthly => RecurrenceFrequency.monthly,
        Frequency.yearly => RecurrenceFrequency.yearly,
        _ => RecurrenceFrequency.none,
      };

      // Parse interval
      _interval = recurrenceRule.interval ?? 1;
      _intervalController.text = _interval.toString();

      // Parse count
      _count = recurrenceRule.count;

      // Parse until date
      _until = recurrenceRule.until;

      // Parse weekdays for weekly recurrence
      if (recurrenceRule.byWeekDays.isNotEmpty) {
        _byWeekDay.clear();
        for (final byWeekDay in recurrenceRule.byWeekDays) {
          _byWeekDay.add(byWeekDay.day);
        }
      }
    } catch (e) {
      // If parsing fails, reset to none
      talker.debug('RecurrencePicker: Failed to parse RRULE "$rruleString"');
      _frequency = RecurrenceFrequency.none;
    }
  }

  String? _buildRRule() {
    if (_frequency == RecurrenceFrequency.none) {
      return null;
    }

    final frequency = switch (_frequency) {
      RecurrenceFrequency.daily => Frequency.daily,
      RecurrenceFrequency.weekly => Frequency.weekly,
      RecurrenceFrequency.monthly => Frequency.monthly,
      RecurrenceFrequency.yearly => Frequency.yearly,
      RecurrenceFrequency.none => throw StateError('Invalid frequency'),
    };

    final byWeekDays =
        _frequency == RecurrenceFrequency.weekly && !_repeatFromCompletion
        ? _byWeekDay.map(ByWeekDayEntry.new).toList()
        : const <ByWeekDayEntry>[];

    final recurrenceRule = RecurrenceRule(
      frequency: frequency,
      interval: _interval,
      count: _count,
      until: _until,
      byWeekDays: byWeekDays,
    );

    return recurrenceRule.toString();
  }

  void _updateRRule() {
    // This widget no longer streams changes upward. Keeping this method allows
    // existing UI handlers to remain simple while still triggering rebuilds.
  }

  RecurrencePickerResult _currentResult() {
    if (_frequency == RecurrenceFrequency.none) {
      return const RecurrencePickerResult(
        rrule: null,
        repeatFromCompletion: false,
        seriesEnded: false,
      );
    }
    return RecurrencePickerResult(
      rrule: _buildRRule(),
      repeatFromCompletion: _repeatFromCompletion,
      seriesEnded: _seriesEnded,
    );
  }

  String _getHumanReadableText(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (_frequency == RecurrenceFrequency.none) {
      return l10n.recurrenceDoesNotRepeat;
    }

    // Try to use rrule's toText() method if l10n is initialized
    if (_rruleL10n != null) {
      try {
        final rruleString = _buildRRule();
        if (rruleString == null) return l10n.recurrenceDoesNotRepeat;

        final recurrenceRule = RecurrenceRule.fromString(rruleString);
        return recurrenceRule.toText(l10n: _rruleL10n!);
      } catch (e) {
        // Fall through to manual text generation
        talker.debug(
          'RecurrencePicker: Failed to generate human-readable text',
        );
      }
    }

    // Fallback: Build human-readable text manually
    var text = l10n.recurrenceEvery;
    if (_interval > 1) {
      text += ' $_interval';
    }
    text += ' ${_frequencyUnitLabel(l10n, _frequency, _interval)}';

    if (_frequency == RecurrenceFrequency.weekly && _byWeekDay.isNotEmpty) {
      final dayNames = _byWeekDay.map(_dayLabel).join(', ');
      text += ' ${l10n.recurrenceOn} $dayNames';
    }

    if (_count != null) {
      text += ', ${_count!} ${l10n.recurrenceTimesLabel}';
    } else if (_until != null) {
      final formattedDate = MaterialLocalizations.of(context).formatMediumDate(
        _until!,
      );
      text += ', ${l10n.recurrenceUntilDate(formattedDate)}';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final now = context.read<NowService>().nowLocal();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final tokens = TasklyTokens.of(context);

    return TasklyFormSheet(
      title: l10n.recurrenceTitle,
      preset: TasklyFormPreset.standard(TasklyTokens.of(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frequency selector
          SegmentedButton<RecurrenceFrequency>(
            segments: [
              ButtonSegment(
                value: RecurrenceFrequency.none,
                label: Text(l10n.recurrenceNever),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.daily,
                label: Text(l10n.recurrenceDaily),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.weekly,
                label: Text(l10n.recurrenceWeekly),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.monthly,
                label: Text(l10n.recurrenceMonthly),
              ),
            ],
            selected: {_frequency},
            onSelectionChanged: (selected) {
              setState(() {
                _frequency = selected.first;
                if (_frequency == RecurrenceFrequency.none) {
                  _repeatFromCompletion = false;
                  _seriesEnded = false;
                }
              });
            },
            showSelectedIcon: false,
          ),

          if (_frequency != RecurrenceFrequency.none) ...[
            SizedBox(height: tokens.spaceXl),
            Text(
              l10n.recurrenceRepeatModeLabel,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spaceSm),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.recurrenceRepeatModeScheduled),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.recurrenceRepeatModeFromCompletion),
                ),
              ],
              selected: {_repeatFromCompletion},
              onSelectionChanged: (selected) {
                setState(() {
                  _repeatFromCompletion = selected.first;
                  if (_repeatFromCompletion) {
                    _byWeekDay.clear();
                  }
                });
              },
              showSelectedIcon: false,
            ),
            SizedBox(height: tokens.spaceMd),

            // Interval
            Row(
              children: [
                Text(
                  l10n.recurrenceEvery,
                  style: theme.textTheme.titleMedium,
                ),
                SizedBox(width: tokens.spaceLg),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceMd,
                        vertical: tokens.spaceSm,
                      ),
                    ),
                    onChanged: (value) {
                      final interval = int.tryParse(value);
                      if (interval != null && interval > 0 && interval <= 999) {
                        setState(() {
                          _interval = interval;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.validationRequired;
                      }
                      final interval = int.tryParse(value);
                      if (interval == null) {
                        return l10n.validationInvalid;
                      }
                      if (interval <= 0) {
                        return l10n.validationMustBeGreaterThanZero;
                      }
                      if (interval > 999) {
                        return l10n.validationMaxValue(999);
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: tokens.spaceMd),
                Expanded(
                  child: Text(
                    _frequencyUnitLabel(l10n, _frequency, _interval),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            // Weekly: Day selector
            if (_frequency == RecurrenceFrequency.weekly &&
                !_repeatFromCompletion) ...[
              SizedBox(height: tokens.spaceLg),
              Text(
                l10n.recurrenceOnDays,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: tokens.spaceMd),
              Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceSm,
                children: [
                  for (final day in [
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.wednesday,
                    DateTime.thursday,
                    DateTime.friday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ])
                    FilterChip(
                      label: Text(_dayLabel(day)),
                      selected: _byWeekDay.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _byWeekDay.add(day);
                          } else {
                            _byWeekDay.remove(day);
                          }
                          _updateRRule();
                        });
                      },
                      showCheckmark: false,
                    ),
                ],
              ),
            ],

            SizedBox(height: tokens.spaceXl),
            const Divider(),
            SizedBox(height: tokens.spaceLg),

            // End condition
            Text(
              l10n.recurrenceEnds,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spaceMd),

            RadioListTile<EndCondition>(
              title: Text(l10n.recurrenceNever),
              value: EndCondition.never,
              groupValue: _count != null
                  ? EndCondition.after
                  : (_until != null ? EndCondition.on : EndCondition.never),
              onChanged: (value) {
                setState(() {
                  _count = null;
                  _until = null;
                  _updateRRule();
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            RadioListTile<EndCondition>(
              title: Row(
                children: [
                  Text(l10n.recurrenceAfter),
                  SizedBox(width: tokens.spaceLg),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _count?.toString() ?? '10',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        suffix: Text(l10n.recurrenceTimesLabel),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceMd,
                          vertical: tokens.spaceSm,
                        ),
                      ),
                      onChanged: (value) {
                        final count = int.tryParse(value);
                        if (count != null && count > 0 && count <= 9999) {
                          setState(() {
                            _count = count;
                            _until = null;
                            _updateRRule();
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.validationRequired;
                        }
                        final count = int.tryParse(value);
                        if (count == null) {
                          return l10n.validationInvalid;
                        }
                        if (count <= 0) {
                          return l10n.validationMustBeGreaterThanZero;
                        }
                        if (count > 9999) {
                          return l10n.validationMaxValue(9999);
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              value: EndCondition.after,
              groupValue: _count != null
                  ? EndCondition.after
                  : (_until != null ? EndCondition.on : EndCondition.never),
              onChanged: (value) {
                setState(() {
                  _count = 10;
                  _until = null;
                  _updateRRule();
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            RadioListTile<EndCondition>(
              title: Row(
                children: [
                  Text(l10n.recurrenceOn),
                  SizedBox(width: tokens.spaceLg),
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _until ?? now.add(const Duration(days: 30)),
                        firstDate: now,
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _until = date;
                          _count = null;
                          _updateRRule();
                        });
                      }
                    },
                    icon: Icon(Icons.calendar_today, size: tokens.spaceLg),
                    label: Text(
                      _until != null
                          ? MaterialLocalizations.of(context).formatMediumDate(
                              _until!,
                            )
                          : l10n.recurrenceSelectDate,
                    ),
                  ),
                ],
              ),
              value: EndCondition.on,
              groupValue: _count != null
                  ? EndCondition.after
                  : (_until != null ? EndCondition.on : EndCondition.never),
              onChanged: (value) async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 30)),
                  firstDate: now,
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _until = date;
                    _count = null;
                    _updateRRule();
                  });
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],

          SizedBox(height: tokens.spaceXl),

          if (_frequency != RecurrenceFrequency.none) ...[
            SwitchListTile.adaptive(
              value: _seriesEnded,
              onChanged: (v) => setState(() => _seriesEnded = v),
              title: Text(l10n.recurrenceSeriesEndedLabel),
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: tokens.spaceXl),
          ],

          // Summary
          if (_frequency != RecurrenceFrequency.none)
            Container(
              padding: EdgeInsets.all(tokens.spaceLg),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    color: colorScheme.primary,
                    size: tokens.spaceLg3,
                  ),
                  SizedBox(width: tokens.spaceMd),
                  Expanded(
                    child: Text(
                      _getSummary(context, l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: tokens.spaceXl),

          // Action buttons
          TasklyFormActionRow(
            cancelLabel: l10n.cancelLabel,
            confirmLabel: l10n.doneLabel,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () => Navigator.of(context).pop(_currentResult()),
          ),
        ],
      ),
    );
  }

  String _dayLabel(int weekday) {
    return MaterialLocalizations.of(context).narrowWeekdays[weekday % 7];
  }

  String _getSummary(BuildContext context, AppLocalizations l10n) {
    return _getHumanReadableText(context, l10n);
  }

  String _frequencyUnitLabel(
    AppLocalizations l10n,
    RecurrenceFrequency frequency,
    int interval,
  ) {
    return switch (frequency) {
      RecurrenceFrequency.none => '',
      RecurrenceFrequency.daily => l10n.recurrenceDayUnit(interval),
      RecurrenceFrequency.weekly => l10n.recurrenceWeekUnit(interval),
      RecurrenceFrequency.monthly => l10n.recurrenceMonthUnit(interval),
      RecurrenceFrequency.yearly => l10n.recurrenceYearUnit(interval),
    };
  }
}

enum RecurrenceFrequency { none, daily, weekly, monthly, yearly }

enum EndCondition {
  never,
  after,
  on,
}

@immutable
class RecurrencePickerResult {
  const RecurrencePickerResult({
    required this.rrule,
    required this.repeatFromCompletion,
    required this.seriesEnded,
  });

  final String? rrule;
  final bool repeatFromCompletion;
  final bool seriesEnded;
}
