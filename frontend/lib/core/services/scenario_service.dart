import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ScenarioService {
  static String get _apiUrl => dotenv.env['SCENARIO_API_URL']!;

  static Future<String?> _currentSub() async {
    try {
      final attrs = await AuthService.fetchUserAttributes();
      return attrs['sub'];
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _post(
      Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 30));

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
          data['error'] ?? 'Request failed (${response.statusCode})');
    }
    return data;
  }

  static Future<List<Map<String, dynamic>>> loadScenarios() async {
    final sub = await _currentSub();
    if (sub == null) return [];
    final data = await _post({'action': 'list', 'userId': sub});
    final list = data['scenarios'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> addScenario(
    Map<String, dynamic> metadata,
    Map<String, dynamic> rawResults,
  ) async {
    final sub = await _currentSub();
    if (sub == null) return;
    await _post({
      'action': 'save',
      'userId': sub,
      'metadata': metadata,
      'results': rawResults,
    });
  }

  static Future<Map<String, dynamic>> getScenarioResults(String s3Key) async {
    final data = await _post({'action': 'get', 's3Key': s3Key});
    return data['results'] as Map<String, dynamic>;
  }

  static Future<void> deleteScenario({
    required String userId,
    required String scenarioId,
    required String s3Key,
  }) async {
    await _post({
      'action': 'delete',
      'userId': userId,
      'scenarioId': scenarioId,
      's3Key': s3Key,
    });
  }

  static Future<void> deleteCurrentUserScenarios() async {
    final scenarios = await loadScenarios();
    for (final scenario in scenarios) {
      final userId = scenario['userId'] as String?;
      final scenarioId = scenario['scenarioId'] as String?;
      final s3Key = scenario['s3Key'] as String?;
      if (userId == null || scenarioId == null || s3Key == null) continue;
      await deleteScenario(
        userId: userId,
        scenarioId: scenarioId,
        s3Key: s3Key,
      );
    }
  }
}
