import 'package:flutter_test/flutter_test.dart';
import 'package:rrule/rrule.dart';
import 'package:taskly_bloc/core/l10n/rrule_l10n_es.dart';

void main() {
  group('RruleL10nEs', () {
    late RruleL10nEs l10n;

    setUp(() async {
      l10n = await RruleL10nEs.create();
    });

    test('locale is es_ES', () {
      expect(l10n.locale, 'es_ES');
    });

    group('frequencyInterval', () {
      test('returns correct Spanish for daily frequency', () {
        expect(l10n.frequencyInterval(Frequency.daily, 1), 'Cada día');
      });

      test('returns correct Spanish for weekly frequency', () {
        expect(l10n.frequencyInterval(Frequency.weekly, 1), 'Cada semana');
      });

      test('returns correct Spanish for monthly frequency', () {
        expect(l10n.frequencyInterval(Frequency.monthly, 1), 'Mensualmente');
      });

      test('returns correct Spanish for yearly frequency', () {
        expect(l10n.frequencyInterval(Frequency.yearly, 1), 'Anualmente');
      });

      test('returns correct Spanish for every 2 days', () {
        expect(l10n.frequencyInterval(Frequency.daily, 2), 'Cada 2 días');
      });

      test('returns correct Spanish for every 3 weeks', () {
        expect(l10n.frequencyInterval(Frequency.weekly, 3), 'Cada 3 semanas');
      });

      test('returns correct Spanish for every 5 months', () {
        expect(l10n.frequencyInterval(Frequency.monthly, 5), 'Cada 5 meses');
      });
    });

    group('count', () {
      test('returns correct Spanish for once', () {
        expect(l10n.count(1), ', una vez');
      });

      test('returns correct Spanish for twice', () {
        expect(l10n.count(2), ', dos veces');
      });

      test('returns correct Spanish for 5 times', () {
        expect(l10n.count(5), ', 5 veces');
      });

      test('returns correct Spanish for 10 times', () {
        expect(l10n.count(10), ', 10 veces');
      });
    });

    group('ordinal', () {
      test('returns correct Spanish ordinal for 1', () {
        expect(l10n.ordinal(1), '1º');
      });

      test('returns correct Spanish ordinal for 2', () {
        expect(l10n.ordinal(2), '2º');
      });

      test('returns correct Spanish ordinal for 10', () {
        expect(l10n.ordinal(10), '10º');
      });

      test('returns correct Spanish for last', () {
        expect(l10n.ordinal(-1), 'último');
      });

      test('returns correct Spanish for 2nd-to-last', () {
        expect(l10n.ordinal(-2), '2º desde el final');
      });
    });

    group('list', () {
      test('formats conjunctive short list correctly', () {
        final result = l10n.list([
          'lunes',
          'martes',
        ], ListCombination.conjunctiveShort);
        expect(result, 'lunes y martes');
      });

      test('formats conjunctive long list correctly', () {
        final result = l10n.list(
          ['lunes', 'martes', 'miércoles'],
          ListCombination.conjunctiveLong,
        );
        expect(result, 'lunes, martes, y miércoles');
      });

      test('formats disjunctive list correctly', () {
        final result = l10n.list([
          'lunes',
          'martes',
        ], ListCombination.disjunctive);
        expect(result, 'lunes o martes');
      });
    });

    test('weekdaysString returns correct Spanish', () {
      expect(l10n.weekdaysString, 'días laborables');
    });

    test('everyXDaysOfWeekPrefix returns correct Spanish', () {
      expect(l10n.everyXDaysOfWeekPrefix, 'cada ');
    });

    test('onInstances returns correct Spanish', () {
      expect(l10n.onInstances('primera'), 'en la primera instancia');
    });

    test('inMonths returns correct Spanish', () {
      expect(l10n.inMonths('enero'), 'en enero');
    });

    test('inWeeks returns correct Spanish', () {
      expect(l10n.inWeeks('primera'), 'en la primera semana del año');
    });

    test('onDaysOfWeek returns correct Spanish', () {
      expect(
        l10n.onDaysOfWeek('lunes'),
        'el lunes',
      );
    });

    test('onDaysOfWeek with frequency returns correct Spanish', () {
      expect(
        l10n.onDaysOfWeek(
          'lunes',
          indicateFrequency: true,
        ),
        'el lunes del mes',
      );
    });

    test('onDaysOfMonth returns correct Spanish', () {
      expect(
        l10n.onDaysOfMonth('15'),
        'el el 15 día del mes',
      );
    });

    test('onDaysOfYear returns correct Spanish', () {
      expect(l10n.onDaysOfYear('100'), 'el el 100 día del año');
    });

    test('nthDaysOfWeek returns correct Spanish', () {
      expect(
        l10n.nthDaysOfWeek([1, 3], 'lunes'),
        'el 1º y 3º lunes',
      );
    });

    group('RecurrenceRule.toText with Spanish', () {
      test('formats daily recurrence in Spanish', () async {
        final rule = RecurrenceRule(frequency: Frequency.daily);
        final text = rule.toText(l10n: l10n);
        expect(text, 'Cada día');
      });

      test('formats weekly recurrence in Spanish', () async {
        final rule = RecurrenceRule(frequency: Frequency.weekly);
        final text = rule.toText(l10n: l10n);
        expect(text, 'Cada semana');
      });

      test('formats monthly recurrence in Spanish', () async {
        final rule = RecurrenceRule(frequency: Frequency.monthly);
        final text = rule.toText(l10n: l10n);
        expect(text, 'Mensualmente');
      });

      test('formats every 2 days in Spanish', () async {
        final rule = RecurrenceRule(frequency: Frequency.daily, interval: 2);
        final text = rule.toText(l10n: l10n);
        expect(text, 'Cada 2 días');
      });

      test('formats recurrence with count in Spanish', () async {
        final rule = RecurrenceRule(frequency: Frequency.daily, count: 5);
        final text = rule.toText(l10n: l10n);
        expect(text, 'Cada día, 5 veces');
      });
    });
  });
}
