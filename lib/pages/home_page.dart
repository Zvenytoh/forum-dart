import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
        backgroundColor: Colors.deepPurple, // Couleur de fond plus riche
        elevation: 10, // Ombre portée
        actions: [
          IconButton(
            icon: const Icon(Icons.login, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/login'),
            tooltip: 'Se connecter',
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/register'),
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
                image: DecorationImage(
                  image: AssetImage('assets/images/forum_header.jpg'), // Image de fond
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.withOpacity(0.6), Colors.indigo.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bienvenue sur le Forum!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
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
            SizedBox(height: 30),
            // Section de fonctionnalités
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Carte de fonctionnalité 1
                  _buildFeatureCard(
                    icon: Icons.forum,
                    title: 'Discussions Actives',
                    description: 'Rejoignez des conversations dynamiques et partagez vos idées.',
                    color: Colors.deepPurple,
                  ),
                  SizedBox(height: 20),
                  // Carte de fonctionnalité 2
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: 'Communauté Engagée',
                    description: 'Rencontrez des personnes partageant les mêmes intérêts.',
                    color: Colors.indigo,
                  ),
                  SizedBox(height: 20),
                  // Carte de fonctionnalité 3
                  _buildFeatureCard(
                    icon: Icons.trending_up,
                    title: 'Tendances',
                    description: 'Découvrez les sujets les plus populaires du moment.',
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Boutons d'action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      iconColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Se Connecter',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    child: Text(
                      'S\'inscrire',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Fonction pour construire une carte de fonctionnalité
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}