class ValueModel {
  ValueModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
}
