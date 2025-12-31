enum MoodRating {
  veryLow(1, 'Very Low', '\u{1F622}'),
  low(2, 'Low', '\u{1F615}'),
  neutral(3, 'Neutral', '\u{1F610}'),
  good(4, 'Good', '\u{1F642}'),
  excellent(5, 'Excellent', '\u{1F604}');

  const MoodRating(this.value, this.label, this.emoji);

  final int value;
  final String label;
  final String emoji;

  static MoodRating fromValue(int value) {
    return MoodRating.values.firstWhere(
      (rating) => rating.value == value,
      orElse: () => MoodRating.neutral,
    );
  }
}
