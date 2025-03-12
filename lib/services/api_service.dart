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

  Future<void> vote(int messageId, int newVoteType) async {
    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(
      key: 'user_id',
    ); // récupérer l'id du user

    if (token == null || userId == null) {
      throw HttpException('Non authentifié ou ID utilisateur manquant');
    }

    final messageIri = '/forum/api/messages/$messageId';
    final userIri = '/forum/api/users/$userId'; 
    try {
      // 1. Récupérer le vote existant de l'utilisateur pour ce message
      final votesResponse = await http.get(
        Uri.parse('${_baseUrl}votes?user=$userIri&message=$messageIri'),
        headers: {'Authorization': 'Bearer $token'},
      );

      int finalVoteType = newVoteType;
      int previousVoteType = 0;

      // 2. Vérifier si l'utilisateur a déjà voté
      if (votesResponse.statusCode == 200) {
        final existingVotes =
            json.decode(votesResponse.body)['hydra:member'] as List;
        if (existingVotes.isNotEmpty) {
          final existingVote = existingVotes.first;
          previousVoteType = existingVote['voteType'] as int;

          if (previousVoteType == newVoteType) {
            finalVoteType = 0; 
            await http.delete(
              Uri.parse('${_baseUrl}votes/${existingVote['id']}'),
              headers: {'Authorization': 'Bearer $token'},
            );
          } else {
            await http.patch(
              Uri.parse('${_baseUrl}votes/${existingVote['id']}'),
              headers: {
                'Content-Type': 'application/merge-patch+json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({'voteType': newVoteType}),
            );
          }
        }
      }

      // 3. Si c'est un nouveau vote (ou un vote annulé et remplacé)
      if (finalVoteType != 0) {
        await http.post(
          Uri.parse('${_baseUrl}votes'),
          headers: {
            'Content-Type': 'application/ld+json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'user': userIri,
            'message': messageIri,
            'voteType': finalVoteType,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );
      }

      // 4. Mettre à jour le score total du message
      final patchRequestBody = {
        'score':
            newVoteType - previousVoteType, // Calculer la différence de score
      };

      final patchResponse = await http.patch(
        Uri.parse('${_baseUrl}messages/$messageId'),
        headers: {
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(patchRequestBody),
      );

      if (patchResponse.statusCode != 200) {
        throw HttpException(
          'Erreur HTTP ${patchResponse.statusCode}: ${patchResponse.body}',
        );
      }

      print('Vote enregistré et score mis à jour avec succès !');
    } catch (e) {
      print('Erreur lors de l\'envoi de la requête: $e');
      throw HttpException('Erreur lors de l\'envoi du vote: $e');
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