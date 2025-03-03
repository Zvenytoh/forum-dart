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

  Future<List<Map<String, dynamic>>> fetchTrendingMessages() async {
  final uri = Uri.parse('http://s3-4204.nuage-peda.fr/forum/messages/trending?page=1'); // URL complète avec baseUrl

  final token = await jwtToken;
  final headers = {
    'Accept': 'application/ld+json',
    'Authorization': token != null ? 'Bearer $token' : '',
  };

  try {
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      // Décode la réponse JSON
      final data = json.decode(response.body);

      // Assurez-vous que la réponse contient la clé 'hydra:member'
      if (data['hydra:member'] != null) {
        // Extrait les messages dans un format attendu
        List<Map<String, dynamic>> messages = [];
        
        for (var message in data['hydra:member']) {
          messages.add({
            'id': message['id'],
            'titre': message['titre'],
            'datePoste': message['datePoste'],
            'contenu': message['contenu'],
            'envoyer': message['envoyer'],
            'score': message['score'],
          });
        }

        return messages;
      } else {
        throw Exception('Pas de messages trouvés');
      }
    } else {
      throw Exception('Erreur lors du chargement des messages tendances');
    }
  } catch (e) {
    throw Exception('Erreur réseau : $e');
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

      // Stocker l'id et l'email dans le stockage sécurisé
      await storage.write(key: 'user_id', value: userId.toString());
      await storage.write(key: 'user_email', value: userEmail);
    } else {
      throw HttpException(
        'Erreur HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> vote(int messageId, int newVoteType) async {
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

          // Annuler le vote si l'utilisateur clique à nouveau sur le même bouton
          if (previousVoteType == newVoteType) {
            finalVoteType = 0; // Annuler le vote
            await http.delete(
              Uri.parse('${_baseUrl}votes/${existingVote['id']}'),
              headers: {'Authorization': 'Bearer $token'},
            );
          } else {
            // Mettre à jour le vote existant si l'utilisateur change son vote
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

class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() => message;
}
