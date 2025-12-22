enum LabelType {
  label,
  value,
}

class Label {
  Label({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.color,
    this.type = LabelType.label,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? color;
  final LabelType type;
}
