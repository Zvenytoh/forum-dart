import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart'; // Assurez-vous que votre service API est importé
import 'package:myapp/widgets/bottomNavBar.dart'; // Assurez-vous que le BottomNavBar est importé

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2; // ProfilePage doit être sélectionné dans la bottom nav

  // Méthode de gestion de la navigation dans la barre de navigation en bas
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
        Navigator.popAndPushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar et nom d'utilisateur
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/default_profile.jpg'),
            ),
            const SizedBox(height: 20),
            const Text(
              'John Doe', // Remplacez par le nom de l'utilisateur
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'john.doe@example.com', // Remplacez par l'email de l'utilisateur
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            // Section des informations
            _buildProfileSection(
              icon: Icons.person,
              title: 'Informations personnelles',
              onTap: () {
                Navigator.pushNamed(context, '/editProfile');
              },
            ),
            _buildProfileSection(
              icon: Icons.security,
              title: 'Sécurité',
              onTap: () {
                Navigator.pushNamed(context, '/security');
              },
            ),
            _buildProfileSection(
              icon: Icons.settings,
              title: 'Paramètres',
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(height: 20),

            // Bouton de déconnexion
            ElevatedButton(
              onPressed: () async {
                final apiService = ApiService(); // Utilisez votre service API
                await apiService.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
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

  // Widget pour construire une section du profil
  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
