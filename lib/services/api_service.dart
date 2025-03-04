import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// URL de base de l'API
const String baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

class ApiService {
  // URL de base de l'API (utilisée pour construire les URLs des endpoints)
  static const String _baseUrl = baseUrl;

  // Instance de FlutterSecureStorage pour stocker des données sensibles (comme le token JWT et l'ID utilisateur)
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Récupère le token JWT depuis le stockage sécurisé
  Future<String?> get jwtToken async => await storage.read(key: 'jwt_token');

  // Récupère l'ID de l'utilisateur depuis le stockage sécurisé
  Future<String?> get userId async => await storage.read(key: 'user_id');

  // Vérifie si l'utilisateur est authentifié en vérifiant la présence du token JWT
  Future<bool> checkAuthentication() async {
    final token = await jwtToken;
    return token != null && token.isNotEmpty;
  }

  // Méthode POST générique pour envoyer des données à l'API
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false, // Indique si l'authentification est requise
  }) async {
    // Construit l'URL complète pour l'endpoint
    final uri = Uri.parse('$_baseUrl$endpoint');

    // Définit les headers de la requête
    final headers = {
      'Content-Type': 'application/ld+json',
      'Accept': 'application/ld+json',
      if (requiresAuth) 'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    try {
      // Envoie la requête POST à l'API
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      // Vérifie si la réponse est réussie (code HTTP 2xx)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(
          response.body,
        ); // Retourne les données JSON de la réponse
      } else {
        // Si la réponse est une erreur, affiche un message d'erreur dans la console
        print('Erreur HTTP ${response.statusCode}: ${response.body}');
        throw HttpException(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      // En cas d'erreur réseau, affiche un message d'erreur dans la console
      print('Erreur réseau: $e');
      throw HttpException('Erreur réseau: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserMessages() async {
    try {
      // Envoyer une requête GET à l'API
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages'), // Endpoint pour récupérer les messages
        headers: {
          'Authorization': 'Bearer ${await jwtToken ?? ''}', // Ajouter le token d'authentification
          'Content-Type': 'application/json',
        },
      );

      // Vérifier le statut de la réponse
      if (response.statusCode == 200) {
        // Décoder la réponse JSON
        final List<dynamic> data = jsonDecode(response.body);

        // Convertir les données en List<Map<String, dynamic>>
        return data.map((message) => message as Map<String, dynamic>).toList();
      } else {
        // Gérer les erreurs HTTP
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      // Gérer les erreurs de connexion ou de traitement
      throw Exception('Erreur lors de la récupération des messages: $e');
    }
  }

  // Récupère les données de l'utilisateur connecté
  Future<Map<String, dynamic>> getUserData() async {
    // Récupère l'ID de l'utilisateur depuis le stockage sécurisé
    final userId = await storage.read(key: 'user_id');
    print('getUserData : user id = $userId');

    // Si l'ID utilisateur est null, l'utilisateur n'est pas authentifié
    if (userId == null) {
      print('ID utilisateur non trouvé dans le stockage');
      throw HttpException('ID utilisateur non trouvé dans le stockage');
    }

    // Construit l'URL pour récupérer les données de l'utilisateur
    final uri = Uri.parse('${_baseUrl}users/$userId');
    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    // Envoie la requête GET à l'API
    final response = await http.get(uri, headers: headers);
    print('Réponse getUserData : ${response.body}');

    // Vérifie si la réponse est réussie (code HTTP 200)
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Stocke les données supplémentaires dans le stockage sécurisé (optionnel)
      await storage.write(key: 'user_email', value: data['email']);
      await storage.write(key: 'user_prenom', value: data['prenom']);

      // Retourne les données de l'utilisateur sous forme de Map
      return {
        'id': data['id'],
        'email': data['email'],
        'prenom': data['prenom'],
        'nom': data['nom'],
        'dateInscription': data['dateInscription'],
        'messages': data['messages'] ?? [],
      };
    } else {
      // Si la réponse est une erreur, affiche un message d'erreur dans la console
      print(
        'Erreur HTTP getUserData ${response.statusCode} - ${response.body}',
      );
      throw HttpException(
        'Erreur HTTP getUserData ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Connexion de l'utilisateur
  Future<void> login(String email, String password) async {
    try {
      // Envoie une requête POST pour obtenir le token JWT
      final response = await post('authentication_token', {
        'email': email,
        'password': password,
      });

      // Vérifie si le token est présent dans la réponse
      if (response['token'] == null) {
        print('Token manquant dans la réponse');
        throw HttpException('Token manquant dans la réponse');
      }

      // Stocke le token JWT dans le stockage sécurisé
      await storage.write(key: 'jwt_token', value: response['token']);

      // L'ID utilisateur est également retourné dans la réponse
      final userId = response['user_id'].toString();

      // Vérifie si l'ID utilisateur est valide
      if (userId == null) {
        print('ID utilisateur manquant dans la réponse');
        throw HttpException('ID utilisateur manquant');
      }

      // Stocke l'ID utilisateur dans le stockage sécurisé
      await storage.write(key: 'user_id', value: userId);

      // Récupère les données complètes de l'utilisateur
      final userData = await getUserData();
      if (userData['id'] == null) {
        print('ID utilisateur non trouvé dans les données');
        throw HttpException('ID utilisateur non trouvé');
      }
    } catch (e) {
      // En cas d'erreur, déconnecte l'utilisateur et affiche l'erreur dans la console
      print('Erreur lors de la connexion : $e');
      await logout();
      rethrow;
    }
  }

  // Déconnexion de l'utilisateur
  Future<void> logout() async {
    // Supprime le token JWT et l'ID utilisateur du stockage sécurisé
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_id');
    print('Utilisateur déconnecté');
  }

  // Récupère les messages paginés
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

  // Envoie un nouveau message
  Future<Map<String, dynamic>> sendMessage(String titre, String contenu) async {
    final data = {'titre': titre, 'contenu': contenu};
    return post('messages', data, requiresAuth: true);
  }

  // Récupère les réponses à un message parent
  Future<List<Map<String, dynamic>>> fetchReplies(int parentId) async {
    // Construit l'URL pour récupérer les réponses à un message parent
    final uri = Uri.parse('$_baseUrl/messages?repondre_id=$parentId');
    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    try {
      // Envoie la requête GET à l'API
      final response = await http.get(uri, headers: headers);

      // Vérifie si la réponse est réussie (code HTTP 200)
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['hydra:member']);
      } else {
        // Si la réponse est une erreur, affiche un message d'erreur dans la console
        print(
          'Erreur HTTP fetchReplies ${response.statusCode}: ${response.body}',
        );
        throw HttpException(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      // En cas d'erreur réseau, affiche un message d'erreur dans la console
      print('Erreur réseau fetchReplies: $e');
      throw HttpException('Erreur réseau: $e');
    }
  }

  // Envoie une réponse à un message parent
  Future<Map<String, dynamic>> postReply(int parentId, String contenu) async {
    final data = {'contenu': contenu, 'repondre': '/messages/$parentId'};
    return post('messages', data, requiresAuth: true);
  }

  // Récupère les messages envoyés par l'utilisateur connecté
  Future<List<Map<String, dynamic>>> fetchUserMessages() async {
    // Récupère l'ID de l'utilisateur connecté
    final userId = await storage.read(key: 'user_id');
    if (userId == null) {
      print('Utilisateur non authentifié');
      throw HttpException('Utilisateur non authentifié');
    }

    // Construit l'URL pour récupérer les messages de l'utilisateur
    final uri = Uri.parse('$_baseUrl/messages').replace(
      queryParameters: {
        'envoyer.id': userId,
        'itemsPerPage': '100', // Nombre d'éléments par page (ajustable)
      },
    );

    final headers = {
      'Accept': 'application/ld+json',
      'Authorization': 'Bearer ${await jwtToken ?? ''}',
    };

    // Envoie la requête GET à l'API
    final response = await http.get(uri, headers: headers);

    // Vérifie si la réponse est réussie (code HTTP 200)
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['hydra:member']);
    } else {
      // Si la réponse est une erreur, affiche un message d'erreur dans la console
      print('Erreur HTTP fetchUserMessages ${response.statusCode}');
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
