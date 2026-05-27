// lib/presentation/screens/arcade/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:retronova_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../models/arcade_model.dart';
import '../../../models/game_model.dart';
import '../../../models/friend_model.dart';
import '../../../providers/arcade_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../providers/ticket_provider.dart';
import '../../widgets/ticket_balance_widget.dart';

class ReservationScreen extends StatefulWidget {
  final ArcadeModel arcade;
  final GameOnArcadeModel? selectedGame;

  const ReservationScreen({super.key, required this.arcade, this.selectedGame});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  GameOnArcadeModel? _selectedGame;
  FriendModel? _selectedFriend;
  bool _isMultiplayer = false;

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.selectedGame;

    // Charger les amis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendProvider>(context, listen: false).loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réserver - ${widget.arcade.nom}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: CompactTicketBalance()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArcadeInfo(),
            const SizedBox(height: 20),
            _buildGameSelection(),
            const SizedBox(height: 20),
            if (_selectedGame != null &&
                _selectedGame!.supportsMultiplayer) ...[
              _buildMultiplayerOption(),
              const SizedBox(height: 20),
            ],
            if (_isMultiplayer && _selectedGame != null) ...[
              _buildFriendSelection(),
              const SizedBox(height: 20),
            ],
            if (_selectedGame != null) ...[
              _buildReservationSummary(),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildArcadeInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_esports, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Borne d\'arcade',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.arcade.nom,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.arcade.localisation,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                Text(
                  widget.arcade.formattedDistance,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.videogame_asset, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Sélectionner un jeu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.arcade.games.isEmpty)
              const Center(
                child: Text(
                  'Aucun jeu disponible sur cette borne',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.arcade.games.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final game = widget.arcade.games[index];
                  return _buildGameOption(game);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOption(GameOnArcadeModel game) {
    final isSelected = _selectedGame?.id == game.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGame = game;
          _isMultiplayer = false;
          _selectedFriend = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${game.slotNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
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
                    game.nom,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        game.playersDescription,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.confirmation_number,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.ticketCost} tickets',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplayerOption() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Mode de jeu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isMultiplayer = false;
                        _selectedFriend = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: !_isMultiplayer
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: !_isMultiplayer ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: !_isMultiplayer
                            ? AppColors.primary.withOpacity(0.05)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person,
                            color: !_isMultiplayer
                                ? AppColors.primary
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Solo',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: !_isMultiplayer
                                  ? AppColors.primary
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isMultiplayer = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isMultiplayer
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: _isMultiplayer ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _isMultiplayer
                            ? AppColors.primary.withOpacity(0.05)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people,
                            color: _isMultiplayer
                                ? AppColors.primary
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Multijoueur',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _isMultiplayer
                                  ? AppColors.primary
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Inviter un ami',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                if (friendProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (friendProvider.friends.isEmpty) {
                  return const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aucun ami disponible',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ajoutez des amis pour jouer ensemble',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                      title: const Text('Aucun ami'),
                      subtitle: const Text('Jouer en solo dans ce mode'),
                      trailing: Radio<FriendModel?>(
                        value: null,
                        groupValue: _selectedFriend,
                        onChanged: (value) {
                          setState(() {
                            _selectedFriend = value;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedFriend = null;
                        });
                      },
                    ),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friendProvider.friends.length,
                      itemBuilder: (context, index) {
                        final friend = friendProvider.friends[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              friend.pseudo.isNotEmpty
                                  ? friend.pseudo[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(friend.pseudo),
                          subtitle: Text('@${friend.pseudo}'),
                          trailing: Radio<FriendModel?>(
                            value: friend,
                            groupValue: _selectedFriend,
                            onChanged: (value) {
                              setState(() {
                                _selectedFriend = value;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedFriend = friend;
                            });
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Résumé de la réservation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Borne', widget.arcade.nom),
            _buildSummaryRow('Jeu', _selectedGame!.nom),
            _buildSummaryRow('Slot', 'Position ${_selectedGame!.slotNumber}'),
            if (_isMultiplayer) ...[
              _buildSummaryRow(
                'Joueur 2',
                _selectedFriend?.pseudo ?? 'Solo (dans ce mode)',
              ),
            ],
            const Divider(),
            Consumer<TicketProvider>(
              builder: (context, ticketProvider, child) {
                final hasEnoughTickets =
                    ticketProvider.ticketBalance >= _selectedGame!.ticketCost;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Coût en tickets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${_selectedGame!.ticketCost}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Votre solde actuel'),
                        Text(
                          '${ticketProvider.ticketBalance}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: hasEnoughTickets ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Solde après réservation'),
                        Text(
                          '${ticketProvider.ticketBalance - _selectedGame!.ticketCost}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: hasEnoughTickets ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (!hasEnoughTickets) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tickets insuffisants. Vous avez besoin de ${_selectedGame!.ticketCost - ticketProvider.ticketBalance} tickets supplémentaires.',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Naviguer vers le store
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                            // Note: Vous devrez adapter cette navigation selon votre structure
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Acheter des tickets'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_selectedGame == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Sélectionnez un jeu pour continuer'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Consumer2<ArcadeProvider, TicketProvider>(
        builder: (context, arcadeProvider, ticketProvider, child) {
          final hasEnoughTickets =
              ticketProvider.ticketBalance >= _selectedGame!.ticketCost;
          final isCreating = arcadeProvider.isCreatingReservation;

          return ElevatedButton.icon(
            onPressed: (hasEnoughTickets && !isCreating)
                ? () => _createReservation(arcadeProvider)
                : null,
            icon: isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.event_seat),
            label: Text(
              isCreating
                  ? 'Création en cours...'
                  : hasEnoughTickets
                  ? 'Confirmer la réservation'
                  : 'Tickets insuffisants',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasEnoughTickets
                  ? AppColors.primary
                  : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createReservation(ArcadeProvider arcadeProvider) async {
    // Afficher une dialog de confirmation
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    final reservation = await arcadeProvider.createReservation(
      arcadeId: widget.arcade.id,
      gameId: _selectedGame!.id,
      player2Id: _selectedFriend?.id,
    );

    if (mounted) {
      if (reservation != null) {
        // Actualiser le solde de tickets
        Provider.of<TicketProvider>(context, listen: false).loadBalance();

        // Afficher le succès et revenir en arrière
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Réservation créée avec succès !',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text('Code de déverrouillage: ${reservation.unlockCode}'),
                if (reservation.positionInQueue != null)
                  Text('Position en file: ${reservation.positionInQueue}e'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Voir mes réservations',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Naviguer vers l'onglet arcade avec la tab réservations
              },
            ),
          ),
        );

        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              arcadeProvider.errorMessage ??
                  'Erreur lors de la création de la réservation',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmer la réservation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vous êtes sur le point de créer cette réservation :',
                  ),
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
                        Text('Borne : ${widget.arcade.nom}'),
                        Text('Jeu : ${_selectedGame!.nom}'),
                        Text('Slot : ${_selectedGame!.slotNumber}'),
                        if (_isMultiplayer && _selectedFriend != null)
                          Text('Avec : ${_selectedFriend!.pseudo}')
                        else if (_isMultiplayer)
                          const Text('Mode : Multijoueur (solo)'),
                        Text('Coût : ${_selectedGame!.ticketCost} tickets'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cette action débitera vos tickets immédiatement.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
