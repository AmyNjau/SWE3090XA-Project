import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/symptom.dart';
import '../models/diagnosis_result.dart';
import '../models/provider.dart';

/// Thrown when the backend returns an error or is unreachable, carrying a
/// human-readable message the UI can show with a retry option.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// The single point of contact between the Flutter client and the REST API.
/// The client holds no diagnostic logic of its own; it only collects input,
/// calls the API, and maps JSON responses into typed models.
class ApiService {
  final String baseUrl;
  final http.Client _client;

  /// Supplies the current Firebase ID token, or null when signed out. Injected
  /// as a callback rather than importing the auth service so this class stays
  /// free of Firebase and remains testable with a plain function.
  Future<String?> Function()? tokenProvider;

  ApiService({String? baseUrl, http.Client? client, this.tokenProvider})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  /// Authorization header for the signed-in user, empty when signed out.
  Future<Map<String, String>> _authHeaders() async {
    final token = await tokenProvider?.call();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  /// GET /api/symptoms -> the catalogue used to populate the input screen.
  Future<List<Symptom>> fetchSymptoms() async {
    final res = await _get('/api/symptoms');
    final list = (res['symptoms'] as List<dynamic>? ?? []);
    return list.map((e) => Symptom.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/diagnose -> ranked conditions + specialist + disclaimer.
  Future<DiagnosisResult> getDiagnosis(List<String> symptoms) async {
    final res = await _post('/api/diagnose', {'symptoms': symptoms});
    return DiagnosisResult.fromJson(res);
  }

  /// POST /api/providers -> nearby providers for a specialist + location.
  Future<List<Provider>> getNearbyProviders({
    required String specialist,
    required double latitude,
    required double longitude,
  }) async {
    final res = await _post('/api/providers', {
      'specialist': specialist,
      'latitude': latitude,
      'longitude': longitude,
    });
    final list = (res['providers'] as List<dynamic>? ?? []);
    return list.map((e) => Provider.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await _client.get(
        Uri.parse('$baseUrl$path'),
        headers: await _authHeaders(),
      );
      return _decode(res);
    } catch (e) {
      throw ApiException(_networkMessage(e));
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json', ...await _authHeaders()},
        body: jsonEncode(body),
      );
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_networkMessage(e));
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    final decoded = res.body.isNotEmpty
        ? jsonDecode(res.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final message = decoded['error']?.toString() ?? 'Request failed (${res.statusCode}).';
    throw ApiException(message);
  }

  String _networkMessage(Object e) =>
      'Could not reach the server. Check your connection and try again.';

  void dispose() => _client.close();
}
