import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/journal.dart';

extension MoodRatingLocalizedLabel on MoodRating {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      MoodRating.veryLow => l10n.moodVeryLowLabel,
      MoodRating.low => l10n.moodLowLabel,
      MoodRating.neutral => l10n.moodNeutralLabel,
      MoodRating.good => l10n.moodGoodLabel,
      MoodRating.excellent => l10n.moodExcellentLabel,
    };
  }
}
