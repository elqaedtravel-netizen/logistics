import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/analytics_provider.dart';
import '../orders/widgets/create_order_modal.dart';
import '../inventory/widgets/add_product_modal.dart';
import 'widgets/analytics_charts.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _openCreateOrder(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateOrderModal(),
    );
  }

  void _openAddProduct(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddProductModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لوحة التحكم والعمليات اللوجستية (Enterprise Dashboard)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 17)),
            Text(
              'متابعة الإيرادات، خطوط السير، حسابات العهدة والتوريد، ومؤشرات الأداء اللحظية',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // زر إضافة صنف للمخزن
          OutlinedButton.icon(
            onPressed: () => _openAddProduct(context),
            icon: const Icon(Icons.add_box_outlined, size: 16),
            label: const Text('إضافة صنف للمخزن'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 10),
          // زر إنشاء أوردر وبوليصة جديدة
          ElevatedButton.icon(
            onPressed: () => _openCreateOrder(context),
            icon: const Icon(Icons.add_task, size: 16),
            label: const Text('إذن شحن وتوزيع جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('تعذر تحميل مؤشرات الأداء: $err'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.refresh(dashboardAnalyticsProvider), child: const Text('إعادة المحاولة')),
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
                // 1. كروت مؤشرات الأداء الـ 4 مع نسب النمو
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'إجمالي الإيرادات المحصلة',
                        '${kpis.totalRevenueEgp.toStringAsFixed(2)} ج.م',
                        '↑ +١٤.٢٪ مقارنة بالأسبوع الماضي',
                        Icons.payments,
                        AppColors.statusDelivered,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'إجمالي الأوردرات النشطة',
                        '${kpis.totalOrdersCount} شحنة',
                        'فروع القاهرة والجيزة والإسكندرية',
                        Icons.local_shipping,
                        AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'المناديب على خطوط السير',
                        '${kpis.activeDriversCount} مندوب نشط',
                        'معدل التسليم ٩٤.٨٪ في الموعد',
                        Icons.two_wheeler,
                        AppColors.brandSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'عهدة كاش مع المناديب',
                        '${kpis.unsettledDriverCashEgp.toStringAsFixed(2)} ج.م',
                        'جاهزة للتوريد بالخزينة',
                        Icons.account_balance_wallet,
                        AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. الرسوم البيانية التفاعلية (منحنى الإيرادات + توزيع الحالات)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // منحنى الإيرادات
                    Expanded(
                      flex: 5,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('معدل الإيرادات اليومية وتوريد الكاش', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                      Text('تطور حجم المبيعات والنقدية المحصلة خلال الأيام السبعة الأخيرة (ج.م)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                    child: const Text('مباشر ⚡', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              const RevenueLineChart(
                                weeklyData: [12400, 18900, 24500, 21200, 31400, 38900, 42890],
                                days: ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // الدائرة البيانية لحالات الأوردرات
                    Expanded(
                      flex: 4,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('توزيع الأوردرات حسب دورة الشحن', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                              Text('النسبة المئوية لكل مرحلة تشغيلية', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              const Divider(height: 24),
                              OrderStatusDonutChart(statusMap: statusBreakdown),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. لوحة الصدارة للمناديب + تحليل أسباب التأجيل
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // المتصدرون من المناديب
                    Expanded(
                      flex: 4,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('أعلى المناديب تسليماً (Leaderboard)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                  Text('تقييم الأداء ⭐', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 20),
                              const DriverLeaderboardCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // تحليل أسباب التأجيل
                    Expanded(
                      flex: 5,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('تحليل أسباب تأجيل الشحنات (Root Cause)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.statusPostponed.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                    child: Text('${statusBreakdown['Postponed'] ?? 0} شحنة مؤجلة', style: const TextStyle(color: AppColors.statusPostponed, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              if (postponementAnalysis.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: Text('لا توجد شحنات مؤجلة حالياً، جميع خطوط السير تعمل بانتظام.')),
                                )
                              else
                                ...postponementAnalysis.entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(_translateReason(e.key), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            Text('${e.value} مرة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.black, color: AppColors.statusPostponed)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: (e.value / 25).clamp(0.05, 1.0),
                                            backgroundColor: AppColors.surfaceElevated,
                                            color: AppColors.statusPostponed,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
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

  String _translateReason(String key) {
    for (final r in AppConstants.postponementReasons) {
      if (r['code'] == key) return r['label']!;
    }
    return key.replaceAll('_', ' ');
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.black, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
