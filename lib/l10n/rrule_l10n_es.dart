import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:rrule/rrule.dart';

/// Spanish localization for RRule text generation.
///
/// Provides Spanish translations for all recurrence rule text formatting,
/// including frequencies, dates, ordinals, and list formatting.
@immutable
class RruleL10nEs extends RruleL10n {
  const RruleL10nEs._();

  /// Creates a Spanish localization instance.
  ///
  /// Initializes the Spanish locale for date formatting.
  static Future<RruleL10nEs> create() async {
    await initializeDateFormatting('es');
    return const RruleL10nEs._();
  }

  @override
  String get locale => 'es_ES';

  @override
  String frequencyInterval(Frequency frequency, int interval) {
    String plurals({
      required String one,
      required String singular,
      String? plural,
    }) {
      return switch (interval) {
        1 => one,
        2 => 'Cada 2 ${plural ?? '${singular}s'}',
        _ => 'Cada $interval ${plural ?? '${singular}s'}',
      };
    }

    return {
      Frequency.secondly: plurals(one: 'Cada segundo', singular: 'segundo'),
      Frequency.minutely: plurals(one: 'Cada minuto', singular: 'minuto'),
      Frequency.hourly: plurals(one: 'Cada hora', singular: 'hora'),
      Frequency.daily: plurals(
        one: 'Cada día',
        singular: 'día',
        plural: 'días',
      ),
      Frequency.weekly: plurals(one: 'Cada semana', singular: 'semana'),
      Frequency.monthly: plurals(
        one: 'Mensualmente',
        singular: 'mes',
        plural: 'meses',
      ),
      Frequency.yearly: plurals(
        one: 'Anualmente',
        singular: 'año',
        plural: 'años',
      ),
    }[frequency]!;
  }

  @override
  String until(DateTime until, Frequency frequency) {
    final untilString = formatWithIntl(
      () => DateFormat.yMMMMEEEEd().add_jms().format(until),
    );
    return ', hasta $untilString';
  }

  @override
  String count(int count) {
    return switch (count) {
      1 => ', una vez',
      2 => ', dos veces',
      _ => ', $count veces',
    };
  }

  @override
  String onInstances(String instances) => 'en la $instances instancia';

  @override
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple}) =>
      '${_inVariant(variant)} $months';

  @override
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple}) =>
      '${_inVariant(variant)} la $weeks semana del año';

  String _inVariant(InOnVariant variant) {
    return switch (variant) {
      InOnVariant.simple => 'en',
      InOnVariant.also => 'que también están en',
      InOnVariant.instanceOf => 'de',
    };
  }

  @override
  String onDaysOfWeek(
    String days, {
    bool indicateFrequency = false,
    DaysOfWeekFrequency? frequency = DaysOfWeekFrequency.monthly,
    InOnVariant variant = InOnVariant.simple,
  }) {
    assert(variant != InOnVariant.also, 'InOnVariant.also not supported');

    final frequencyString = frequency == DaysOfWeekFrequency.monthly
        ? 'mes'
        : 'año';
    final suffix = indicateFrequency ? ' del $frequencyString' : '';
    return '${_onVariant(variant)} $days$suffix';
  }

  @override
  String? get weekdaysString => 'días laborables';

  @override
  String get everyXDaysOfWeekPrefix => 'cada ';

  @override
  String nthDaysOfWeek(Iterable<int> occurrences, String daysOfWeek) {
    if (occurrences.isEmpty) return daysOfWeek;

    final ordinals = list(
      occurrences.map(ordinal).toList(),
      ListCombination.conjunctiveShort,
    );
    return 'el $ordinals $daysOfWeek';
  }

  @override
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    final suffix = {
      DaysOfVariant.simple: '',
      DaysOfVariant.day: ' día',
      DaysOfVariant.dayAndFrequency: ' día del mes',
    }[daysOfVariant];
    return '${_onVariant(variant)} el $days$suffix';
  }

  @override
  String onDaysOfYear(
    String days, {
    InOnVariant variant = InOnVariant.simple,
  }) => '${_onVariant(variant)} el $days día del año';

  String _onVariant(InOnVariant variant) {
    return switch (variant) {
      InOnVariant.simple => 'el',
      InOnVariant.also => 'que también son',
      InOnVariant.instanceOf => 'de',
    };
  }

  @override
  String list(List<String> items, ListCombination combination) {
    final (two, end) = switch (combination) {
      ListCombination.conjunctiveShort => (' y ', ' y '),
      ListCombination.conjunctiveLong => (' y ', ', y '),
      ListCombination.disjunctive => (' o ', ', o '),
    };
    return RruleL10n.defaultList(items, two: two, end: end);
  }

  @override
  String ordinal(int number) {
    assert(number != 0, 'Ordinal cannot be zero');
    if (number == -1) return 'último';

    final n = number.abs();
    final string = '$nº';

    return number < 0 ? '$string desde el final' : string;
  }
}
