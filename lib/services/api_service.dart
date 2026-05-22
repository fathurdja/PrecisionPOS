import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import '../data/database_helper.dart';

class ApiService {
  // 1. Authentication (Mobile App)
  
  // ──────────────────────────────────────────────
  // Mock user database – kept in the same shape as the real API response
  // so that toggling `ApiConfig.useMockApi = false` requires NO code changes.
  // ──────────────────────────────────────────────
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'username': 'admin',
      'password': 'admin123',
      'token': 'mock_token_admin_001',
      'user': {'id': 1, 'name': 'Budi Pemilik', 'role': 'admin'},
      'tenant': {'id': 1, 'name': 'Kopi Senja'},
    },
    {
      'username': 'kasir',
      'password': 'kasir123',
      'token': 'mock_token_kasir_002',
      'user': {'id': 2, 'name': 'Ani Kasir', 'role': 'kasir'},
      'tenant': {'id': 1, 'name': 'Kopi Senja'},
    },
    {
      'username': 'delivery',
      'password': 'delivery123',
      'token': 'mock_token_delivery_003',
      'user': {'id': 3, 'name': 'Dedi Kurir', 'role': 'delivery'},
      'tenant': {'id': 1, 'name': 'Kopi Senja'},
    },
  ];

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      final db = await DatabaseHelper.instance.database;
      final staffMaps = await db.query(
        'staff',
        where: 'email = ? AND password = ?',
        whereArgs: [email.trim().toLowerCase(), password],
      );

      Map<String, dynamic>? match;
      if (staffMaps.isNotEmpty) {
        final staff = staffMaps.first;
        match = {
          'token': 'mock_token_${staff['email']}_${staff['id']}',
          'user': {'id': staff['id'], 'name': staff['name'], 'role': staff['role']},
          'tenant': {'id': 1, 'name': 'Kopi Senja'},
        };
      } else {
        // Find matching mock user by username/email AND password
        final staticMatch = _mockUsers.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u!['username'] == email.trim().toLowerCase() && u['password'] == password,
          orElse: () => null,
        );
        if (staticMatch != null) {
          match = staticMatch;
        }
      }

      if (match == null) {
        return {'success': false, 'message': 'Username atau password salah'};
      }

      final mockData = {
        'token': match['token'],
        'user': match['user'],
        'tenant': match['tenant'],
      };

      await ApiConfig.saveToken(mockData['token'] as String);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', (mockData['user'] as Map)['role']);
      await prefs.setString('user_name', (mockData['user'] as Map)['name']);
      await prefs.setString('store_name', (mockData['tenant'] as Map)['name']);

      if (staffMaps.isNotEmpty) {
        await db.update(
          'staff',
          {'last_active': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [staffMaps.first['id']],
        );
      }

      return {'success': true, 'data': mockData};
    }

    // Real API Implementation
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/mobile/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
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

        if (data['tenant'] != null) {
           await prefs.setString('store_name', data['tenant']['name'] ?? '');
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
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      await ApiConfig.clearAuth();
      return {'success': true, 'message': 'Logout berhasil.'};
    }

    try {
      final token = await ApiConfig.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/mobile/logout'),
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

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        final db = await DatabaseHelper.instance.database;
        await db.insert('staff', {
          'name': name,
          'email': email.trim().toLowerCase(),
          'role': role,
          'password': password,
          'last_active': DateTime.now().toIso8601String(),
          'revenue': 0.0,
        });
      } catch (e) {
        print("Local staff insertion error during registration: $e");
      }
      return {'success': true, 'data': {'message': 'Mock register success'}};
    }
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

  // 2. Self-Order (AI / External Integration)
  
  Future<Map<String, dynamic>> getProducts() async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'success': true,
        'data': [
          {
            "id": 1,
            "name": "Kopi Susu",
            "category": { "name": "Drink" },
            "variants": [
              { "id": 1, "name": "Normal", "price": 15000, "stock": 10 }
            ]
          }
        ]
      };
    }

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

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'transaction_code': 'TRX-MOCK-${DateTime.now().millisecondsSinceEpoch}',
        'invoice_url': 'https://mock-xendit-url.com/invoice',
        'total_amount': orderData['total_amount'] ?? 30000
      };
    }

    try {
      final token = await ApiConfig.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(orderData),
      );
      final decoded = jsonDecode(response.body);
      return {'success': response.statusCode == 200 || response.statusCode == 201, ...decoded};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateFulfillment(String transactionId, String status) async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'success': true, 'message': 'Status updated to $status'};
    }

    try {
      final token = await ApiConfig.getToken();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/orders/$transactionId/fulfillment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      return {'success': response.statusCode == 200};
    } catch(e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // 3. Mobile POS (In-Store)

  Future<Map<String, dynamic>> getTenantProfile() async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'data': {
          'id': 1,
          'name': 'Kopi Senja',
          'address': 'Jl. Mawar No. 12',
          'phone': '08123456789'
        }
      };
    }

    try {
      final token = await ApiConfig.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/tenant/profile'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
         return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to load profile'};
    } catch(e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> transactionData) async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'transaction_id': 'TX-${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Transaction recorded successfully'
      };
    }

    try {
      final token = await ApiConfig.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/mobile/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(transactionData),
      );
      final decoded = jsonDecode(response.body);
      return {'success': response.statusCode == 200 || response.statusCode == 201, ...decoded};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getReceipt(String id) async {
    if (ApiConfig.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'data': {
          'transaction_id': id,
          'date': DateTime.now().toIso8601String(),
          'items': [
            {'name': 'Kopi Susu', 'qty': 2, 'price': 15000}
          ],
          'total': 30000,
          'payment_method': 'Cash'
        }
      };
    }

    try {
      final token = await ApiConfig.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/transactions/$id/receipt'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to load receipt'};
    } catch(e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
