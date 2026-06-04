import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'; // for defaultTargetPlatform
import 'api_config.dart';

class ApiService {
  Future<Map<String, String>> _getDeviceInfo() async {
    String deviceName = 'Unknown Device';
    String platform = 'android';
    
    try {
      if (kIsWeb) {
        platform = 'web';
        deviceName = 'Web Browser';
      } else {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (defaultTargetPlatform == TargetPlatform.android) {
          platform = 'android';
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.brand} ${androidInfo.model}';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          platform = 'ios';
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.name;
        }
      }
    } catch (e) {
      // Ignore
    }
    
    return {'device_name': deviceName, 'platform': platform};
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'device_name': deviceInfo['device_name'],
          'platform': deviceInfo['platform'],
        }),
      );

      if (response.statusCode == 200) {
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

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await ApiConfig.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      await ApiConfig.clearAuth();
      return {'success': response.statusCode == 200, 'message': 'Logout berhasil.'};
    } catch (e) {
      await ApiConfig.clearAuth();
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(String name, String username, String password, String role) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'username': username,
          'password': password,
          'role': role,
          'device_name': deviceInfo['device_name'],
          'platform': deviceInfo['platform'],
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

  Future<Map<String, dynamic>> getProducts() async {
    try {
      final token = await ApiConfig.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/products'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)['data']};
      }
      return {'success': false, 'message': 'Failed to load products'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final token = await ApiConfig.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/summary'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to load analytics summary'};
    } catch(e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
