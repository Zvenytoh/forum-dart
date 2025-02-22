import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<String?> get jwtToken async => await storage.read(key: 'jwt_token');

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {bool requiresAuth = false}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresAuth) 'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw HttpException('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await post('authentication_token', {
        'username': email,
        'password': password,
      });

      await storage.write(key: 'jwt_token', value: response['token']);
    } catch (e) {
      throw HttpException('Échec de la connexion: $e');
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
  }
}
