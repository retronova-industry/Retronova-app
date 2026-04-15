import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exceptions.dart';
import '../models/payment_config_model.dart';
import '../models/promo_code_model.dart';
import '../models/ticket_offer_model.dart';
import '../models/ticket_purchase_checkout_model.dart';
import '../models/ticket_purchase_model.dart';
import '../models/ticket_purchase_status_model.dart';
import '../repositories/payment_repository.dart';
import '../services/ticket_service.dart';

class TicketProvider with ChangeNotifier {
  TicketProvider({
    PaymentRepository? paymentRepository,
    TicketService? ticketService,
  }) : _paymentRepository = paymentRepository ?? PaymentRepository(),
       _ticketService = ticketService ?? TicketService();

  final PaymentRepository _paymentRepository;
  final TicketService _ticketService;

  List<TicketOfferModel> _offers = [];
  List<TicketPurchaseModel> _purchaseHistory = [];
  List<PromoCodeHistoryItem> _promoHistory = [];
  int _ticketBalance = 0;
  bool _isLoading = false;
  bool _isPurchasing = false;
  bool _isUsingPromo = false;
  bool _isPollingPurchase = false;
  String? _errorMessage;
  String? _purchaseMessage;
  PaymentConfigModel? _paymentConfig;
  int? _activeTransactionId;
  String? _activeCheckoutUrl;
  bool _checkoutLaunched = false;
  bool _pollingCancelled = false;
  TicketPurchaseStatusModel? _latestPurchaseStatus;

  List<TicketOfferModel> get offers => _offers;
  List<TicketPurchaseModel> get purchaseHistory => _purchaseHistory;
  List<PromoCodeHistoryItem> get promoHistory => _promoHistory;
  int get ticketBalance => _ticketBalance;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  bool get isUsingPromo => _isUsingPromo;
  bool get isPollingPurchase => _isPollingPurchase;
  String? get errorMessage => _errorMessage;
  String? get purchaseMessage => _purchaseMessage;
  PaymentConfigModel? get paymentConfig => _paymentConfig;
  int? get activeTransactionId => _activeTransactionId;
  String? get activeCheckoutUrl => _activeCheckoutUrl;
  TicketPurchaseStatusModel? get latestPurchaseStatus => _latestPurchaseStatus;
  bool get hasPendingCheckout =>
      _checkoutLaunched &&
      _activeTransactionId != null &&
      (_latestPurchaseStatus == null || !_latestPurchaseStatus!.isFinal);

  Future<void> loadOffers() async {
    try {
      _setLoading(true);
      _clearError();
      try {
        _paymentConfig = await _paymentRepository.getPaymentConfig();
      } catch (_) {
        _paymentConfig ??= PaymentConfigModel(
          publishableKey: '',
          currency: 'eur',
          checkoutMode: CheckoutMode.unknown,
        );
      }
      _offers = await _paymentRepository.getTicketOffers();
      notifyListeners();
    } catch (e) {
      _handleError(e, fallback: 'Impossible de charger les offres tickets');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBalance() async {
    try {
      _clearError();
      _ticketBalance = await _paymentRepository.getTicketBalance();
      notifyListeners();
    } catch (e) {
      _handleError(e, fallback: 'Impossible de charger le solde de tickets');
    }
  }

  Future<TicketPurchaseCheckoutModel?> startCheckoutPurchase(
    int offerId,
  ) async {
    if (_isPurchasing || _isPollingPurchase) {
      return null;
    }
    try {
      _setPurchasing(true);
      _clearError();
      _purchaseMessage = null;
      final checkout = await _paymentRepository.createPurchaseSession(offerId);
      _activeTransactionId = checkout.transactionId;
      _activeCheckoutUrl = checkout.checkoutUrl;
      _checkoutLaunched = false;
      _latestPurchaseStatus = null;
      _purchaseMessage = 'Redirection vers Stripe Checkout...';
      notifyListeners();
      return checkout;
    } catch (e) {
      _handleError(e, fallback: 'Impossible de démarrer le paiement');
      return null;
    } finally {
      _setPurchasing(false);
    }
  }

  void markCheckoutLaunched() {
    _checkoutLaunched = true;
    _purchaseMessage = 'Paiement en cours. Revenez dans l\'app pour confirmer.';
    notifyListeners();
  }

  Future<TicketPurchaseStatusModel?> pollActivePurchaseStatus({
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final transactionId = _activeTransactionId;
    if (transactionId == null || _isPollingPurchase) {
      return _latestPurchaseStatus;
    }

    _isPollingPurchase = true;
    _pollingCancelled = false;
    _purchaseMessage = 'Vérification du statut du paiement...';
    notifyListeners();

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_pollingCancelled) {
        _isPollingPurchase = false;
        _purchaseMessage = 'Vérification annulée.';
        notifyListeners();
        return null;
      }

      try {
        final status = await _paymentRepository.getPurchaseStatus(
          transactionId,
        );
        _latestPurchaseStatus = status;
        _ticketBalance = status.currentBalance;

        if (status.status == TicketPurchaseStatus.succeeded) {
          _isPollingPurchase = false;
          _purchaseMessage = _buildSuccessMessage(status);
          _checkoutLaunched = false;
          notifyListeners();
          unawaited(loadPurchaseHistory());
          return status;
        }

        if (status.status == TicketPurchaseStatus.failed) {
          _isPollingPurchase = false;
          _purchaseMessage = 'Paiement refusé ou annulé.';
          _checkoutLaunched = false;
          notifyListeners();
          return status;
        }
      } catch (e) {
        _isPollingPurchase = false;
        _handleError(e, fallback: 'Erreur pendant la vérification du paiement');
        return null;
      }

      await Future.delayed(interval);
    }

    _isPollingPurchase = false;
    _purchaseMessage =
        'Paiement en attente. Vérifiez votre historique ou réessayez dans quelques secondes.';
    notifyListeners();
    return _latestPurchaseStatus;
  }

  void cancelPurchasePolling() {
    _pollingCancelled = true;
    notifyListeners();
  }

  void clearPurchaseFlow() {
    _activeTransactionId = null;
    _activeCheckoutUrl = null;
    _checkoutLaunched = false;
    _pollingCancelled = false;
    _isPollingPurchase = false;
    _latestPurchaseStatus = null;
    _purchaseMessage = null;
    notifyListeners();
  }

  Future<bool> purchaseTickets(int offerId) async {
    try {
      _setPurchasing(true);
      _clearError();
      final result = await _ticketService.purchaseTickets(offerId);
      _ticketBalance = result['new_balance'] ?? _ticketBalance;
      await loadPurchaseHistory();
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e, fallback: 'Erreur lors de l\'achat');
      return false;
    } finally {
      _setPurchasing(false);
    }
  }

