import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchForumPage extends StatefulWidget {
  const SearchForumPage({super.key});

  @override
  State<SearchForumPage> createState() => _SearchForumPageState();
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        hintText: 'Rechercher sujets, questions...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  focusNode.unfocus();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
    );
  }
}


class _SearchForumPageState extends State<SearchForumPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ForumPost> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _searchForum(String query) async {
  if (query.isEmpty) {
    setState(() => _searchResults = []);
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await http.get(
      Uri.https(
        's3-4204.nuage-peda.fr', // Domaine
        '/forum/api/messages', // Chemin
        {'titre': query, 'contenu': query}, // Paramètres de requête
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Vérifiez si la clé 'hydra:member' existe
      if (responseData.containsKey('hydra:member')) {
        final List<dynamic> data = responseData['hydra:member'];
        setState(() {
          _searchResults = data.map((json) => ForumPost.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Format de réponse inattendu';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Erreur serveur (${response.statusCode})';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur de connexion: $e';
      _isLoading = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _SearchBar(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (query) => _searchForum(query),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: ErrorMessage(message: _errorMessage!));
    }

    return RefreshIndicator(
      onRefresh: () => _searchForum(_searchController.text),
      child: CustomScrollView(
        slivers: [
          if (_searchResults.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_searchResults.length} résultat(s) trouvé(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          _searchResults.isNotEmpty
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => PostItem(post: _searchResults[index]),
                    childCount: _searchResults.length,
                  ),
                )
              : SliverFillRemaining(
                  child: EmptyState(searchQuery: _searchController.text),
                ),
        ],
      ),
    );
  }
}

class ForumPost {
  final String title;
  final String content;
  final String author;
  final int comments;
  final DateTime date;
  final String category;
  final int id;

  ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.comments,
    required this.date,
    required this.category,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
  return ForumPost(
    id: json['id'] ?? 0, // Valeur par défaut si 'id' est null
    title: json['titre'] ?? 'Sans titre', // Valeur par défaut si 'titre' est null
    content: json['contenu'] ?? '', // Valeur par défaut si 'contenu' est null
    author: json['envoyer'] ?? 'Anonyme', // Valeur par défaut si 'envoyer' est null
    comments: 0, // Champ facultatif
    date: DateTime.tryParse(json['datePoste'] ?? '') ?? DateTime.now(), // Gestion de date null
    category: 'Général', // Champ facultatif
  );
}
}

class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Erreur de chargement',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
        FilledButton(
          onPressed: () {/* Reload */},
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}

class PostItem extends StatelessWidget {
  final ForumPost post;

  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPost(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(post.category),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Text(
                    '${post.comments} réponses',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPost(BuildContext context) {
    // Navigation vers le détail du post
  }
}

class EmptyState extends StatelessWidget {
  final String searchQuery;

  const EmptyState({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 80,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          searchQuery.isEmpty
              ? 'Commencez à taper pour rechercher'
              : 'Aucun résultat pour "$searchQuery"',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (searchQuery.isNotEmpty)
          Text(
            'Vérifiez l\'orthographe ou essayez d\'autres termes',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
// Les autres composants (_SearchBar, PostItem, EmptyState, ErrorMessage) 
// restent identiques à la version précédente