import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Pour la gestion des dates

// URL de base de l'API
const String baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

class ApiService {
  // URL de base de l'API (utilisée pour construire les URLs des endpoints)
  static const String _baseUrl = baseUrl;

  // Instance de FlutterSecureStorage pour stocker des données sensibles
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Récupère le token JWT depuis le stockage sécurisé
  Future<String?> get jwtToken async => await storage.read(key: 'jwt_token');

  // Récupère l'ID de l'utilisateur depuis le stockage sécurisé
  Future<String?> get userId async => await storage.read(key: 'user_id');

  // Vérifie si l'utilisateur est authentifié
  Future<bool> checkAuthentication() async {
    final token = await jwtToken;
    return token != null && token.isNotEmpty;
  }

  // Méthode POST générique pour envoyer des données à l'API
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
        print('❌ Erreur HTTP ${response.statusCode}');
        print('📥 Requête envoyée: ${json.encode(data)}');
        print('📤 Réponse de l\'API: ${response.body}');
        throw HttpException('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la requête POST : $e');
      rethrow;
    }
  }

  // Connexion de l'utilisateur
  Future<void> login(String email, String password) async {
    try {
      final response = await post('authentication_token', {
        'email': email,
        'password': password,
      });

      if (response['token'] == null) {
        throw HttpException('Token manquant dans la réponse');
      }

      await storage.write(key: 'jwt_token', value: response['token']);
      final userId = response['user_id'].toString();

      if (userId.isEmpty) {
        throw HttpException('ID utilisateur manquant');
      }

      await storage.write(key: 'user_id', value: userId);
      await getUserData();
    } catch (e) {
      print('Erreur lors de la connexion : $e');
      await logout();
      rethrow;
    }
  }

  // Déconnexion de l'utilisateur
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_id');
    print('Utilisateur déconnecté');
  }

  // Récupère les données de l'utilisateur connecté
  Future<Map<String, dynamic>> getUserData() async {
    final userId = await storage.read(key: 'user_id');
    if (userId == null) throw HttpException('Utilisateur non authentifié');

    final uri = Uri.parse('${_baseUrl}users/$userId');
    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await storage.write(key: 'user_email', value: data['email']);
      await storage.write(key: 'user_prenom', value: data['prenom']);

      return {
        'id': data['id'],
        'email': data['email'],
        'prenom': data['prenom'],
        'nom': data['nom'],
        'dateInscription': data['dateInscription'],
        'messages': data['messages'] ?? [],
      };
    } else {
      throw HttpException('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Récupère les messages paginés
  Future<List<Map<String, dynamic>>> fetchMessages({int page = 1}) async {
    final uri = Uri.parse('${_baseUrl}messages?page=$page');
    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['hydra:member']);
    } else {
      throw HttpException('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Envoie un nouveau message
  Future<Map<String, dynamic>> sendMessage(String titre, String contenu) async {
    final now = DateTime.now();
    final datePoste = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(now);

    final data = {
      'titre': titre,
      'datePoste': datePoste,
      'contenu': contenu,
      'envoyer': '/forum/api/users/${await userId}',
      'votes': [],
      'score': 0,
    };

    return post('messages', data, requiresAuth: true);
  }

  // Récupère les réponses à un message parent
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
      throw HttpException('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Envoie une réponse à un message parent
  Future<Map<String, dynamic>> postReply(int parentId, String contenu) async {
    final data = {'contenu': contenu, 'repondre': '/messages/$parentId'};
    return post('messages', data, requiresAuth: true);
  }

  // Récupère les messages envoyés par l'utilisateur connecté
  Future<List<Map<String, dynamic>>> fetchUserMessages() async {
    final userId = await storage.read(key: 'user_id');
    if (userId == null) throw HttpException('Utilisateur non authentifié');

    final uri = Uri.parse('$_baseUrl/messages').replace(
      queryParameters: {'envoyer.id': userId, 'itemsPerPage': '100'},
    );

    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['hydra:member']);
    } else {
      throw HttpException('Erreur HTTP ${response.statusCode}');
    }
  }
}

// Classe personnalisée pour gérer les exceptions HTTP
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}