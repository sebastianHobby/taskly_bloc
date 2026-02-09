import 'package:meta/meta.dart';

/// Supported display densities for list rows.
enum DisplayDensity { compact, standard }

/// Per-page display preferences (row density, etc.).
@immutable
final class DisplayPreferences {
  const DisplayPreferences({this.density = DisplayDensity.compact});

  factory DisplayPreferences.fromJson(Map<String, dynamic> json) {
    final raw = json['density'] as String?;
    final density = DisplayDensity.values.byName(
      raw ?? DisplayDensity.compact.name,
    );
    return DisplayPreferences(density: density);
  }

  final DisplayDensity density;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'density': density.name,
  };

  DisplayPreferences copyWith({DisplayDensity? density}) {
    return DisplayPreferences(density: density ?? this.density);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayPreferences && other.density == density;

  @override
  int get hashCode => density.hashCode;
}
