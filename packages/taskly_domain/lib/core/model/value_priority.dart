/// Public entrypoint for value priority.
///
/// This file exists so code generation (e.g. Drift) can import this type via a
/// non-`lib/src` URI.
library;

enum ValuePriority {
  low(1),
  medium(3),
  high(5);

  const ValuePriority(this.weight);

  final int weight;
}
