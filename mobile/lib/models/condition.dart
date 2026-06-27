/// One ranked probable condition returned by the diagnostic engine.
class Condition {
  final String id;
  final String name;
  final String specialist;
  final String severity; // low | medium | high
  final String description;
  final double confidence; // 0..100
  final List<String> matchedSymptoms;

  const Condition({
    required this.id,
    required this.name,
    required this.specialist,
    required this.severity,
    required this.description,
    required this.confidence,
    required this.matchedSymptoms,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      id: json['id'] as String,
      name: json['name'] as String,
      specialist: json['specialist'] as String? ?? 'General Physician',
      severity: json['severity'] as String? ?? 'medium',
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num).toDouble(),
      matchedSymptoms: (json['matchedSymptoms'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
