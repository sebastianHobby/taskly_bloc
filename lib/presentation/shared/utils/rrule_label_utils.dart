import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';
import 'package:taskly_bloc/l10n/rrule_l10n_es.dart';

Future<String?> resolveRruleLabel(BuildContext context, String rrule) async {
  if (rrule.isEmpty) return null;

  try {
    final locale = Localizations.localeOf(context);
    final rruleL10n = locale.languageCode == 'es'
        ? await RruleL10nEs.create()
        : await RruleL10nEn.create();

    final recurrenceRule = RecurrenceRule.fromString(rrule);
    return recurrenceRule.toText(l10n: rruleL10n);
  } catch (_) {
    return null;
  }
}
