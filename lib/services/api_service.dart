import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

class ApiService {
  static const String _baseUrl = baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<String?> get jwtToken async => await storage.read(key: 'jwt_token');

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    final headers = {
      'Content-Type': 'application/ld+json',
      'Accept': 'application/ld+json',
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
      throw HttpException(
        'Erreur HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> login(String email, String password) async {
    final response = await post('authentication_token', {
      'email': email,
      'password': password,
    });
    await storage.write(key: 'jwt_token', value: response['token']);
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
  }

  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final uri = Uri.parse('${_baseUrl}messages?page=1');

    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['hydra:member']);
    } else {
      throw HttpException(
        'Erreur HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> sendMessage(String titre, String contenu) async {
    final data = {
      'titre': titre,
      'contenu': contenu,
    };

    return post('messages', data, requiresAuth: true);
  }

  Future<List<Map<String, dynamic>>> fetchReplies(int parentId) async {
    final uri = Uri.parse('${_baseUrl}messages?repondre_id=$parentId');

    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['hydra:member']);
    } else {
      throw HttpException(
        'Erreur HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> postReply(int parentId, String contenu) async {
    final data = {
      'contenu': contenu,
      'repondre': '/messages/$parentId',
    };

    return post('messages', data, requiresAuth: true);
  }
}

class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() => message;
}