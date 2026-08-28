import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/analytics_provider.dart';
import '../../shared/status_badge.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة التحكم ومتابعة العمليات اللحظية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: () => ref.refresh(dashboardAnalyticsProvider),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.statusCanceled),
              const SizedBox(height: 12),
              Text('حدث خطأ أثناء تحميل المؤشرات: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardAnalyticsProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (data) {
          final kpis = data.kpis;
          final statusBreakdown = data.statusBreakdown;
          final postponementAnalysis = data.postponementAnalysis;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // كروت مؤشرات الأداء الـ 4
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        'إجمالي الإيرادات المحصلة',
                        '${kpis.totalRevenueEgp.toStringAsFixed(2)} ج.م',
                        Icons.payments_outlined,
                        AppColors.statusDelivered,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKpiCard(
                        'إجمالي الأوردرات',
                        '${kpis.totalOrdersCount}',
                        Icons.shopping_bag_outlined,
                        AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKpiCard(
                        'المناديب على خطوط السير',
                        '${kpis.activeDriversCount}',
                        Icons.delivery_dining_outlined,
                        AppColors.statusInWarehouse,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKpiCard(
                        'عهدة كاش مع المناديب',
                        '${kpis.unsettledDriverCashEgp.toStringAsFixed(2)} ج.م',
                        Icons.account_balance_wallet_outlined,
                        AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // مراحل دورة حياة الأوردرات
                const Text(
                  'حالات الأوردرات في دورة الشحن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusCard('قيد الانتظار', statusBreakdown['Pending'] ?? 0, AppColors.statusPending),
                    const SizedBox(width: 12),
                    _buildStatusCard('في المخزن', statusBreakdown['In_Warehouse'] ?? 0, AppColors.statusInWarehouse),
                    const SizedBox(width: 12),
                    _buildStatusCard('مع المندوب', statusBreakdown['Dispatched_to_Driver'] ?? 0, AppColors.statusDispatched),
                    const SizedBox(width: 12),
                    _buildStatusCard('تم التسليم', statusBreakdown['Delivered'] ?? 0, AppColors.statusDelivered),
                    const SizedBox(width: 12),
                    _buildStatusCard('مؤجل', statusBreakdown['Postponed'] ?? 0, AppColors.statusPostponed),
                    const SizedBox(width: 12),
                    _buildStatusCard('ملغي', statusBreakdown['Canceled'] ?? 0, AppColors.statusCanceled),
                    const SizedBox(width: 12),
                    _buildStatusCard('مرتجع للمخزن', statusBreakdown['Returned'] ?? 0, AppColors.statusReturned),
                  ],
                ),
                const SizedBox(height: 24),

                // تحليل أسباب التأجيل وتنبيهات المخزون
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // تحليل أسباب التأجيل
                    Expanded(
                      flex: 3,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'تحليل أسباب تأجيل الأوردرات (Root Cause)',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusPostponed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${statusBreakdown['Postponed'] ?? 0} أوردر مؤجل',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusPostponed),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              if (postponementAnalysis.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'لا توجد أوردرات في حالة تأجيل حالياً.',
                                      style: TextStyle(color: AppColors.textMuted),
                                    ),
                                  ),
                                )
                              else
                                ...postponementAnalysis.entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _translatePostponementReason(e.key),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceElevated,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            '${e.value} مرة',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                    ),
                    const SizedBox(width: 16),

                    // تنبيهات النواقص بالمخزن
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'تنبيهات نواقص المخزن',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                '${kpis.lowStockAlertsCount} صنف قارب على النفاد',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'أصناف تتطلب إعادة توريد فورية بالمخزن الرئيسي بالقاهرة لمنع تعطل الشحن والتسليم.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _translatePostponementReason(String key) {
    for (final r in AppConstants.postponementReasons) {
      if (r['code'] == key) return r['label']!;
    }
    return key.replaceAll('_', ' ');
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
