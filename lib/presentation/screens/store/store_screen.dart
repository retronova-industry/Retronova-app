// lib/presentation/screens/store/store_screen.dart - Version avec codes promo
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/ticket_provider.dart';
import '../../../models/ticket_offer_model.dart';
import '../../../models/ticket_purchase_model.dart';
import '../../../models/promo_code_model.dart';
import '../../../models/ticket_purchase_status_model.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController _promoCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this); // Maintenant 4 tabs

    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProvider = Provider.of<TicketProvider>(
        context,
        listen: false,
      );
      ticketProvider.loadAllData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    if (ticketProvider.hasPendingCheckout) {
      _handleAppReturnedFromCheckout(ticketProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.storeLabel),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Offres', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Codes Promo', icon: Icon(Icons.redeem)),
            Tab(text: 'Mon Solde', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: 'Historique', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Consumer<TicketProvider>(
        builder: (context, ticketProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOffersTab(ticketProvider),
              _buildPromoTab(ticketProvider), // NOUVEAU TAB
              _buildBalanceTab(ticketProvider),
              _buildHistoryTab(ticketProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOffersTab(TicketProvider ticketProvider) {
    if (ticketProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des offres...'),
          ],
        ),
      );
    }

    if (ticketProvider.offers.isEmpty) {
      final hasError = ticketProvider.errorMessage != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.store_outlined,
              size: 64,
              color: hasError ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              hasError
                  ? 'Impossible de charger les offres'
                  : 'Aucune offre disponible',
              style: TextStyle(
                fontSize: 18,
                color: hasError ? Colors.red : Colors.grey,
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  ticketProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ticketProvider.loadOffers(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (ticketProvider.purchaseMessage != null ||
            ticketProvider.isPollingPurchase)
          _buildPurchaseStatusBanner(ticketProvider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ticketProvider.loadOffers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ticketProvider.offers.length,
              itemBuilder: (context, index) {
                final offer = ticketProvider.offers[index];
                return _buildOfferCard(offer, ticketProvider);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseStatusBanner(TicketProvider ticketProvider) {
    final status = ticketProvider.latestPurchaseStatus?.status;
    final isSuccess = status == TicketPurchaseStatus.succeeded;
    final isFailed = status == TicketPurchaseStatus.failed;

    Color backgroundColor;
    if (isSuccess) {
      backgroundColor = Colors.green.shade100;
    } else if (isFailed) {
      backgroundColor = Colors.red.shade100;
    } else {
      backgroundColor = Colors.orange.shade100;
    }

    IconData icon;
    if (isSuccess) {
      icon = Icons.check_circle;
    } else if (isFailed) {
      icon = Icons.error;
    } else {
      icon = Icons.hourglass_bottom;
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ticketProvider.purchaseMessage ?? 'Paiement en cours...',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (ticketProvider.isPollingPurchase)
            TextButton(
              onPressed: ticketProvider.cancelPurchasePolling,
              child: const Text('Annuler'),
            )
          else
            TextButton(
              onPressed: ticketProvider.clearPurchaseFlow,
              child: const Text('Fermer'),
            ),
        ],
      ),
    );
  }

  // NOUVEAU TAB POUR LES CODES PROMO
  Widget _buildPromoTab(TicketProvider ticketProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section utilisation de code promo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.redeem, color: Colors.deepPurple, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Utiliser un code promo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Entrez votre code promo pour obtenir des tickets gratuits !',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _promoCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Code promo',
                            hintText: 'Ex: WELCOME10',
                            prefixIcon: const Icon(Icons.confirmation_number),
                            border: const OutlineInputBorder(),
                            errorText: ticketProvider.errorMessage,
                          ),
                          onChanged: (_) {
                            if (ticketProvider.errorMessage != null) {
                              ticketProvider.clearError();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: ticketProvider.isUsingPromo
                            ? null
                            : () => _usePromoCode(ticketProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: ticketProvider.isUsingPromo
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Utiliser'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Historique des codes promo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Codes promo utilisés',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (ticketProvider.promoHistory.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun code promo utilisé',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ticketProvider.promoHistory.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final promo = ticketProvider.promoHistory[index];
                        return _buildPromoHistoryCard(promo);
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Statistiques des codes promo
          if (ticketProvider.promoHistory.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistiques codes promo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Codes utilisés',
                      '${ticketProvider.totalPromoCodesUsed}',
                      Icons.redeem,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Tickets obtenus',
                      '${ticketProvider.totalTicketsFromPromo}',
                      Icons.confirmation_number,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoHistoryCard(PromoCodeHistoryItem promo) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check_circle, color: Colors.green),
      ),
      title: Text(
        promo.code,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      subtitle: Text(_formatDate(promo.usedAt)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '+${promo.ticketsReceived}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Future<void> _usePromoCode(TicketProvider ticketProvider) async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un code promo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await ticketProvider.usePromoCode(code);

    if (mounted) {
      if (success) {
        _promoCodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Code promo utilisé !',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Votre nouveau solde : ${ticketProvider.ticketBalance} tickets',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Voir le solde',
              textColor: Colors.white,
              onPressed: () => _tabController.animateTo(2), // Tab "Mon Solde"
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ticketProvider.errorMessage ??
                  'Erreur lors de l\'utilisation du code promo',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOfferCard(
    TicketOfferModel offer,
    TicketProvider ticketProvider,
  ) {
    final isGoodDeal = offer.isGoodDeal;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isGoodDeal
              ? LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      offer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isGoodDeal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PROMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Informations principales
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.confirmation_number,
                      color: Colors.deepPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.ticketsAmount} tickets',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Text(
                          '${offer.pricePerTicket.toStringAsFixed(2)}€ par ticket',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${offer.priceEuros.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      if (isGoodDeal)
                        Text(
                          'Économie: ${offer.savings.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bouton d'achat
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      ticketProvider.isPurchasing ||
                          ticketProvider.isPollingPurchase
                      ? null
                      : () => _showPurchaseDialog(offer, ticketProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGoodDeal
                        ? Colors.green
                        : Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: ticketProvider.isPurchasing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Acheter ${offer.ticketsAmount} tickets',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceTab(TicketProvider ticketProvider) {
    return RefreshIndicator(
      onRefresh: () => ticketProvider.loadBalance(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Solde principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.confirmation_number,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mon solde de tickets',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ticketProvider.ticketBalance}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'tickets disponibles',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Statistiques
            if (ticketProvider.purchaseHistory.isNotEmpty ||
                ticketProvider.promoHistory.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistiques',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (ticketProvider.purchaseHistory.isNotEmpty) ...[
                        _buildStatRow(
                          'Total dépensé',
                          '${ticketProvider.totalSpent.toStringAsFixed(2)}€',
                          Icons.euro,
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          'Tickets achetés',
                          '${ticketProvider.totalTicketsPurchased}',
                          Icons.shopping_cart,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (ticketProvider.promoHistory.isNotEmpty) ...[
                        _buildStatRow(
                          'Tickets via promo',
                          '${ticketProvider.totalTicketsFromPromo}',
                          Icons.redeem,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildStatRow(
                        'Achats effectués',
                        '${ticketProvider.purchaseHistory.length}',
                        Icons.shopping_bag,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Acheter tickets'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.redeem),
                    label: const Text('Code promo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(TicketProvider ticketProvider) {
    final hasHistory =
        ticketProvider.purchaseHistory.isNotEmpty ||
        ticketProvider.promoHistory.isNotEmpty;

    if (!hasHistory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun historique disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vos achats et codes promo apparaîtront ici',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Voir les offres'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ticketProvider.loadPurchaseHistory();
        await ticketProvider.loadPromoHistory();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount:
            ticketProvider.purchaseHistory.length +
            ticketProvider.promoHistory.length,
        itemBuilder: (context, index) {
          // Fusionner et trier les historiques par date
          final allHistory = <dynamic>[];
          allHistory.addAll(ticketProvider.purchaseHistory);
          allHistory.addAll(ticketProvider.promoHistory);

          // Trier par date décroissante
          allHistory.sort((a, b) {
            DateTime dateA = a is TicketPurchaseModel ? a.createdAt : a.usedAt;
            DateTime dateB = b is TicketPurchaseModel ? b.createdAt : b.usedAt;
            return dateB.compareTo(dateA);
          });

          final item = allHistory[index];

          if (item is TicketPurchaseModel) {
            return _buildPurchaseHistoryCard(item);
          } else if (item is PromoCodeHistoryItem) {
            return _buildPromoHistoryCardInHistory(item);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPurchaseHistoryCard(TicketPurchaseModel purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
        ),
        title: Text(
          '${purchase.ticketsReceived} tickets achetés',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_formatDate(purchase.createdAt)),
        trailing: Text(
          '${purchase.amountPaid.toStringAsFixed(2)}€',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildPromoHistoryCardInHistory(PromoCodeHistoryItem promo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.redeem, color: Colors.green),
        ),
        title: Text(
          'Code promo ${promo.code}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_formatDate(promo.usedAt)),
        trailing: Text(
          '+${promo.ticketsReceived}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
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
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  void _showPurchaseDialog(
    TicketOfferModel offer,
    TicketProvider ticketProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer l\'achat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous êtes sur le point d\'acheter :'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tickets :'),
                        Text(
                          '${offer.ticketsAmount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Prix :'),
                        Text(
                          '${offer.priceEuros.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    if (offer.isGoodDeal) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Économie :'),
                          Text(
                            '${offer.savings.toStringAsFixed(2)}€',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre solde actuel : ${ticketProvider.ticketBalance} tickets',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                'Nouveau solde : ${ticketProvider.ticketBalance + offer.ticketsAmount} tickets',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed:
                  ticketProvider.isPurchasing ||
                      ticketProvider.isPollingPurchase
                  ? null
                  : () => _processPurchase(offer, ticketProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: ticketProvider.isPurchasing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmer l\'achat'),
            ),
          ],
        );
      },
    );
  }

  void _processPurchase(
    TicketOfferModel offer,
    TicketProvider ticketProvider,
  ) async {
    Navigator.of(context).pop();
    await _startCheckoutRedirect(offer, ticketProvider);
  }

  Future<void> _startCheckoutRedirect(
    TicketOfferModel offer,
    TicketProvider ticketProvider,
  ) async {
    final checkout = await ticketProvider.startCheckoutPurchase(offer.id);
    if (!mounted) {
      return;
    }

    if (checkout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ticketProvider.errorMessage ??
                'Erreur lors du démarrage du paiement',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(checkout.checkoutUrl);
    if (uri == null || !_isAllowedCheckoutUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL Stripe Checkout invalide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) {
      return;
    }

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir Stripe Checkout'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ticketProvider.markCheckoutLaunched();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Finalisez le paiement Stripe, puis revenez dans l’app pour confirmer l’achat ${offer.name}.',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  bool _isAllowedCheckoutUrl(Uri uri) {
    if (!(uri.isScheme('https') || uri.isScheme('http'))) {
      return false;
    }

    final host = uri.host.toLowerCase();
    return host == 'checkout.stripe.com' || host.endsWith('.stripe.com');
  }

  Future<void> _handleAppReturnedFromCheckout(
    TicketProvider ticketProvider,
  ) async {
    final status = await ticketProvider.pollActivePurchaseStatus();
    if (!mounted || status == null) {
      return;
    }

    if (status.status == TicketPurchaseStatus.succeeded) {
      await ticketProvider.loadBalance();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paiement confirmé. Nouveau solde: ${ticketProvider.ticketBalance} tickets.',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir le solde',
            textColor: Colors.white,
            onPressed: () => _tabController.animateTo(2),
          ),
        ),
      );
      return;
    }

    if (status.status == TicketPurchaseStatus.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement échoué ou annulé. Aucun ticket crédité.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paiement toujours en attente. Vérification en cours...'),
      ),
    );
  }
}
