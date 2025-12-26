enum MoodRating {
  veryLow(1, 'Very Low', 'ðŸ˜¢'),
  low(2, 'Low', 'ðŸ˜•'),
  neutral(3, 'Neutral', 'ðŸ˜'),
  good(4, 'Good', 'ðŸ™‚'),
  excellent(5, 'Excellent', 'ðŸ˜„');

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
