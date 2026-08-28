class DashboardKpis {
  final double totalRevenueEgp;
  final int totalOrdersCount;
  final int activeDriversCount;
  final double pendingCodInRouteEgp;
  final double unsettledDriverCashEgp;
  final int lowStockAlertsCount;

  DashboardKpis({
    required this.totalRevenueEgp,
    required this.totalOrdersCount,
    required this.activeDriversCount,
    required this.pendingCodInRouteEgp,
    required this.unsettledDriverCashEgp,
    required this.lowStockAlertsCount,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      totalRevenueEgp: double.tryParse(json['total_revenue_egp']?.toString() ?? '0') ?? 0.0,
      totalOrdersCount: int.tryParse(json['total_orders_count']?.toString() ?? '0') ?? 0,
      activeDriversCount: int.tryParse(json['active_drivers_count']?.toString() ?? '0') ?? 0,
      pendingCodInRouteEgp: double.tryParse(json['pending_cod_in_route_egp']?.toString() ?? '0') ?? 0.0,
      unsettledDriverCashEgp: double.tryParse(json['unsettled_driver_cash_egp']?.toString() ?? '0') ?? 0.0,
      lowStockAlertsCount: int.tryParse(json['low_stock_alerts_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class DashboardDataModel {
  final DashboardKpis kpis;
  final Map<String, int> statusBreakdown;
  final Map<String, int> postponementAnalysis;
  final List<dynamic> recentOrders;

  DashboardDataModel({
    required this.kpis,
    required this.statusBreakdown,
    required this.postponementAnalysis,
    required this.recentOrders,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    final Map<String, int> statusMap = {};
    if (json['status_breakdown'] != null) {
      (json['status_breakdown'] as Map<String, dynamic>).forEach((k, v) {
        statusMap[k] = int.tryParse(v.toString()) ?? 0;
      });
    }

    final Map<String, int> postpMap = {};
    if (json['postponement_analysis'] != null) {
      (json['postponement_analysis'] as Map<String, dynamic>).forEach((k, v) {
        postpMap[k] = int.tryParse(v.toString()) ?? 0;
      });
    }

    return DashboardDataModel(
      kpis: DashboardKpis.fromJson(json['kpis'] ?? {}),
      statusBreakdown: statusMap,
      postponementAnalysis: postpMap,
      recentOrders: json['recent_orders'] ?? [],
    );
  }
}
