import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart'; // Importez votre ApiService
import 'package:myapp/widgets/bottomNavBar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLoggedIn = false; // Variable pour suivre l'état de connexion

  @override
  void initState() {
    super.initState();
    _checkAuthentication(); // Vérifier l'état de connexion au chargement
  }

  // Vérifie si l'utilisateur est connecté
  Future<void> _checkAuthentication() async {
    final isAuthenticated = await ApiService().checkAuthentication();
    setState(() {
      _isLoggedIn = isAuthenticated;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.popAndPushNamed(context, '/');
        break;
      case 1:
        Navigator.popAndPushNamed(context, '/forum');
        break;
      case 2:
        Navigator.popAndPushNamed(context, '/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forum',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        actions: _isLoggedIn
            ? [] // Si connecté, pas de boutons
            : [
                // Si non connecté, afficher les boutons
                IconButton(
                  icon: const Icon(Icons.login, color: Colors.white),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/login');
                    if (!context.mounted) return;
                    await _checkAuthentication(); // Rafraîchir l'état après connexion
                  },
                  tooltip: 'Se connecter',
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/register');
                    if (!context.mounted) return;
                    await _checkAuthentication(); // Rafraîchir l'état après inscription
                  },
                  tooltip: 'S\'inscrire',
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec image et dégradé
            Container(
              height: 300,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/forum_header.jpg'),
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.withOpacity(0.6),
                    Colors.indigo.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bienvenue sur le Forum!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Participez à des discussions enrichissantes',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}