enum ValuePriority {
  low(1),
  medium(3),
  high(5);

  const ValuePriority(this.weight);

  final int weight;
}
