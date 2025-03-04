import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late Future<List<Map<String, dynamic>>> _userMessages;
  bool _isLoggedIn = false;

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
              print('user messages $_userMessages');
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

  String _formatDate(String isoDate) {
    try {
      return DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(isoDate));
    } catch (e) {
      return 'Date inconnue';
    }
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    Navigator.popAndPushNamed(context, ['/', '/forum', '/profil'][index]);
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.forum, color: Colors.deepPurple),
        title: Text(
          message['titre'] ?? 'Sans titre',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['contenu'] ?? 'Pas de contenu',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (message['datePoste'] != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(message['datePoste']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                if (message['score'] != null)
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.thumb_up, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        message['score'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesSection(List<Map<String, dynamic>> messages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Mes Contributions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        if (messages.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Center(
              child: Text(
                'Aucune publication pour le moment',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildMessageItem(messages[index]),
          ),
      ],
    );
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
          builder: (context, userSnapshot) {
            return Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      _isLoggedIn && userSnapshot.hasData
                          ? NetworkImage(userSnapshot.data?['avatar'] ?? '')
                          : const AssetImage(
                                'assets/images/default_profile.jpg',
                              )
                              as ImageProvider,
                ),
                const SizedBox(height: 20),
                Text(
                  _isLoggedIn
                      ? (userSnapshot.data?['prenom'] ?? 'Invité')
                      : 'Invité',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoggedIn
                      ? (userSnapshot.data?['email'] ?? 'invité@example.com')
                      : 'invité@example.com',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (_isLoggedIn)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _userMessages,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      return _buildMessagesSection(snapshot.data ?? []);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Déconnexion',
                              style: TextStyle(
                                fontSize: 16,
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
                                    horizontal: 40,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Connexion',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 16,
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
                                  'Inscription',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.deepPurple,
                                  ),
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
