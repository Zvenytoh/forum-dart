import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/widgets/bottomNavBar.dart';
import 'package:myapp/widgets/buildProfilWidget.dart';

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
    _userMessages = Future.value([]);
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuthenticated = await ApiService().checkAuthentication();
    if (isAuthenticated) {
      _userData = ApiService()
          .getUserData()
          .then((user) {
            final userId = user['id']?.toString();
            if (userId != null) {
              _userMessages = ApiService().fetchUserMessages();
            } else {
              _userMessages = Future.error('ID utilisateur introuvable');
            }
            return user;
          })
          .catchError((error) {
            _userMessages = Future.error(error);
            throw error;
          });
    } else {
      _userMessages = Future.value([]);
    }
    setState(() => _isLoggedIn = isAuthenticated);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    Navigator.popAndPushNamed(context, ['/', '/forum', '/profil'][index]);
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.forum, color: Colors.deepPurple),
        ),
        title: Text(
          message['titre'] ?? 'Sans titre',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              message['contenu'] ?? 'Pas de contenu',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  Icons.access_time_outlined,
                  _formatDate(message['datePoste']),
                ),
                const SizedBox(width: 20),
                _buildInfoItem(
                  Icons.thumb_up_outlined,
                  message['score']?.toString() ?? '0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      // Parse la chaîne de date en objet DateTime
      final DateTime date = DateTime.parse(dateString);
      // Formate la date selon le format souhaité
      return DateFormat('dd/MM/yyyy à HH:mm').format(date);
    } catch (e) {
      // En cas d'erreur de parsing, retourne une chaîne par défaut
      return 'Date inconnue';
    }
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesSection(List<Map<String, dynamic>> messages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Mes Contributions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
        ),
        if (messages.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Center(
              child: Text(
                'Aucune publication pour le moment',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildMessageItem(messages[index]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _isLoggedIn ? _userData : null,
          builder: (context, userSnapshot) {
            return Column(
              children: [
                
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.deepPurple.withOpacity(0.3),
                  ),
                  backgroundImage:
                      _isLoggedIn && userSnapshot.hasData
                          ? NetworkImage(userSnapshot.data?['avatar'] ?? '')
                          : const AssetImage(
                                'assets/images/default_profile.jpg',
                              )
                              as ImageProvider,
                ),
                const SizedBox(height: 24),
                Text(
                  _isLoggedIn
                      ? (userSnapshot.data?['prenom'] ?? 'Invité')
                      : 'Invité',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoggedIn
                      ? (userSnapshot.data?['email'] ?? 'invité@example.com')
                      : 'invité@example.com',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoggedIn)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _userMessages,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Erreur : ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return _buildMessagesSection(snapshot.data ?? []);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child:
                      _isLoggedIn
                          ? ElevatedButton(
                            onPressed: () async {
                              await ApiService().logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/profil',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.red[300]!),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 20),
                                SizedBox(width: 8),
                                Text('Déconnexion'),
                              ],
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
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login, size: 20),
                                    SizedBox(width: 8),
                                    Text('Connexion'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/register',
                                    ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Colors.deepPurple,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add, size: 20),
                                    SizedBox(width: 8),
                                    Text('Inscription'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
              ],
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
      child:
          isOutlined
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
