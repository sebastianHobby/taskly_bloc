class Label {
  Label({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.color,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? color;
}
