// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  runApp(const MyApp());
}

final String baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forum': (context) => const ForumPage(),
      },
    );
  }
}
class ApiService {
  static const String _baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<String?> get jwtToken async => await storage.read(key: 'jwt_token');

  Future<Map<String, dynamic>> post(String endpoint, dynamic body) async {
    final String? token = await jwtToken;
    final Uri url = Uri.parse('$_baseUrl/$endpoint');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/ld+json',
        'Accept': 'application/ld+json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {

      throw HttpException(response.statusCode, jsonDecode(response.body));
    }
  }
}

class HttpException implements Exception {
  final int statusCode;
  final dynamic data;

  HttpException(this.statusCode, this.data);

  @override
  String toString() => 'HTTP Error $statusCode: $data';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forum')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final api = ApiService();
      final response = await api.post('authentication_token', {
        'username': _emailController.text,
        'password': _passwordController.text,
      });

      await api.storage.write(key: 'jwt_token', value: response['token']);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/forum');
      }
    } on HttpException catch (e) {
      setState(
        () => _errorMessage = e.data['message'] ?? 'Erreur de connexion',
      );
    } catch (e) {
      setState(() => _errorMessage = 'Erreur inconnue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (value) => value!.contains('@') ? null : 'Email invalide',
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator:
                      (value) =>
                          value!.length >= 6 ? null : '6 caractères minimum',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Se connecter'),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final api = ApiService();
    final result = await api.post('users', {
      'email': _emailController.text,
      'roles': ['ROLE_USER'],
      'password': _passwordController.text,
      'nom': _lastNameController.text,
      'prenom': _firstNameController.text,
      'dateInscription': DateTime.now().toIso8601String(),
      'messages': [],
    });
    debugPrint("Inscription réussie : $result");

    if (!mounted) return;
    Navigator.pop(context);
  } on HttpException catch (e) {
    // Affiche l'erreur complète dans la console pour le debug
    debugPrint("HttpException lors de l'inscription : ${e.toString()}");
    setState(() => _errorMessage = e.toString());
  } catch (e, stacktrace) {
    // Affiche l'erreur et la stack trace dans la console
    debugPrint("Erreur inconnue lors de l'inscription : $e");
    debugPrint(stacktrace.toString());
    setState(() => _errorMessage = 'Erreur inconnue : $e');
  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Email requis' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) => value!.isEmpty ? 'Mot de passe requis' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) => value!.isEmpty ? 'Nom requis' : null,
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (value) => value!.isEmpty ? 'Prénom requis' : null,
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('S\'inscrire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await const FlutterSecureStorage().delete(key: 'jwt_token');
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/');
              });
            },
          ),
        ],
      ),
      body: const Center(child: Text('Bienvenue sur le forum !')),
    );
  }
}
