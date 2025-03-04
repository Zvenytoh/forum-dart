import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/widgets/bottomNavBar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  bool _isLoggedIn = false;
  late Future<Map<String, dynamic>> _userData;
  late Future<List<Map<String, dynamic>>> _userMessages;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 2; // Index pour la BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    // Initialisation des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _checkLoginStatus() {
    setState(() {
      _isLoggedIn = true; // Mettez à jour selon l'état réel
      _userData = ApiService().getUserData();
      _userMessages = ApiService().getUserMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _isLoggedIn ? _userData : null,
        builder: (context, userSnapshot) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        _buildProfileAvatar(userSnapshot),
                        _buildProfileInfo(userSnapshot),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: _isLoggedIn
                                  ? _buildLoggedInContent(context)
                                  : _buildGuestContent(context),
                            ),
                          ),
                        ),
                        if (_isLoggedIn) _buildStatisticsSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileAvatar(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(top: 20),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 56,
          backgroundImage: _isLoggedIn && snapshot.hasData
              ? NetworkImage(snapshot.data?['avatar'] ?? '')
              : const AssetImage('assets/images/default_profile.jpg')
                  as ImageProvider<Object>,
        ),
      ),
    );
  }

  Widget _buildProfileInfo(AsyncSnapshot<Map<String, dynamic>> snapshot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            _isLoggedIn ? (snapshot.data?['prenom'] ?? 'Invité') : 'Invité',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isLoggedIn
                ? (snapshot.data?['email'] ?? 'invité@example.com')
                : 'invité@example.com',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent(BuildContext context) {
    return Column(
      children: [
        _buildProfileItem(
          icon: Icons.person_outline,
          title: 'Modifier le profil',
          onTap: () => Navigator.pushNamed(context, '/edit-profile'),
        ),
        const Divider(height: 30),
        _buildProfileItem(
          icon: Icons.settings_outlined,
          title: 'Paramètres',
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
        const Divider(height: 30),
        _buildProfileItem(
          icon: Icons.exit_to_app,
          title: 'Déconnexion',
          color: Colors.red,
          onTap: () async {
            await ApiService().logout();
            if (Navigator.of(context).mounted) {
              Navigator.pushReplacementNamed(context, '/profil');
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    return Column(
      children: [
        AnimatedButton(
          text: 'Connexion',
          icon: Icons.login,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
        const SizedBox(height: 12),
        AnimatedButton(
          text: 'Inscription',
          icon: Icons.person_add,
          isOutlined: true,
          onPressed: () => Navigator.pushNamed(context, '/register'),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('12', 'Messages'),
            _buildStatCard('89', 'Followers'),
            _buildStatCard('34', 'Abonnements'),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    Color color = Colors.deepPurple,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildStatCard(String value, String label) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isOutlined;
  final VoidCallback onPressed;

  const AnimatedButton({
    required this.text,
    required this.icon,
    this.isOutlined = false,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton.icon(
              icon: Icon(icon, size: 20),
              label: Text(text),
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Colors.deepPurple, width: 2),
              ),
            )
          : ElevatedButton.icon(
              icon: Icon(icon, size: 20),
              label: Text(text),
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}