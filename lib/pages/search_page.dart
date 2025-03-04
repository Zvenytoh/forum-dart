import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Page qui permet de rechercher des posts dans le forum.
class SearchForumPage extends StatefulWidget {
  const SearchForumPage({super.key});

  @override
  State<SearchForumPage> createState() => _SearchForumPageState();
}

/// État de la page de recherche, gère la logique de recherche et l'affichage des résultats.
class _SearchForumPageState extends State<SearchForumPage> {
  // Contrôleur du champ de recherche.
  final TextEditingController _searchController = TextEditingController();
  // FocusNode pour le champ de recherche.
  final FocusNode _searchFocusNode = FocusNode();

  // Liste complète des résultats de la recherche.
  List<ForumPost> _searchResults = [];
  // Indicateur de chargement pendant la requête.
  bool _isLoading = false;
  // Message d'erreur en cas de problème de connexion ou de réponse inattendue.
  String? _errorMessage;
  // Nombre de résultats actuellement affichés.
  int _displayedItemCount = 10;

  /// Effectue la recherche sur le forum en fonction de la requête saisie.
  Future<void> _searchForum(String query) async {
    // Si la requête est vide, on réinitialise les résultats et le compteur d'affichage.
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _displayedItemCount = 10;
      });
      return;
    }

    // Mise àforum-dart.git forum-dartgit-2884883 Setting up workspace Initializing environment Building environmentFinalizing jour de l'état : lancement du chargement, réinitialisation du message d'erreur
    // et remise à zéro du nombre d'éléments affichés.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _displayedItemCount = 10;
    });

    try {
      // Construction de l'URI avec les paramètres de recherche.
      final uri = Uri.https(
        's3-4204.nuage-peda.fr', // Domaine
        '/forum/api/messages',   // Chemin
        {
          'titre': query,
          'contenu': query,
        },
      );

      // Envoi de la requête HTTP GET.
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Décodage de la réponse JSON.
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Vérification de la présence de la clé attendue.
        if (responseData.containsKey('hydra:member')) {
          final List<dynamic> data = responseData['hydra:member'];
          setState(() {
            // Transformation des données JSON en objets ForumPost.
            _searchResults =
                data.map((json) => ForumPost.fromJson(json)).toList();
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
  void dispose() {
    // Libération des ressources des contrôleurs et du FocusNode.
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar avec le champ de recherche.
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

  /// Construit le corps de la page en fonction de l'état actuel (chargement, erreur, résultats).
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: ErrorMessage(message: _errorMessage!));
    }

    // Limitation des résultats affichés en fonction de _displayedItemCount.
    final int currentCount = _displayedItemCount > _searchResults.length
        ? _searchResults.length
        : _displayedItemCount;
    final List<ForumPost> displayedResults =
        _searchResults.take(currentCount).toList();

    return RefreshIndicator(
      onRefresh: () => _searchForum(_searchController.text),
      child: CustomScrollView(
        slivers: [
          if (_searchResults.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_searchResults.length} résultat(s) trouvé(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          if (_searchResults.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    PostItem(post: displayedResults[index]),
                childCount: displayedResults.length,
              ),
            ),
          // Bouton "Afficher plus" s'il reste des cards à afficher.
          if (_searchResults.length > _displayedItemCount)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Augmente le nombre d'éléments affichés de 10,
                      // sans dépasser le nombre total de résultats.
                      _displayedItemCount = (_displayedItemCount + 10) >
                              _searchResults.length
                          ? _searchResults.length
                          : _displayedItemCount + 10;
                    });
                  },
                  child: const Text('Afficher plus'),
                ),
              ),
            ),
          // Affichage de l'état vide si aucun résultat n'est disponible.
          if (_searchResults.isEmpty)
            SliverFillRemaining(
              child: EmptyState(searchQuery: _searchController.text),
            ),
        ],
      ),
    );
  }
}

/// Widget représentant la barre de recherche.
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
        // Fond rempli pour une meilleure visibilité.
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        hintText: 'Rechercher sujets, questions...',
        prefixIcon: const Icon(Icons.search_rounded),
        // Affichage d'un bouton pour effacer le champ uniquement si du texte est présent.
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

/// Modèle représentant un post du forum.
class ForumPost {
  final int id;
  final String title;
  final String content;
  final String author;
  final int comments;
  final DateTime date;
  final String category;

  ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.comments,
    required this.date,
    required this.category,
  });

  /// Crée un objet [ForumPost] à partir d'une map JSON.
  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] ?? 0, // Valeur par défaut si 'id' est null.
      title: json['titre'] ?? 'Sans titre',
      content: json['contenu'] ?? '',
      author: json['envoyer'] ?? 'Anonyme',
      comments: 0, // Champ facultatif avec valeur par défaut.
      date: DateTime.tryParse(json['datePoste'] ?? '') ?? DateTime.now(),
      category: 'Général', // Champ facultatif avec valeur par défaut.
    );
  }
}

/// Widget affichant un message d'erreur avec une icône et un bouton de réessai.
class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 60, color: Colors.red),
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
          onPressed: () {
            // TODO: Implémenter la logique de réessai.
          },
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}

/// Widget qui affiche un post dans une carte.
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
              // Ligne affichant la catégorie et le nombre de réponses.
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
              // Titre du post.
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              // Aperçu du contenu du post.
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigation vers le détail du post.
  void _navigateToPost(BuildContext context) {
    // TODO: Implémenter la navigation vers le détail du post.
  }
}

/// Widget affiché lorsqu'aucun résultat n'est trouvé.
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
