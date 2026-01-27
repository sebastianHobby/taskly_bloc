import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rrule/rrule.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
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
  RruleL10nEn? _l10n;

  late bool _repeatFromCompletion;
  late bool _seriesEnded;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(text: _interval.toString());
    unawaited(_initializeL10n());
    _parseRRule(widget.initialRRule);

    _repeatFromCompletion = widget.initialRepeatFromCompletion;
    _seriesEnded = widget.initialSeriesEnded;
  }

  Future<void> _initializeL10n() async {
    _l10n = await RruleL10nEn.create();
    if (mounted) {
      setState(() {});
    }
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

    final recurrenceRule = RecurrenceRule(
      frequency: frequency,
      interval: _interval,
      count: _count,
      until: _until,
      byWeekDays: _byWeekDay.isNotEmpty
          ? _byWeekDay.map(ByWeekDayEntry.new).toList()
          : const [],
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

  String _getHumanReadableText() {
    if (_frequency == RecurrenceFrequency.none) {
      return 'Does not repeat';
    }

    // Try to use rrule's toText() method if l10n is initialized
    if (_l10n != null) {
      try {
        final rruleString = _buildRRule();
        if (rruleString == null) return 'Does not repeat';

        final recurrenceRule = RecurrenceRule.fromString(rruleString);
        return recurrenceRule.toText(l10n: _l10n!);
      } catch (e) {
        // Fall through to manual text generation
        talker.debug(
          'RecurrencePicker: Failed to generate human-readable text',
        );
      }
    }

    // Fallback: Build human-readable text manually
    var text = 'Every';
    if (_interval > 1) {
      text += ' $_interval';
    }
    text += ' ${_frequency.label}';
    if (_interval > 1) {
      text += 's';
    }

    if (_frequency == RecurrenceFrequency.weekly && _byWeekDay.isNotEmpty) {
      final dayNames = _byWeekDay.map(_dayLabel).join(', ');
      text += ' on $dayNames';
    }

    if (_count != null) {
      text += ', $_count times';
    } else if (_until != null) {
      text +=
          ', until ${_until!.year}-${_until!.month.toString().padLeft(2, '0')}-${_until!.day.toString().padLeft(2, '0')}';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final now = getIt<NowService>().nowLocal();
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
            segments: const [
              ButtonSegment(
                value: RecurrenceFrequency.none,
                label: Text('Never'),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.daily,
                label: Text('Daily'),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.weekly,
                label: Text('Weekly'),
              ),
              ButtonSegment(
                value: RecurrenceFrequency.monthly,
                label: Text('Monthly'),
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

            // Interval
            Row(
              children: [
                Text(
                  'Every',
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
                        return 'Required';
                      }
                      final interval = int.tryParse(value);
                      if (interval == null) {
                        return 'Invalid';
                      }
                      if (interval <= 0) {
                        return 'Must be > 0';
                      }
                      if (interval > 999) {
                        return 'Max 999';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: tokens.spaceMd),
                Expanded(
                  child: Text(
                    '${_frequency.label}${_interval > 1 ? 's' : ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            // Weekly: Day selector
            if (_frequency == RecurrenceFrequency.weekly) ...[
              SizedBox(height: tokens.spaceLg),
              Text(
                'On days',
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
              'Ends',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spaceMd),

            RadioListTile<EndCondition>(
              title: const Text('Never'),
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
                  const Text('After'),
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
                        suffix: Text('times'),
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
                          return 'Required';
                        }
                        final count = int.tryParse(value);
                        if (count == null) {
                          return 'Invalid';
                        }
                        if (count <= 0) {
                          return '> 0';
                        }
                        if (count > 9999) {
                          return 'Max 9999';
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
                  const Text('On'),
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
                          ? '${_until!.day}/${_until!.month}/${_until!.year}'
                          : 'Select date',
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
              value: _repeatFromCompletion,
              onChanged: (v) => setState(() => _repeatFromCompletion = v),
              title: Text(l10n.recurrenceRepeatFromCompletionLabel),
              contentPadding: EdgeInsets.zero,
            ),
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
                      _getSummary(),
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
    const labels = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return labels[weekday]!;
  }

  String _getSummary() {
    return _getHumanReadableText();
  }
}

enum RecurrenceFrequency {
  none('Never'),
  daily('day'),
  weekly('week'),
  monthly('month'),
  yearly('year');

  const RecurrenceFrequency(this.label);
  final String label;
}

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
