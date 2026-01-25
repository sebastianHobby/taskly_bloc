enum RoutineType {
  weeklyFixed,
  weeklyFlexible,
  monthlyFixed,
  monthlyFlexible,
}

extension RoutineTypeStorageKey on RoutineType {
  String get storageKey => switch (this) {
    RoutineType.weeklyFixed => 'weekly_fixed',
    RoutineType.weeklyFlexible => 'weekly_flexible',
    RoutineType.monthlyFixed => 'monthly_fixed',
    RoutineType.monthlyFlexible => 'monthly_flexible',
  };

  static RoutineType fromStorageKey(String raw) {
    return switch (raw.trim()) {
      'weekly_fixed' => RoutineType.weeklyFixed,
      'weekly_flexible' => RoutineType.weeklyFlexible,
      'monthly_fixed' => RoutineType.monthlyFixed,
      'monthly_flexible' => RoutineType.monthlyFlexible,
      _ => RoutineType.weeklyFlexible,
    };
  }
}
