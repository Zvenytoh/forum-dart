import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:myapp/widgets/message_card.dart';
import 'package:myapp/widgets/bottomNavBar.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentIndex = 2; // Index adapté si vous avez une navigation inférieure

  @override
  void initState() {
    super.initState();
    _loadTrendingMessages();
  }

  Future<void> _loadTrendingMessages() async {
    try {
      final messages = await _apiService.fetchTrendingMessages();
      if (mounted) {
        setState(() {
          _messages =
              messages; // Les messages sont maintenant dans la bonne structure
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur lors du chargement des messages tendances";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVote(int messageId, int voteType) async {
    // Récupération du score initial pour rollback en cas d'erreur
    final originalScore =
        _messages.firstWhere((m) => m['id'] == messageId)['score'];
    // Mise à jour optimiste du score
    setState(() {
      _messages.firstWhere((m) => m['id'] == messageId)['score'] += voteType;
    });

    try {
      await _apiService.vote(messageId, voteType);
    } catch (e) {
      // Rollback en cas d'erreur
      setState(() {
        _messages.firstWhere((m) => m['id'] == messageId)['score'] =
            originalScore;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du vote: ${e.toString()}')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.popAndPushNamed(context, '/');
        break;
      case 1:
        Navigator.popAndPushNamed(context, '/forum');
        break;
      case 2:
        Navigator.popAndPushNamed(context, '/trending');
        break;
      case 3:
        Navigator.popAndPushNamed(context, '/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrendingMessages,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withOpacity(0.8),
              Colors.indigo.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : _errorMessage.isNotEmpty
                ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadTrendingMessages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageCard(
                        message: message,
                        onVote:
                            (voteType) => _handleVote(message['id'], voteType),
                      );
                    },
                  ),
                ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
