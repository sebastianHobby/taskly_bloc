/// Curated Plan My Day flow presets.
enum MyDayPlanFlow {
  valuesFirst,
  routinesFirst,
  triageFirst;

  static MyDayPlanFlow fromName(String? name) {
    return MyDayPlanFlow.values.firstWhere(
      (flow) => flow.name == name,
      orElse: () => MyDayPlanFlow.valuesFirst,
    );
  }
}
