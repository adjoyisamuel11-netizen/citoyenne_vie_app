import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/storage_service.dart';
import 'navigation_service.dart';

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

  /// Vérifie chaque réponse : si le serveur renvoie 401 (jeton invalide/expiré)
  /// en dehors de l'écran de connexion lui-même, on déconnecte automatiquement
  /// et on redirige vers le login avec un message clair — au lieu de laisser
  /// l'agent bloqué sur un écran qui ne charge jamais rien.
  Future<http.Response> _handleResponse(http.Response response, String endpoint) async {
    final estRouteLogin = endpoint.startsWith('/auth/login');
    if (response.statusCode == 401 && !estRouteLogin) {
      await StorageService.clearSession();
      NavigationService.flashMessage = 'Votre session a expiré. Veuillez vous reconnecter.';
      NavigationService.onSessionExpired?.call();
    }
    return response;
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.get(url, headers: headers);
    return _handleResponse(response, endpoint);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint);
  }

  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.delete(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, endpoint);
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint);
  }
}