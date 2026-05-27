// lib/presentation/screens/friends/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:retronova_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/friend_provider.dart';
import '../../../models/friend_model.dart';
import '../../../models/user_search_model.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données initiales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final friendProvider = Provider.of<FriendProvider>(
        context,
        listen: false,
      );
      friendProvider.loadFriends();
      friendProvider.loadFriendRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showRemoveFriendDialog(FriendModel friend) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer ami'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${friend.fullName} de vos amis ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final friendProvider = Provider.of<FriendProvider>(
                  context,
                  listen: false,
                );
                final success = await friendProvider.removeFriend(friend.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Ami supprimé avec succès'
                            : friendProvider.errorMessage ??
                                  'Erreur lors de la suppression',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.friendsLabel),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes amis', icon: Icon(Icons.people)),
            Tab(text: 'Demandes', icon: Icon(Icons.person_add)),
            Tab(text: 'Rechercher', icon: Icon(Icons.search)),
          ],
        ),
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsTab(friendProvider),
              _buildRequestsTab(friendProvider),
              _buildSearchTab(friendProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendsTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun ami pour le moment',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Recherchez des utilisateurs dans l\'onglet Rechercher',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendProvider.loadFriends(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: friendProvider.friends.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final friend = friendProvider.friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildFriendCard(FriendModel friend) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            friend.pseudo.isNotEmpty ? friend.pseudo[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          friend.pseudo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '@${friend.pseudo}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              _showRemoveFriendDialog(friend);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(FriendProvider friendProvider) {
    if (friendProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.friendRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune demande d\'amitié',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendProvider.loadFriendRequests(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: friendProvider.friendRequests.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final request = friendProvider.friendRequests[index];
          return _buildRequestCard(request, friendProvider);
        },
      ),
    );
  }

  Widget _buildRequestCard(
    FriendshipModel request,
    FriendProvider friendProvider,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Text(
            request.requester.pseudo.isNotEmpty
                ? request.requester.pseudo[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.orange,
            ),
          ),
        ),
        title: Text(
          request.requester.pseudo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '@${request.requester.pseudo}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () async {
                final success = await friendProvider.acceptFriendRequest(
                  request.id,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Demande acceptée !'
                            : friendProvider.errorMessage ?? 'Erreur',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, color: Colors.green),
              tooltip: 'Accepter',
            ),
            IconButton(
              onPressed: () async {
                final success = await friendProvider.rejectFriendRequest(
                  request.id,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Demande rejetée'
                            : friendProvider.errorMessage ?? 'Erreur',
                      ),
                      backgroundColor: success ? Colors.orange : Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Rejeter',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab(FriendProvider friendProvider) {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher des utilisateurs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        friendProvider.clearSearchResults();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                friendProvider.searchUsers(value);
              } else {
                friendProvider.clearSearchResults();
              }
            },
          ),
        ),

        // Résultats de recherche
        Expanded(child: _buildSearchResults(friendProvider)),
      ],
    );
  }

  Widget _buildSearchResults(FriendProvider friendProvider) {
    if (friendProvider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tapez au moins 2 caractères pour rechercher',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (friendProvider.searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: friendProvider.searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = friendProvider.searchResults[index];
        return _buildSearchResultCard(user, friendProvider);
      },
    );
  }

  Widget _buildSearchResultCard(
    UserSearchResult user,
    FriendProvider friendProvider,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(
            user.pseudo.isNotEmpty ? user.pseudo[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          user.pseudo, // UserSearchResult a une propriété fullName
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '@${user.pseudo}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () async {
            final success = await friendProvider.sendFriendRequest(user.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Demande d\'amitié envoyée !'
                        : friendProvider.errorMessage ?? 'Erreur',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }
}
