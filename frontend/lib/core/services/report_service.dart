import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ReportService {
  static String get _apiUrl => dotenv.env['REPORT_API_URL']!;

  static Future<String> generateReport({
    required String scenario,
    required String temperature,
    required String pressure,
    required String scenarioId,
    required dynamic selectedValue,
    required bool useReservoir,
    required Map<String, dynamic> results,
    Map<String, dynamic>? reservoir,
  }) async {
    final payload = {
      'scenario':      scenario,
      'temperature':   temperature,
      'pressure':      pressure,
      'scenarioId':    scenarioId,
      'selectedValue': selectedValue,
      'use_reservoir': useReservoir,
      'results':       _sanitize(results),
      if (reservoir != null) 'reservoir': reservoir,
    };

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['url'] as String;
    }

    final err = json.decode(response.body);
    throw Exception(err['error'] ?? 'Report generation failed (${response.statusCode})');
  }

  // Strips Flutter-only types (Color, IconData) that cannot be JSON-encoded.
  static dynamic _sanitize(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value
          .map((k, v) => MapEntry(k, _sanitize(v)))
        ..removeWhere((_, v) => v == null);
    }
    if (value is num || value is String || value is bool) return value;
    return null;
  }
}
