import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': 'Precision POS Flutter',
          'platform': 'android' // or detect platform
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiConfig.saveToken(data['token']);
        
        final prefs = await SharedPreferences.getInstance();
        if (data['user'] != null) {
          await prefs.setString('user_role', data['user']['role'] ?? '');
          await prefs.setString('user_name', data['user']['name'] ?? '');
        }

        if (data['store'] != null) {
           await prefs.setString('store_name', data['store']['name'] ?? '');
           await prefs.setString('store_address', data['store']['address'] ?? '');
           await prefs.setString('store_phone', data['store']['phone'] ?? '');
        }
        
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'role': role,
          'device_name': 'Precision POS Flutter',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
           await ApiConfig.saveToken(data['token']);
        }

        final prefs = await SharedPreferences.getInstance();
        if (data['user'] != null) {
          await prefs.setString('user_role', data['user']['role'] ?? '');
          await prefs.setString('user_name', data['user']['name'] ?? '');
        }

        if (data['store'] != null) {
           await prefs.setString('store_name', data['store']['name'] ?? '');
           await prefs.setString('store_address', data['store']['address'] ?? '');
           await prefs.setString('store_phone', data['store']['phone'] ?? '');
        }

        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
