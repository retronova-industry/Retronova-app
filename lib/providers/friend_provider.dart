// lib/providers/friend_provider.dart
import 'package:flutter/foundation.dart';
import '../models/friend_model.dart';
import '../models/user_search_model.dart';
import '../services/friend_service.dart';

class FriendProvider with ChangeNotifier {
  final FriendService _friendService = FriendService();

  List<FriendModel> _friends = [];
  List<FriendshipModel> _friendRequests = [];
  List<UserSearchResult> _searchResults =
      []; // CHANGÉ: UserSearchResult pour la recherche
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  // Getters
  List<FriendModel> get friends => _friends;
  List<FriendshipModel> get friendRequests => _friendRequests;
  List<UserSearchResult> get searchResults =>
      _searchResults; // CHANGÉ: UserSearchResult
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  // Charger les amis
  Future<void> loadFriends() async {
    try {
      _setLoading(true);
      _clearError();

      _friends = await _friendService.getFriends();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Charger les demandes d'amitié
  Future<void> loadFriendRequests() async {
    try {
      _setLoading(true);
      _clearError();

      _friendRequests = await _friendService.getFriendRequests();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Rechercher des utilisateurs
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _setSearching(true);
      _clearError();

      print('FriendProvider: Searching for "$query"'); // Debug
      _searchResults = await _friendService.searchUsers(query);
      print('FriendProvider: Found ${_searchResults.length} users'); // Debug
      notifyListeners();
    } catch (e) {
      print('FriendProvider error: $e'); // Debug
      _setError(e.toString());
    } finally {
      _setSearching(false);
    }
  }

  // Envoyer une demande d'amitié
  Future<bool> sendFriendRequest(int userId) async {
    try {
      _clearError();
      await _friendService.sendFriendRequest(userId);

      // Supprimer l'utilisateur des résultats de recherche
      _searchResults.removeWhere((user) => user.id == userId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Accepter une demande d'amitié
  Future<bool> acceptFriendRequest(int friendshipId) async {
    try {
      _clearError();
      await _friendService.acceptFriendRequest(friendshipId);

      // Supprimer la demande de la liste et rafraîchir les amis
      _friendRequests.removeWhere((request) => request.id == friendshipId);
      await loadFriends();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Rejeter une demande d'amitié
  Future<bool> rejectFriendRequest(int friendshipId) async {
    try {
      _clearError();
      await _friendService.rejectFriendRequest(friendshipId);

      // Supprimer la demande de la liste
      _friendRequests.removeWhere((request) => request.id == friendshipId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Supprimer un ami
  Future<bool> removeFriend(int userId) async {
    try {
      _clearError();
      await _friendService.removeFriend(userId);

      // Supprimer l'ami de la liste
      _friends.removeWhere((friend) => friend.id == userId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Vider les résultats de recherche
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Méthodes utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
