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
    return TicketPurchaseCheckoutModel(
      transactionId: json['transaction_id'] as int,
      stripeSessionId: (json['stripe_session_id'] ?? '').toString(),
      checkoutUrl: (json['checkout_url'] ?? '').toString(),
    );
  }
}
