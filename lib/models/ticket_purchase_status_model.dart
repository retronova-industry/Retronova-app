enum TicketPurchaseStatus { pending, succeeded, failed, unknown }

class TicketPurchaseStatusModel {
  TicketPurchaseStatusModel({
    required this.transactionId,
    required this.status,
    this.currentBalance,
    this.ticketsReceived,
    this.amountPaid,
  });

  final int transactionId;
  final TicketPurchaseStatus status;
  final int? currentBalance;
  final int? ticketsReceived;
  final double? amountPaid;

  bool get isFinal =>
      status == TicketPurchaseStatus.succeeded ||
      status == TicketPurchaseStatus.failed;

  factory TicketPurchaseStatusModel.fromJson(Map<String, dynamic> json) {
    return TicketPurchaseStatusModel(
      transactionId:
          _toIntOrNull(json['transaction_id'] ?? json['purchase_id']) ?? 0,
      status: _parseStatus(json['status']?.toString()),
      ticketsReceived: _toIntOrNull(json['tickets_received']),
      amountPaid: _toDoubleOrNull(json['amount_paid']),
      currentBalance: _toIntOrNull(json['current_balance'] ?? json['balance']),
    );
  }

  static TicketPurchaseStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return TicketPurchaseStatus.pending;
      case 'paid':
      case 'succeeded':
      case 'completed':
        return TicketPurchaseStatus.succeeded;
      case 'expired':
      case 'canceled':
      case 'cancelled':
      case 'failed':
        return TicketPurchaseStatus.failed;
      default:
        return TicketPurchaseStatus.unknown;
    }
  }

  static int? _toIntOrNull(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
