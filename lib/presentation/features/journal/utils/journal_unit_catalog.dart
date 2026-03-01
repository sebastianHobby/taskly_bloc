class JournalUnitOption {
  const JournalUnitOption({
    required this.key,
    required this.label,
    required this.category,
  });

  final String key;
  final String label;
  final String category;
}

const List<JournalUnitOption> journalUnitCatalog = <JournalUnitOption>[
  JournalUnitOption(key: 'times', label: 'times', category: 'Count'),
  JournalUnitOption(key: 'steps', label: 'steps', category: 'Count'),
  JournalUnitOption(key: 'reps', label: 'reps', category: 'Count'),
  JournalUnitOption(key: 'ml', label: 'ml', category: 'Volume'),
  JournalUnitOption(key: 'l', label: 'l', category: 'Volume'),
  JournalUnitOption(key: 'oz', label: 'oz', category: 'Volume'),
  JournalUnitOption(key: 'cup', label: 'cup', category: 'Volume'),
  JournalUnitOption(key: 'g', label: 'g', category: 'Mass'),
  JournalUnitOption(key: 'kg', label: 'kg', category: 'Mass'),
  JournalUnitOption(key: 'oz_mass', label: 'oz', category: 'Mass'),
  JournalUnitOption(key: 'lb', label: 'lb', category: 'Mass'),
  JournalUnitOption(key: 'minutes', label: 'min', category: 'Duration'),
  JournalUnitOption(key: 'hours', label: 'hours', category: 'Duration'),
];

bool isCanonicalUnitKey(String unitKey) {
  final key = unitKey.trim().toLowerCase();
  if (key.isEmpty) return false;
  for (final unit in journalUnitCatalog) {
    if (unit.key == key) return true;
  }
  return false;
}

String journalUnitLabel(String? unitKey) {
  final key = (unitKey ?? '').trim().toLowerCase();
  if (key.isEmpty) return '';
  for (final unit in journalUnitCatalog) {
    if (unit.key == key) return unit.label;
  }
  return key;
}
