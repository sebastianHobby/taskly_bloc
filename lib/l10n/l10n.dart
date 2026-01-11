import 'package:flutter/widgets.dart';
import 'package:taskly_bloc/l10n/gen/app_localizations.dart';

export 'package:taskly_bloc/l10n/gen/app_localizations.dart';
export 'rrule_l10n_es.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
