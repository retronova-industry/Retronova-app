enum TicketPurchaseStatus { pending, succeeded, failed, unknown }

class TicketPurchaseStatusModel {
  TicketPurchaseStatusModel({
    required this.transactionId,
    required this.status,
    required this.currentBalance,
    this.ticketsReceived,
    this.amountPaid,
  });

  final int transactionId;
  final TicketPurchaseStatus status;
  final int currentBalance;
  final int? ticketsReceived;
  final double? amountPaid;

  bool get isFinal =>
      status == TicketPurchaseStatus.succeeded ||
      status == TicketPurchaseStatus.failed;

  factory TicketPurchaseStatusModel.fromJson(Map<String, dynamic> json) {
    return TicketPurchaseStatusModel(
      transactionId: json['transaction_id'] as int,
      status: _parseStatus(json['status']?.toString()),
      ticketsReceived: _toIntOrNull(json['tickets_received']),
      amountPaid: _toDoubleOrNull(json['amount_paid']),
      currentBalance: _toIntOrNull(json['current_balance']) ?? 0,
    );
  }

  static TicketPurchaseStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return TicketPurchaseStatus.pending;
      case 'succeeded':
        return TicketPurchaseStatus.succeeded;
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
