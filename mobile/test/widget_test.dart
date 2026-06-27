import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:smart_health/models/condition.dart';
import 'package:smart_health/models/diagnosis_result.dart';
import 'package:smart_health/models/provider.dart';
import 'package:smart_health/services/api_service.dart';
import 'package:smart_health/screens/symptom_input_screen.dart';
import 'package:smart_health/widgets/condition_card.dart';

/// A MockClient that serves canned JSON so the UI and parsing can be tested
/// without a running backend.
ApiService buildMockApi() {
  final client = MockClient((request) async {
    if (request.url.path == '/api/symptoms') {
      return http.Response(
        jsonEncode({
          'count': 2,
          'symptoms': [
            {'id': 'fever', 'name': 'Fever', 'category': 'general', 'common': true},
            {'id': 'cough', 'name': 'Cough', 'category': 'respiratory', 'common': true},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.url.path == '/api/diagnose') {
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': 'malaria',
              'name': 'Malaria',
              'specialist': 'General Physician',
              'severity': 'high',
              'description': 'Test',
              'confidence': 86.0,
              'matchedSymptoms': ['fever'],
            }
          ],
          'recommendedSpecialist': 'General Physician',
          'specialistInfo': {'description': 'First point of contact.'},
          'disclaimer': 'This is a guidance tool.',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(jsonEncode({'error': 'not found'}), 404);
  });
  return ApiService(baseUrl: 'http://test.local', client: client);
}

void main() {
  test('DiagnosisResult parses ranked conditions and specialist', () {
    final json = {
      'results': [
        {
          'id': 'malaria',
          'name': 'Malaria',
          'specialist': 'General Physician',
          'severity': 'high',
          'description': 'Test',
          'confidence': 86.0,
          'matchedSymptoms': ['fever', 'chills'],
        }
      ],
      'recommendedSpecialist': 'General Physician',
      'specialistInfo': {'description': 'First point of contact.'},
      'disclaimer': 'This is a guidance tool.',
    };
    final result = DiagnosisResult.fromJson(json);
    expect(result.results.length, 1);
    expect(result.results.first.name, 'Malaria');
    expect(result.recommendedSpecialist, 'General Physician');
    expect(result.disclaimer, contains('guidance'));
  });

  test('Provider distanceLabel formats metres and kilometres', () {
    const a = Provider(id: '1', name: 'A Clinic', specialty: 'x', distanceMetres: 850);
    const b = Provider(id: '2', name: 'B Clinic', specialty: 'x', distanceMetres: 1816);
    expect(a.distanceLabel, '850 m');
    expect(b.distanceLabel, '1.8 km');
    expect(b.initials, 'BC');
  });

  testWidgets('ConditionCard shows name and confidence', (tester) async {
    const condition = Condition(
      id: 'malaria',
      name: 'Malaria',
      specialist: 'General Physician',
      severity: 'high',
      description: 'Test',
      confidence: 86,
      matchedSymptoms: ['fever'],
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ConditionCard(condition: condition, emphasised: true)),
    ));
    expect(find.text('Malaria'), findsOneWidget);
    expect(find.text('86%'), findsOneWidget);
  });

  testWidgets('Symptom input screen loads common chips from the API', (tester) async {
    final api = buildMockApi();
    await tester.pumpWidget(MaterialApp(home: SymptomInputScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Check Your Symptoms'), findsOneWidget);
    expect(find.text('Fever'), findsOneWidget);
    expect(find.text('Cough'), findsOneWidget);
    expect(find.text('Analyse Symptoms'), findsOneWidget);
  });
}