  Future<void> loadPurchaseHistory() async {
    try {
      _clearError();
      _purchaseHistory = await _ticketService.getPurchaseHistory();
      notifyListeners();
    } catch (e) {
      _handleError(
        e,
        fallback: 'Impossible de charger l\'historique des achats',
      );
    }
  }

  Future<bool> usePromoCode(String code) async {
    if (code.trim().isEmpty) {
      _setError('Veuillez entrer un code promo');
      return false;
    }

    try {
      _setUsingPromo(true);
      _clearError();
      final result = await _ticketService.usePromoCode(
        code.trim().toUpperCase(),
      );
      _ticketBalance = result.newBalance;
      await loadPromoHistory();
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e, fallback: 'Erreur lors de l\'utilisation du code promo');
      return false;
    } finally {
      _setUsingPromo(false);
    }
  }

  Future<void> loadPromoHistory() async {
    try {
      _clearError();
      _promoHistory = await _ticketService.getPromoHistory();
      notifyListeners();
    } catch (e) {
      _handleError(
        e,
        fallback: 'Impossible de charger l\'historique des codes promo',
      );
    }
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadOffers(),
      loadBalance(),
      loadPurchaseHistory(),
      loadPromoHistory(),
    ]);
  }

  Future<void> refresh() async {
    await loadAllData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setPurchasing(bool purchasing) {
    _isPurchasing = purchasing;
    notifyListeners();
  }

  void _setUsingPromo(bool usingPromo) {
    _isUsingPromo = usingPromo;
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

  TicketOfferModel? findOfferById(int id) {
    try {
      return _offers.firstWhere((offer) => offer.id == id);
    } catch (_) {
      return null;
    }
  }

  double get totalSpent {
    return _purchaseHistory.fold(
      0.0,
      (sum, purchase) => sum + purchase.amountPaid,
    );
  }

  int get totalTicketsPurchased {
    return _purchaseHistory.fold(
      0,
      (sum, purchase) => sum + purchase.ticketsReceived,
    );
  }

  int get totalTicketsFromPromo {
    return _promoHistory.fold(0, (sum, promo) => sum + promo.ticketsReceived);
  }

  int get totalPromoCodesUsed => _promoHistory.length;

  void _handleError(Object error, {required String fallback}) {
    if (error is UnauthorizedException) {
      _setError('Session expirée. Reconnectez-vous.');
      return;
    }
    if (error is NetworkException) {
      _setError(error.message);
      return;
    }
    if (error is ApiException) {
      _setError(error.message);
      return;
    }
    _setError(fallback);
  }

  String _buildSuccessMessage(TicketPurchaseStatusModel status) {
    if (status.ticketsReceived != null && status.amountPaid != null) {
      return 'Paiement confirmé: +${status.ticketsReceived} tickets pour ${status.amountPaid!.toStringAsFixed(2)}.';
    }
    return 'Paiement confirmé. Solde mis à jour.';
  }
}
