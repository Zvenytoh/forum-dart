import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/widgets/bottomNavBar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2;
  late Future<Map<String, dynamic>> _userData;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuthenticated = await ApiService().checkAuthentication();
    if (isAuthenticated) {
      _userData = ApiService().getUserData();
    }
    setState(() {
      _isLoggedIn = isAuthenticated;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/forum');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: _isLoggedIn ? _userData : null,
          builder: (context, snapshot) {
            return Center(  // Utilisation du widget Center
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center, // Centrer les éléments
                children: [
                  // Avatar et informations utilisateur
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _isLoggedIn
                            ? NetworkImage(snapshot.data?['avatar'] ?? '')
                            : const AssetImage(
                                  'assets/images/default_profile.jpg',
                                )
                                as ImageProvider,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLoggedIn
                        ? (snapshot.data?['name'] ?? 'Invité') // Correction ici
                        : 'Invité',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLoggedIn
                        ? (snapshot.data?['email'] ??
                            'invité@example.com') // Correction ici
                        : 'invité@example.com',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  if (_isLoggedIn) ...[
                    _buildProfileSection(
                      icon: Icons.person,
                      title: 'Informations personnelles',
                      onTap: () => Navigator.pushNamed(context, '/editProfile'),
                    ),
                    _buildProfileSection(
                      icon: Icons.security,
                      title: 'Sécurité',
                      onTap: () => Navigator.pushNamed(context, '/security'),
                    ),
                    _buildProfileSection(
                      icon: Icons.settings,
                      title: 'Paramètres',
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Boutons d'action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child:
                        _isLoggedIn
                            ? ElevatedButton(
                                onPressed: () async {
                                  await ApiService().logout();
                                  if (!context.mounted) return;
                                  Navigator.pushReplacementNamed(context, '/profil');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 50,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Se déconnecter',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        () =>
                                            Navigator.pushNamed(context, '/login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 50,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      'Se Connecter',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  OutlinedButton(
                                    onPressed:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/register',
                                        ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 50,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.deepPurple,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Text(
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
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
