enum CheckoutMode { redirect, unknown }

class PaymentConfigModel {
  PaymentConfigModel({
    required this.publishableKey,
    required this.currency,
    required this.checkoutMode,
  });

  final String publishableKey;
  final String currency;
  final CheckoutMode checkoutMode;

  factory PaymentConfigModel.fromJson(Map<String, dynamic> json) {
    return PaymentConfigModel(
      publishableKey: (json['publishable_key'] ?? '').toString(),
      currency: (json['currency'] ?? 'eur').toString(),
      checkoutMode: _parseCheckoutMode(json['checkout_mode']?.toString()),
    );
  }

  static CheckoutMode _parseCheckoutMode(String? mode) {
    final normalized = mode?.trim().toLowerCase();
    if (normalized == 'redirect') {
      return CheckoutMode.redirect;
    }
    return CheckoutMode.unknown;
  }
}
