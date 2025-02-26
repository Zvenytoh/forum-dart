import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:myapp/pages/search_page.dart';

void main() {
  runApp(const MyApp());
}

const String baseUrl = 'https://s3-4204.nuage-peda.fr/forum/api/';

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
        '/newMessage': (context) => const NewMessagePage(),
        '/search': (context) => const SearchForumPage(),
      },
    );
  }
}

class ApiService {
  static const String _baseUrl = baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<String?> get jwtToken async => await storage.read(key: 'jwt_token');

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data,
      {bool requiresAuth = false}) async {
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
      throw HttpException('Erreur HTTP ${response.statusCode}: ${response.body}');
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
      throw HttpException('Erreur HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String titre, String contenu) async {
    // Prépare les données à envoyer.
    final data = {
      'titre': titre,
      'contenu': contenu,
      // Selon l'API, tu peux ajouter d'autres champs si nécessaire.
      // Par exemple, 'datePoste' peut être géré côté serveur.
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.chat_bubble, size: 26, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Forum', style: TextStyle(fontSize: 24)),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 6.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.login, size: 24, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add, size: 24, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/register'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenue sur le Forum!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color color;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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
      await api.login(_emailController.text, _passwordController.text);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/forum');
      }
    } on HttpException catch (e) {
      setState(() => _errorMessage = e.toString());
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
                  validator: (value) => value!.contains('@') ? null : 'Email invalide',
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (value) =>
                      value!.length >= 6 ? null : '6 caractères minimum',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
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
      debugPrint("HttpException lors de l'inscription : ${e.toString()}");
      setState(() => _errorMessage = e.toString());
    } catch (e, stacktrace) {
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
          child: SingleChildScrollView(
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
                  validator: (value) => value!.isEmpty ? 'Mot de passe requis' : null,
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
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('S\'inscrire'),
                ),
              ],
            ),
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
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _apiService.fetchMessages();
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de charger les messages.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _apiService.logout();
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/');
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Card(
                      child: ListTile(
                        title: Text(message['titre'] ?? 'Sans titre'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message['contenu'] ?? 'Pas de contenu'),
                            const SizedBox(height: 4),
                            Text('Envoyé par : ${message['envoyer'] ?? 'Inconnu'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/newMessage').then((_) => _loadMessages());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});

  @override
  _NewMessagePageState createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _apiService.sendMessage(_titreController.text, _contenuController.text);
      if (!mounted) return;
      Navigator.pop(context);
    } on HttpException catch (e) {
      setState(() => _errorMessage = e.toString());
    } catch (e) {
      setState(() => _errorMessage = 'Erreur inconnue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau message')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titreController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (value) => value!.isEmpty ? 'Titre requis' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _contenuController,
                  decoration: const InputDecoration(labelText: 'Contenu'),
                  maxLines: 5,
                  validator: (value) => value!.isEmpty ? 'Contenu requis' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Envoyer'),
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
