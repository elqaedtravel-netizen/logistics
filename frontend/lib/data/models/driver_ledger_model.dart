class DriverBalanceModel {
  final String driverId;
  final String driverName;
  final double totalCashCollected;
  final double totalCommissionEarned;
  final double totalSettledPayouts;
  final double currentCashInHandToHandover;
  final double netCommissionReceivable;
  final double runningBalance;

  DriverBalanceModel({
    required this.driverId,
    required this.driverName,
    required this.totalCashCollected,
    required this.totalCommissionEarned,
    required this.totalSettledPayouts,
    required this.currentCashInHandToHandover,
    required this.netCommissionReceivable,
    required this.runningBalance,
  });

  factory DriverBalanceModel.fromJson(Map<String, dynamic> json) {
    return DriverBalanceModel(
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      totalCashCollected: double.tryParse(json['total_cash_collected']?.toString() ?? '0') ?? 0.0,
      totalCommissionEarned: double.tryParse(json['total_commission_earned']?.toString() ?? '0') ?? 0.0,
      totalSettledPayouts: double.tryParse(json['total_settled_payouts']?.toString() ?? '0') ?? 0.0,
      currentCashInHandToHandover: double.tryParse(json['current_cash_in_hand_to_handover']?.toString() ?? '0') ?? 0.0,
      netCommissionReceivable: double.tryParse(json['net_commission_receivable']?.toString() ?? '0') ?? 0.0,
      runningBalance: double.tryParse(json['running_balance']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DriverLedgerEntryModel {
  final String id;
  final String driverId;
  final String? orderId;
  final String transactionType;
  final double amount;
  final double runningBalance;
  final String description;
  final String? referenceCode;
  final DateTime createdAt;

  DriverLedgerEntryModel({
    required this.id,
    required this.driverId,
    this.orderId,
    required this.transactionType,
    required this.amount,
    required this.runningBalance,
    required this.description,
    this.referenceCode,
    required this.createdAt,
  });

  factory DriverLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return DriverLedgerEntryModel(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      orderId: json['order_id'],
      transactionType: json['transaction_type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      runningBalance: double.tryParse(json['running_balance']?.toString() ?? '0') ?? 0.0,
      description: json['description'] ?? '',
      referenceCode: json['reference_code'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
