import 'package:flutter/material.dart';

class MessageCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final Future<void> Function(int voteType) onVote;

  const MessageCard({
    super.key,
    required this.message,
    required this.onVote,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  late int _currentVote; // 1 pour upvote, -1 pour downvote, 0 pour aucun vote
  late int _score;

  @override
  void initState() {
    super.initState();
    _score = widget.message['score'] ?? 0;
    _currentVote = widget.message['userVote'] ?? 0; // À récupérer du backend
  }

  Future<void> _handleVote(int newVoteType) async {
    try {
      await widget.onVote(newVoteType); // Appeler la fonction de vote côté serveur
      setState(() {
        if (_currentVote == newVoteType) {
          // Annuler le vote si l'utilisateur clique à nouveau sur le même bouton
          _score -= newVoteType;
          _currentVote = 0;
        } else {
          // Mettre à jour le score et le vote actuel
          _score += newVoteType - _currentVote;
          _currentVote = newVoteType;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              widget.message['titre'] ?? 'Sans titre',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            subtitle: Text(
              widget.message['contenu'] ?? 'Pas de contenu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.deepPurple,
            ),
            onTap: () => _showMessageDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 12.0, right: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bloc de vote (flèche gauche pour upvote, score, flèche droite pour downvote)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                        size: 32,
                        color: _currentVote == 1 ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _handleVote(1),
                    ),
                    // Affiche le score uniquement s'il est strictement supérieur à 1
                    if (_score >= 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '$_score',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_downward,
                        size: 32,
                        color: _currentVote == -1 ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _handleVote(-1),
                    ),
                  ],
                ),
                Text(
                  'Posté le ${_formatDate(widget.message['date_poste'])}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.message['repondre']?['titre']?.toString() ?? 'Aucune réponse',
        ),
        content: Text(
          widget.message['repondre']?['contenu']?.toString() ?? 'Aucune réponse',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';
    final date = DateTime.tryParse(dateString);
    return date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'Date invalide';
  }
}
