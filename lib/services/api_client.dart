import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Ambil token yang sudah disimpan
    final token = await ApiConfig.getToken();
    
    // Inject token ke header untuk setiap request
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    // Set Accept header agar server selalu membalas dengan format JSON
    request.headers['Accept'] = 'application/json';
    
    // Lanjutkan request HTTP
    return _inner.send(request);
  }
}
