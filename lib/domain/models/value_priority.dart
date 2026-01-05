enum ValuePriority {
  low(1),
  medium(3),
  high(5);

  final int weight;
  const ValuePriority(this.weight);
}
