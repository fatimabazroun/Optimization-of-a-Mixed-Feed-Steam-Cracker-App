import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Persists scenarios per-user using SharedPreferences keyed by Cognito sub.
class ScenarioService {
  static String _key(String sub) => 'scenarios_$sub';

  /// Returns the current user's sub, or null if not signed in.
  static Future<String?> _currentSub() async {
    try {
      final attrs = await AuthService.fetchUserAttributes();
      return attrs['sub'];
    } catch (_) {
      return null;
    }
  }

  /// Loads all saved scenarios for the current user.
  static Future<List<Map<String, dynamic>>> loadScenarios() async {
    final sub = await _currentSub();
    if (sub == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(sub));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Saves the full scenarios list for the current user.
  static Future<void> _persist(String sub, List<Map<String, dynamic>> scenarios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(sub), jsonEncode(scenarios));
  }

  /// Adds a new scenario to the top of the current user's list.
  static Future<void> addScenario(Map<String, dynamic> scenario) async {
    final sub = await _currentSub();
    if (sub == null) return;
    final list = await loadScenarios();
    list.insert(0, scenario);
    await _persist(sub, list);
  }

  /// Removes the scenario at [index] from the current user's list.
  static Future<void> deleteScenario(int index) async {
    final sub = await _currentSub();
    if (sub == null) return;
    final list = await loadScenarios();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _persist(sub, list);
  }
}
