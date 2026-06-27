import 'condition.dart';

/// The full response from POST /api/diagnose: ranked conditions, the
/// recommended specialist, and the mandatory guidance disclaimer.
class DiagnosisResult {
  final List<Condition> results;
  final String? recommendedSpecialist;
  final String? specialistDescription;
  final String disclaimer;

  const DiagnosisResult({
    required this.results,
    required this.recommendedSpecialist,
    required this.specialistDescription,
    required this.disclaimer,
  });

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    final info = json['specialistInfo'] as Map<String, dynamic>?;
    return DiagnosisResult(
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => Condition.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedSpecialist: json['recommendedSpecialist'] as String?,
      specialistDescription: info?['description'] as String?,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
