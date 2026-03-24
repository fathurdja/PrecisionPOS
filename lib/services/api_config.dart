import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Use http://10.0.2.2:8000/api/v1 for Android emulator
  // Use http://localhost:8000/api/v1 for Windows/iOS simulator
  static const String baseUrl = 'https://untonsured-bettina-nonvirulent.ngrok-free.dev/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }
}
