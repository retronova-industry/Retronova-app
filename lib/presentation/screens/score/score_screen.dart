// lib/presentation/screens/score/score_screen.dart
import 'package:flutter/material.dart';
import 'package:retronova_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/score_provider.dart';
import '../../../providers/arcade_provider.dart';
import '../../../models/score_model.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
      final arcadeProvider = Provider.of<ArcadeProvider>(
        context,
        listen: false,
      );

      // Passer les données des jeux/bornes au ScoreProvider
      scoreProvider.setAvailableGames(arcadeProvider.games);
      scoreProvider.setAvailableArcades(arcadeProvider.arcades);

      // Charger les scores et statistiques
      scoreProvider.loadScores();
      scoreProvider.loadMyStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scoreLabel),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scoreboards', icon: Icon(Icons.leaderboard)),
            Tab(text: 'Mes Stats', icon: Icon(Icons.person)),
            Tab(text: 'Récents', icon: Icon(Icons.access_time)),
          ],
        ),
      ),
      body: Consumer<ScoreProvider>(
        builder: (context, scoreProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildScoreboardTab(scoreProvider),
              _buildMyStatsTab(scoreProvider),
              _buildRecentScoresTab(scoreProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScoreboardTab(ScoreProvider scoreProvider) {
    return Column(
      children: [
        // Filtres
        _buildFiltersSection(scoreProvider),

        // Liste des scores
        Expanded(child: _buildScoresList(scoreProvider)),
      ],
    );
  }

  Widget _buildFiltersSection(ScoreProvider scoreProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filtres',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (scoreProvider.hasActiveFilters)
                TextButton.icon(
                  onPressed: () => scoreProvider.clearAllFilters(),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Tout effacer'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Ligne de filtres
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Filtre par jeu
              _buildGameFilter(scoreProvider),

              // Filtre par borne
              _buildArcadeFilter(scoreProvider),

              // Filtre amis seulement
              _buildFriendsOnlyFilter(scoreProvider),

              // Filtre solo seulement
              _buildSinglePlayerFilter(scoreProvider),
            ],
          ),

          // Indicateur de filtres actifs
          if (scoreProvider.activeFilterCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${scoreProvider.activeFilterCount} filtre${scoreProvider.activeFilterCount > 1 ? 's' : ''} actif${scoreProvider.activeFilterCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameFilter(ScoreProvider scoreProvider) {
    return PopupMenuButton<int?>(
      onSelected: (gameId) => scoreProvider.setGameFilter(gameId),
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(value: null, child: Text('Tous les jeux')),
        const PopupMenuDivider(),
        ...scoreProvider.availableGames.map(
          (game) => PopupMenuItem<int?>(value: game.id, child: Text(game.nom)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: scoreProvider.selectedGameId != null
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: scoreProvider.selectedGameId != null
              ? AppColors.primary.withOpacity(0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videogame_asset,
              size: 16,
              color: scoreProvider.selectedGameId != null
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              scoreProvider.selectedGameId != null
                  ? scoreProvider
                            .findGameById(scoreProvider.selectedGameId!)
                            ?.nom ??
                        'Jeu inconnu'
                  : 'Jeu',
              style: TextStyle(
                fontSize: 14,
                color: scoreProvider.selectedGameId != null
                    ? AppColors.primary
                    : Colors.grey[600],
                fontWeight: scoreProvider.selectedGameId != null
                    ? FontWeight.w800
                    : FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: scoreProvider.selectedGameId != null
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArcadeFilter(ScoreProvider scoreProvider) {
    return PopupMenuButton<int?>(
      onSelected: (arcadeId) => scoreProvider.setArcadeFilter(arcadeId),
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(
          value: null,
          child: Text('Toutes les bornes'),
        ),
        const PopupMenuDivider(),
        ...scoreProvider.availableArcades.map(
          (arcade) =>
              PopupMenuItem<int?>(value: arcade.id, child: Text(arcade.nom)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: scoreProvider.selectedArcadeId != null
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: scoreProvider.selectedArcadeId != null
              ? AppColors.primary.withOpacity(0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports,
              size: 16,
              color: scoreProvider.selectedArcadeId != null
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              scoreProvider.selectedArcadeId != null
                  ? scoreProvider
                            .findArcadeById(scoreProvider.selectedArcadeId!)
                            ?.nom ??
                        'Borne inconnue'
                  : 'Borne',
              style: TextStyle(
                fontSize: 14,
                color: scoreProvider.selectedArcadeId != null
                    ? AppColors.primary
                    : Colors.grey[600],
                fontWeight: scoreProvider.selectedArcadeId != null
                    ? FontWeight.w800
                    : FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: scoreProvider.selectedArcadeId != null
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsOnlyFilter(ScoreProvider scoreProvider) {
    return GestureDetector(
      onTap: () =>
          scoreProvider.setFriendsOnlyFilter(!scoreProvider.friendsOnly),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: scoreProvider.friendsOnly
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: scoreProvider.friendsOnly
              ? AppColors.primary.withOpacity(0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scoreProvider.friendsOnly ? Icons.people : Icons.people_outline,
              size: 16,
              color: scoreProvider.friendsOnly
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Amis',
              style: TextStyle(
                fontSize: 14,
                color: scoreProvider.friendsOnly
                    ? AppColors.primary
                    : Colors.grey[600],
                fontWeight: scoreProvider.friendsOnly
                    ? FontWeight.w800
                    : FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePlayerFilter(ScoreProvider scoreProvider) {
    return GestureDetector(
      onTap: () => scoreProvider.setSinglePlayerOnlyFilter(
        !scoreProvider.singlePlayerOnly,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: scoreProvider.singlePlayerOnly
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: scoreProvider.singlePlayerOnly
              ? AppColors.primary.withOpacity(0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scoreProvider.singlePlayerOnly
                  ? Icons.person
                  : Icons.person_outline,
              size: 16,
              color: scoreProvider.singlePlayerOnly
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Solo',
              style: TextStyle(
                fontSize: 14,
                color: scoreProvider.singlePlayerOnly
                    ? AppColors.primary
                    : Colors.grey[600],
                fontWeight: scoreProvider.singlePlayerOnly
                    ? FontWeight.w800
                    : FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresList(ScoreProvider scoreProvider) {
    if (scoreProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des scores...'),
          ],
        ),
      );
    }

    if (scoreProvider.scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              scoreProvider.hasActiveFilters
                  ? Icons.search_off
                  : Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              scoreProvider.hasActiveFilters
                  ? 'Aucun score trouvé avec ces filtres'
                  : 'Aucun score disponible',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              scoreProvider.hasActiveFilters
                  ? 'Essayez de modifier vos filtres'
                  : 'Les scores des parties apparaîtront ici',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (scoreProvider.hasActiveFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => scoreProvider.clearAllFilters(),
                child: const Text('Effacer les filtres'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => scoreProvider.loadScores(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scoreProvider.scores.length,
        itemBuilder: (context, index) {
          final score = scoreProvider.scores[index];
          return _buildScoreCard(score, index + 1);
        },
      ),
    );
  }

  Widget _buildScoreCard(ScoreModel score, int position) {
    Color positionColor;
    IconData positionIcon;

    if (position == 1) {
      positionColor = Colors.amber;
      positionIcon = Icons.emoji_events;
    } else if (position == 2) {
      positionColor = Colors.grey;
      positionIcon = Icons.emoji_events;
    } else if (position == 3) {
      positionColor = Colors.brown;
      positionIcon = Icons.emoji_events;
    } else {
      positionColor = AppColors.primary;
      positionIcon = Icons.sports_score;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec position et jeu
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: positionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: position <= 3
                        ? Icon(positionIcon, color: positionColor, size: 16)
                        : Text(
                            '$position',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: positionColor,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.gameName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        score.arcadeName,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: score.isSinglePlayer
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        score.isSinglePlayer ? Icons.person : Icons.people,
                        size: 14,
                        color: score.isSinglePlayer
                            ? Colors.blue
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        score.isSinglePlayer ? 'Solo' : 'Multi',
                        style: TextStyle(
                          fontSize: 12,
                          color: score.isSinglePlayer
                              ? Colors.blue
                              : Colors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Joueurs et score
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joueur${score.isSinglePlayer ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score.playersText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.scoreText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Résultat pour les jeux multijoueur
            if (!score.isSinglePlayer && score.winnerPseudo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  score.resultText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(score.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStatsTab(ScoreProvider scoreProvider) {
    if (scoreProvider.isLoadingStats) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des statistiques...'),
          ],
        ),
      );
    }

    if (scoreProvider.myStats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune statistique disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jouez des parties pour voir vos statistiques',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => scoreProvider.loadMyStats(),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    final stats = scoreProvider.myStats!;

    return RefreshIndicator(
      onRefresh: () => scoreProvider.loadMyStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de résumé
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mes Statistiques',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Parties jouées',
                            '${stats.totalGames}',
                            Icons.sports_esports,
                            AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Taux de victoire',
                            '${stats.winRate.toStringAsFixed(1)}%',
                            Icons.emoji_events,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistiques détaillées
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Répartition des parties',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildDetailedStatRow(
                      'Parties solo',
                      '${stats.soloGames}',
                      Icons.person,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    _buildDetailedStatRow(
                      'Parties multijoueur',
                      '${stats.multiplayerGames}',
                      Icons.people,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            if (stats.multiplayerGames > 0) ...[
              const SizedBox(height: 16),

              // Statistiques multijoueur
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performances multijoueur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Victoires',
                              '${stats.wins}',
                              Icons.emoji_events,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Défaites',
                              '${stats.losses}',
                              Icons.close,
                              Colors.red,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Égalités',
                              '${stats.draws}',
                              Icons.remove,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Bouton pour actualiser
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => scoreProvider.loadMyStats(),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser les statistiques'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailedStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScoresTab(ScoreProvider scoreProvider) {
    final recentScores = scoreProvider.recentScores;

    if (scoreProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des scores récents...'),
          ],
        ),
      );
    }

    if (recentScores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun score récent',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les scores des dernières 24h apparaîtront ici',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => scoreProvider.loadScores(),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => scoreProvider.loadScores(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recentScores.length,
        itemBuilder: (context, index) {
          final score = recentScores[index];
          return _buildRecentScoreCard(score);
        },
      ),
    );
  }

  Widget _buildRecentScoreCard(ScoreModel score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.gameName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        score.arcadeName,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTimeAgoColor(score.createdAt).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTimeAgo(score.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTimeAgoColor(score.createdAt),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    score.playersText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  score.scoreText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            if (!score.isSinglePlayer && score.winnerPseudo != null) ...[
              const SizedBox(height: 8),
              Text(
                score.resultText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche',
      ];
      return '${weekdays[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else {
      return 'il y a ${difference.inDays}j';
    }
  }

  Color _getTimeAgoColor(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return Colors.green; // Très récent
    } else if (difference.inHours < 6) {
      return Colors.orange; // Récent
    } else {
      return Colors.grey; // Plus ancien
    }
  }
}
