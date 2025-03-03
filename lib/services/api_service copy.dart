import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

class ApiService {
  static const String _baseUrl = baseUrl; // Utilisation de la constante baseUrl
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

  // Fonction pour se connecter
  Future<void> login(String email, String password) async {
    final response = await post('authentication_token', {
      'email': email,
      'password': password,
    });

    final token = response['token'];
    await storage.write(key: 'jwt_token', value: token);

    // Après la connexion, récupérer les informations de l'utilisateur
    await fetchUserIri();
  }

  // Fonction de déconnexion
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_email');
  }

  // Fonction pour récupérer les messages
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

  // Fonction pour envoyer un message
  Future<Map<String, dynamic>> sendMessage(String titre, String contenu) async {
    final data = {'titre': titre, 'contenu': contenu};

    return post('messages', data, requiresAuth: true);
  }

  // Fonction pour récupérer les réponses à un message
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

  // Fonction pour répondre à un message
  Future<Map<String, dynamic>> postReply(int parentId, String contenu) async {
    final data = {'contenu': contenu, 'repondre': '/messages/$parentId'};

    return post('messages', data, requiresAuth: true);
  }

  // Nouvelle fonction pour récupérer l'IRI de l'utilisateur via l'API /api/me
  Future<void> fetchUserIri() async {
    final token = await jwtToken;
    if (token == null) {
      throw HttpException('Non authentifié');
    }

    final uri = Uri.parse('${_baseUrl}me'); // Requête à /api/me
    final headers = {
      'Accept': 'application/json', // Définition du type de réponse attendu
      'Authorization':
          'Bearer $token', // Utilisation du token d'authentification
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final userId = data['id']; // Récupération de l'id de l'utilisateur
      final userEmail =
          data['email']; // Récupération de l'email de l'utilisateur
      print('User ID: $userId');
      print('User Email: $userEmail');

      // Stocker l'id et l'email dans le stockage sécurisé
      await storage.write(key: 'user_id', value: userId.toString());
      await storage.write(key: 'user_email', value: userEmail);
    } else {
      throw HttpException(
        'Erreur HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  // Fonction pour enregistrer le vote de l'utilisateur
  Future<void> vote(int messageId, int voteType) async {
    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(
      key: 'user_id',
    ); // Récupérer l'ID de l'utilisateur

    if (token == null || userId == null) {
      throw HttpException('Non authentifié ou ID utilisateur manquant');
    }

    // Construire les IRIs absolues
    final messageIri = '/forum/api/messages/$messageId';
    final userIri = '/forum/api/users/$userId'; // IRI absolue de l'utilisateur
    
    // Créer le corps de la requête
    final requestBody = {
      'user':
          userIri, // Par exemple "https://s3-4204.nuage-peda.fr/forum/api/users/42"
      'message':
          messageIri, // Par exemple "https://s3-4204.nuage-peda.fr/forum/api/messages/123"
      'voteType': voteType, // Valeur de vote : 1 pour upvote, -1 pour downvote
      'createdAt': DateTime.now().toIso8601String(), // Format ISO 8601
    };

    try {
      // Envoyer la requête POST pour enregistrer le vote
      final response = await http.post(
        Uri.parse('${_baseUrl}votes'),
        headers: {
          'Content-Type': 'application/ld+json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      
      if (response.statusCode != 201) {
        // Log l'erreur si la requête échoue
        throw HttpException(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      // Log des erreurs exceptionnelles
      print('Erreur lors de l\'envoi de la requête: $e');
      throw HttpException('Erreur lors de l\'envoi du vote: $e');
    }
  }
}

class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() => message;
}
