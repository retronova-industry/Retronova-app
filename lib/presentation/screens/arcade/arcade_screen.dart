// lib/presentation/screens/arcade/arcade_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/arcade_provider.dart';
import '../../../providers/ticket_provider.dart';
import '../../../models/arcade_model.dart';
import '../../../models/game_model.dart';
import '../../../models/reservation_model.dart';
import '../../widgets/ticket_balance_widget.dart';
import 'arcade_detail_screen.dart';
import 'reservation_screen.dart';

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arcadeProvider = Provider.of<ArcadeProvider>(
        context,
        listen: false,
      );
      arcadeProvider.loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.arcadeLabel),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: CompactTicketBalance()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bornes', icon: Icon(Icons.sports_esports)),
            Tab(text: 'Réservations', icon: Icon(Icons.event_seat)),
            Tab(text: 'Jeux', icon: Icon(Icons.videogame_asset)),
          ],
        ),
      ),
      body: Consumer<ArcadeProvider>(
        builder: (context, arcadeProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildArcadesTab(arcadeProvider),
              _buildReservationsTab(arcadeProvider),
              _buildGamesTab(arcadeProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArcadesTab(ArcadeProvider arcadeProvider) {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher des bornes ou jeux...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        arcadeProvider.clearSearch();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              arcadeProvider.searchArcades(value);
            },
          ),
        ),

        // Liste des bornes
        Expanded(child: _buildArcadesList(arcadeProvider)),
      ],
    );
  }

  Widget _buildArcadesList(ArcadeProvider arcadeProvider) {
    if (arcadeProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des bornes...'),
          ],
        ),
      );
    }

    if (arcadeProvider.arcades.isEmpty &&
        arcadeProvider.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucune borne trouvée pour "${arcadeProvider.searchQuery}"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                arcadeProvider.clearSearch();
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ),
      );
    }

    if (arcadeProvider.arcades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_esports, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune borne d\'arcade disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => arcadeProvider.loadArcades(),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => arcadeProvider.loadArcades(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: arcadeProvider.arcades.length,
        itemBuilder: (context, index) {
          final arcade = arcadeProvider.arcades[index];
          return _buildArcadeCard(arcade);
        },
      ),
    );
  }

  Widget _buildArcadeCard(ArcadeModel arcade) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ArcadeDetailScreen(arcade: arcade),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      arcade.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          arcade.formattedDistance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Localisation
              Row(
                children: [
                  Icon(Icons.place, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      arcade.localisation,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),

              if (arcade.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  arcade.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Jeux disponibles
              if (arcade.games.isNotEmpty) ...[
                const Text(
                  'Jeux disponibles :',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ...arcade.games.take(3).map((game) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          game.nom,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    if (arcade.games.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${arcade.games.length - 3}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ArcadeDetailScreen(arcade: arcade),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Détails'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: arcade.games.isNotEmpty
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReservationScreen(arcade: arcade),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.event_seat, size: 18),
                    label: const Text('Réserver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsTab(ArcadeProvider arcadeProvider) {
    if (arcadeProvider.isLoadingReservations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des réservations...'),
          ],
        ),
      );
    }

    if (arcadeProvider.myReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_seat, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune réservation',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vos réservations de parties apparaîtront ici',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Voir les bornes'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => arcadeProvider.loadMyReservations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: arcadeProvider.myReservations.length,
        itemBuilder: (context, index) {
          final reservation = arcadeProvider.myReservations[index];
          return _buildReservationCard(reservation, arcadeProvider);
        },
      ),
    );
  }

  Widget _buildReservationCard(
    ReservationModel reservation,
    ArcadeProvider arcadeProvider,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (reservation.status) {
      case ReservationStatus.waiting:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case ReservationStatus.playing:
        statusColor = Colors.green;
        statusIcon = Icons.play_circle;
        break;
      case ReservationStatus.completed:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case ReservationStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.gameName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        reservation.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Informations de la réservation
            _buildReservationInfo(
              'Borne',
              reservation.arcadeName,
              Icons.sports_esports,
            ),
            _buildReservationInfo(
              'Joueurs',
              reservation.playersText,
              Icons.people,
            ),

            if (reservation.isWaiting && reservation.positionInQueue != null)
              _buildReservationInfo(
                'Position en file',
                '${reservation.positionInQueue}e',
                Icons.queue,
              ),

            if (reservation.isWaiting || reservation.isPlaying)
              _buildReservationInfo(
                'Code de déverrouillage',
                reservation.unlockCode,
                Icons.lock_open,
              ),

            _buildReservationInfo(
              'Tickets utilisés',
              '${reservation.ticketsUsed}',
              Icons.confirmation_number,
            ),

            const SizedBox(height: 12),

            // Actions
            if (reservation.canBeCancelled) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCancelReservationDialog(
                      reservation,
                      arcadeProvider,
                    ),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (reservation.isWaiting)
                    TextButton.icon(
                      onPressed: () =>
                          arcadeProvider.refreshReservation(reservation.id),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReservationInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesTab(ArcadeProvider arcadeProvider) {
    if (arcadeProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des jeux...'),
          ],
        ),
      );
    }

    if (arcadeProvider.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videogame_asset, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun jeu disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => arcadeProvider.loadGames(),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => arcadeProvider.loadGames(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: arcadeProvider.games.length,
        itemBuilder: (context, index) {
          final game = arcadeProvider.games[index];
          return _buildGameCard(game, arcadeProvider);
        },
      ),
    );
  }

  Widget _buildGameCard(GameModel game, ArcadeProvider arcadeProvider) {
    final availableArcades = arcadeProvider.getArcadesByGame(game.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du jeu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    game.nom,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 14,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.ticketCost}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (game.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                game.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],

            const SizedBox(height: 12),

            // Informations du jeu
            Row(
              children: [
                _buildGameInfo(game.playersDescription, Icons.people),
                const SizedBox(width: 16),
                _buildGameInfo(
                  '${availableArcades.length} borne${availableArcades.length > 1 ? 's' : ''}',
                  Icons.sports_esports,
                ),
              ],
            ),

            if (availableArcades.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Disponible sur :',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    availableArcades.take(2).map((arcade) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          arcade.nom,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList()..addAll(
                      availableArcades.length > 2
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${availableArcades.length - 2}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ]
                          : [],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  void _showCancelReservationDialog(
    ReservationModel reservation,
    ArcadeProvider arcadeProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler la réservation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jeu : ${reservation.gameName}'),
                    Text('Borne : ${reservation.arcadeName}'),
                    Text('Tickets : ${reservation.ticketsUsed} (remboursés)'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await arcadeProvider.cancelReservation(
                  reservation.id,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Réservation annulée et tickets remboursés'
                            : arcadeProvider.errorMessage ??
                                  'Erreur lors de l\'annulation',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );

                  if (success) {
                    // Actualiser le solde de tickets
                    Provider.of<TicketProvider>(
                      context,
                      listen: false,
                    ).loadBalance();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );
  }
}
