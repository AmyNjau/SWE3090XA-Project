/// A selectable symptom from the backend catalogue.
class Symptom {
  final String id;
  final String name;
  final String category;
  final bool common;

  const Symptom({
    required this.id,
    required this.name,
    required this.category,
    this.common = false,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'general',
      common: json['common'] as bool? ?? false,
    );
  }
}
