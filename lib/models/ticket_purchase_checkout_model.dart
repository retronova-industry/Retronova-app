class TicketPurchaseCheckoutModel {
  TicketPurchaseCheckoutModel({
    required this.transactionId,
    required this.stripeSessionId,
    required this.checkoutUrl,
  });

  final int transactionId;
  final String stripeSessionId;
  final String checkoutUrl;

  factory TicketPurchaseCheckoutModel.fromJson(Map<String, dynamic> json) {
    final transactionRaw = json['transaction_id'] ?? json['purchase_id'];
    final sessionRaw = json['stripe_session_id'] ?? json['checkout_session_id'];

    return TicketPurchaseCheckoutModel(
      transactionId: _toInt(transactionRaw),
      stripeSessionId: (sessionRaw ?? '').toString(),
      checkoutUrl: (json['checkout_url'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw const FormatException('transaction/purchase id invalide');
  }
}
