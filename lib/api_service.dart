import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String _baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer <VOTRE_TOKEN_JWT>' // Si vous avez besoin de JWT
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode != 201) {
      throw HttpException('Erreur lors de la création de l\'utilisateur');
    }

    return json.decode(response.body);
  }
}
