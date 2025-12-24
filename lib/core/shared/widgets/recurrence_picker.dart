import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rrule/rrule.dart';

import 'dart:async';

/// A user-friendly widget for configuring recurring dates using RRULE format.
///
/// This widget provides an intuitive UI for creating iCalendar RRULE strings
/// for defining recurring patterns (daily, weekly, monthly, yearly).
class RecurrencePicker extends StatefulWidget {
  const RecurrencePicker({
    required this.initialRRule,
    required this.onRRuleChanged,
    super.key,
  });

  final String? initialRRule;
  final ValueChanged<String?> onRRuleChanged;

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

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(text: _interval.toString());
    unawaited(_initializeL10n());
    _parseRRule(widget.initialRRule);
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

  void _updateRRule() {
    widget.onRRuleChanged(_buildRRule());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Repeat',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

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
                _updateRRule();
              });
            },
            showSelectedIcon: false,
          ),

          if (_frequency != RecurrenceFrequency.none) ...[
            const SizedBox(height: 24),

            // Interval
            Row(
              children: [
                Text(
                  'Every',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      final interval = int.tryParse(value);
                      if (interval != null && interval > 0 && interval <= 999) {
                        setState(() {
                          _interval = interval;
                          _updateRRule();
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
                const SizedBox(width: 12),
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
              const SizedBox(height: 16),
              Text(
                'On days',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // End condition
            Text(
              'Ends',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

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
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _count?.toString() ?? '10',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        suffix: Text('times'),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _until ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
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
                    icon: const Icon(Icons.calendar_today, size: 16),
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
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
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

          const SizedBox(height: 24),

          // Summary
          if (_frequency != RecurrenceFrequency.none)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
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

          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
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
