import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SimulationService {
  static String get _apiUrl => dotenv.env['API_GATEWAY_URL']!;
  static String get _co2AssessmentUrl => dotenv.env['CO2_ASSESSMENT_URL']!;

  static Future<Map<String, dynamic>> runCo2Assessment({
    required double co2RateKgHr,
    required Map<String, dynamic> reservoirInputs,
  }) async {
    final payload = {
      'co2_rate_kg_hr': co2RateKgHr,
      'reservoir_inputs': reservoirInputs,
    };

    final response = await http
        .post(
          Uri.parse(_co2AssessmentUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final err = json.decode(response.body);
    throw Exception(err['error'] ?? 'Server error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> runSimulation({
    required String scenarioId,
    required dynamic selectedValue,
    bool useReservoir = false,
    Map<String, dynamic>? reservoirInputs,
  }) async {
    final payload = <String, dynamic>{
      'scenario_id': scenarioId,
      'selected_value': selectedValue,
      'use_reservoir': useReservoir,
    };
    if (useReservoir && reservoirInputs != null) {
      payload['reservoir_inputs'] = reservoirInputs;
    }

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final err = json.decode(response.body);
    throw Exception(err['error'] ?? 'Server error ${response.statusCode}');
  }
}
