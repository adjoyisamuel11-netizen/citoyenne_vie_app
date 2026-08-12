import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/storage_service.dart';

class ApiClient {
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // PAS de mot-clé 'static' ici
  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await http.get(url, headers: headers);
  }

  // PAS de mot-clé 'static' ici
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await http.delete(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}