import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import du package intl pour gérer la date au format ISO 8601

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

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        // 🔹 Affiche l'erreur dans la console
        print('❌ Erreur HTTP ${response.statusCode}');
        print('📥 Requête envoyée: ${json.encode(data)}');
        print('📤 Réponse de l\'API: ${response.body}');

        throw HttpException(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      // 🔹 Affiche l'erreur en cas d'échec de la requête
      print('⚠️ Erreur lors de la requête POST : $e');
      rethrow; // Relance l'exception pour être gérée ailleurs si besoin
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
    final now = DateTime.now();
    final datePoste = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(now);

    final data = {
      'titre': titre,
      'datePoste': datePoste, // Format ISO 8601
      'contenu': contenu,
      'envoyer': '/forum/api/users/16', // ID utilisateur (à adapter dynamiquement)
      'votes': [], // Liste vide pour éviter les erreurs
      'score': 0, // Valeur par défaut pour un nouveau message
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
    final data = {'contenu': contenu, 'repondre': '/messages/$parentId'};

    return post('messages', data, requiresAuth: true);
  }
}

class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() => message;
}
