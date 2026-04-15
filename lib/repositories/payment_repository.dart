import '../core/network/app_dio_client.dart';
import '../core/network/api_exceptions.dart';
import '../models/payment_config_model.dart';
import '../models/ticket_offer_model.dart';
import '../models/ticket_purchase_checkout_model.dart';
import '../models/ticket_purchase_status_model.dart';

class PaymentRepository {
  PaymentRepository({AppDioClient? apiClient})
    : _apiClient = apiClient ?? AppDioClient();

  final AppDioClient _apiClient;

  Future<PaymentConfigModel> getPaymentConfig() async {
    final response = await _apiClient.get('/payments/config');
    return PaymentConfigModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TicketOfferModel>> getTicketOffers() async {
    dynamic rawData;
    try {
      final response = await _apiClient.get('/tickets/offers');
      rawData = response.data;
    } on UnauthorizedException {
      final response = await _apiClient.get(
        '/tickets/offers',
        authRequired: true,
      );
      rawData = response.data;
    }

    final list = _extractOffersList(rawData);
    return list
        .map((item) => TicketOfferModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TicketPurchaseCheckoutModel> createPurchaseSession(int offerId) async {
    final response = await _apiClient.post(
      '/tickets/purchase',
      authRequired: true,
      data: {'offer_id': offerId},
    );
    return TicketPurchaseCheckoutModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<TicketPurchaseStatusModel> getPurchaseStatus(int transactionId) async {
    final response = await _apiClient.get(
      '/tickets/purchase/$transactionId/status',
      authRequired: true,
    );
    return TicketPurchaseStatusModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<int> getTicketBalance() async {
    final response = await _apiClient.get(
      '/tickets/balance',
      authRequired: true,
    );
    final data = response.data as Map<String, dynamic>;
    return (data['balance'] as int?) ?? 0;
  }

  List<dynamic> _extractOffersList(dynamic rawData) {
    if (rawData is List<dynamic>) {
      return rawData;
    }
    if (rawData is Map<String, dynamic>) {
      final possible = rawData['offers'] ?? rawData['items'] ?? rawData['data'];
      if (possible is List<dynamic>) {
        return possible;
      }
    }
    throw ApiException('Format de reponse des offres invalide');
  }
}
