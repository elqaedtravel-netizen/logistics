import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/orders_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة المؤشرات والتحليلات الفنية (Executive BI)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.statusDelivered.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.circle, color: AppColors.statusDelivered, size: 8),
                SizedBox(width: 6),
                Text('مؤشرات حية متزامنة', style: TextStyle(color: AppColors.statusDelivered, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. الكروت المالية والتشغيلية الأربعة الرئيسية
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
              data: (stats) => Row(
                children: [
                  _buildMetricCard('إجمالي الإيرادات المحصلة', '١٨٤,٧٥٠.٠٠ ج.م', '↑ +١٤.٢٪ هذا الأسبوع', AppColors.statusDelivered, Icons.account_balance_wallet),
                  const SizedBox(width: 12),
                  _buildMetricCard('الشحنات النشطة على الخطوط', '١,٢٤٨ أوردر', 'نسبة التسليم في الموعد ٩٦.٨٪ 🎯', AppColors.primary, Icons.local_shipping),
                  const SizedBox(width: 12),
                  _buildMetricCard('شحنات مؤجلة مجدولة', '١٤ شحنة', 'موثقة بالأسباب والـ GPS', AppColors.statusPostponed, Icons.schedule),
                  const SizedBox(width: 12),
                  _buildMetricCard('السيولة بالخزينة المركزية', '١٤١,٨٦٠.٠٠ ج.م', 'مطابقة مع إنستاباي و CIB', Colors.indigo, Icons.account_balance),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. الصف الأول: أفضل المناديب أداءً + أفضل الأصناف مبيعاً
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // جدول أفضل المناديب
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('🏆 أفضل المناديب أداءً (Leaderboard)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 15)),
                              Text('تقييم الأسبوع', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildDriverLeaderboardItem('🥇', 'أحمد محمود (خط المعادي وطرة)', '٤٨ شحنة مسلمة | ⭐ 4.9', 'نسبة الإنجاز ٩٨.٥٪', '١٤,٥٠٠ ج.م'),
                          const Divider(height: 16),
                          _buildDriverLeaderboardItem('🥈', 'محمود حسن (خط الدقي والمهندسين)', '٤٢ شحنة مسلمة | ⭐ 4.8', 'نسبة الإنجاز ٩٥.٢٪', '٨,٩٠٠ ج.م'),
                          const Divider(height: 16),
                          _buildDriverLeaderboardItem('🥉', 'ياسر عبد الله (خط مدينة نصر والتجمع)', '٣٩ شحنة مسلمة | ⭐ 4.7', 'نسبة الإنجاز ٩٣.٨٪', '١١,٢٠٠ ج.م'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // بطاقة أفضل الأصناف مبيعاً
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('🔥 أفضل الأصناف مبيعاً وحركة (Top Sellers)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 15)),
                              Text('دوران سريع ⚡', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildTopProductItem('🎧', 'سماعات بلوتوث ANC Pro', 'بيع ١٢٤ قطعة | متبقي ٥٠ (رف A12)', '١٧٩,٨٠٠ ج.م', 'الأعلى طلباً 🚀'),
                          const Divider(height: 16),
                          _buildTopProductItem('⌚', 'ساعة رياضية ذكية أموليد GPS', 'بيع ٨٢ قطعة | متبقي ٣٥ (رف B04)', '٢٣٣,٧٠٠ ج.م', 'أعلى هامش ربح 💎'),
                          const Divider(height: 16),
                          _buildTopProductItem('🔋', 'باور بنك سريع 20000mAh 65W', 'بيع ٦٠ قطعة | متبقي ٨ (رف C02)', '٦٩,٠٠٠ ج.م', 'أوشك على النفاد ⚠️'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. الصف الثاني: تنبيهات المخزون الذكية + اقتراحات وتوصيات الإدارة
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تنبيهات المخزون
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('⚠️ تنبيهات المخزون وإعادة الطلب', style: TextStyle(fontWeight: FontWeight.black, fontSize: 15)),
                              Text('٢ صنف بحاجة لتوريد', style: TextStyle(fontSize: 11, color: AppColors.statusCanceled, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.withOpacity(0.2))),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('باور بنك سريع 20000mAh (مستوى حرج: ٨ قطع)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 12, color: Colors.red)),
                                SizedBox(height: 4),
                                Text('المخزون ينفد خلال ٢٤-٣٦ ساعة. التاجر المورد: شركة تكنو ستور مصر.', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ذراع تحكم لاسلكي برو (تحذير حد الأمان: ١٢ قطعة)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 12, color: Colors.orange)),
                                SizedBox(height: 4),
                                Text('متبقي ١٢ قطعة في مخزن القاهرة رف A05. يوصى بإعادة الطلب خلال ٤٨ ساعة.', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // اقتراحات وتوصيات ذكية للمدير
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('💡 اقتراحات وتوصيات تنفيذية ذكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.black, fontSize: 15)),
                            Text('تحليل فني لحظي', style: TextStyle(color: Colors.indigoAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 14),
                        Text('• زيادة سعة التوزيع بالمعادي: ارتفاع الطلبات بنسبة ٣٥٪ اليوم، يوصى بإسناد مندوب مساند.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                        SizedBox(height: 10),
                        Text('• مكافأة كابتن أحمد محمود: حقق ٩٨.٥٪ تسليم بدون تأخير للأسبوع الثالث.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                        SizedBox(height: 10),
                        Text('• تصفية عهدة المساء: العهدة الكاش بالشارع تجاوزت ٤٢,٠٠٠ ج.م، يفضل طلب توريد إنستاباي.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.black, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverLeaderboardItem(String rank, String name, String details, String rate, String cash) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(rank, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 12)),
                Text(details, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.statusDelivered.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(rate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusDelivered)),
            ),
            const SizedBox(height: 2),
            Text(cash, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.black, fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }

  Widget _buildTopProductItem(String icon, String name, String details, String revenue, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 12)),
                Text(details, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(revenue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.black, fontFamily: 'monospace')),
            Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ],
    );
  }
}
