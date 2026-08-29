import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import '../providers/driver_provider.dart';
import '../shared/status_badge.dart';
import 'driver_order_action_screen.dart';
import 'driver_financials_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  final String? driverId;

  const DriverHomeScreen({super.key, this.driverId});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  void _openDriverSupportDialog() {
    String selectedIssue = 'عميل يرفض الاستلام بعد فتح الطرد والمعاينة';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.statusCanceled),
              SizedBox(width: 8),
              Text('مركز الدعم وبلاغات الطوارئ للمندوب'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر نوع المشكلة الميدانية للإبلاغ الفوري:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedIssue,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'عميل يرفض الاستلام بعد فتح الطرد والمعاينة', child: Text('عميل يرفض الاستلام بعد فتح الطرد')),
                    DropdownMenuItem(value: 'اختلاف في المبلغ المطلوب تحصيله بالبوليصة', child: Text('اختلاف في المبلغ المطلوب تحصيله')),
                    DropdownMenuItem(value: 'عطل مفاجئ بالمركبة على خط السير', child: Text('عطل مفاجئ بالمركبة على خط السير')),
                    DropdownMenuItem(value: 'صعوبة الوصول للعنوان بسبب إغلاق طريق', child: Text('صعوبة الوصول للعنوان')),
                    DropdownMenuItem(value: 'مشكلة تقنية بتطبيق المندوب', child: Text('مشكلة تقنية بتطبيق المندوب')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedIssue = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'تفاصيل البلاغ للمشرف الميداني',
                    hintText: 'اكتب ما حدث بدقة ليتدخل المشرف فوراً...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCanceled),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚨 تم إرسال البلاغ ($selectedIssue) لغرفة العمليات والمشرف الميداني بنجاح!'),
                    backgroundColor: AppColors.statusCanceled,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('إرسال البلاغ فوراً'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPostponeDialog(OrderModel order) {
    String selectedReason = 'العميل طلب موعداً لاحقاً (تحديد تاريخ وساعة)';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = 'الفترة المسائية (٤م - ٨م)';
    final notesController = TextEditingController(text: 'تم الاتفاق هاتفياً مع العميل على الموعد الجديد');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.statusPostponed),
              const SizedBox(width: 8),
              Text('تأجيل موعد تسليم #${order.orderNumber}'),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سبب التأجيل الإلزامي لتقرير خط السير:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'العميل طلب موعداً لاحقاً (تحديد تاريخ وساعة)', child: Text('طلب العميل موعداً لاحقاً')),
                    DropdownMenuItem(value: 'العميل لم يرد على الهاتف بعد ٣ محاولات', child: Text('العميل لم يرد بعد ٣ محاولات')),
                    DropdownMenuItem(value: 'المبلغ الكاش غير متوفر مع العميل حالياً', child: Text('المبلغ الكاش غير متوفر حالياً')),
                    DropdownMenuItem(value: 'العنوان غير دقيق وجاري مراجعته', child: Text('العنوان غير دقيق وجاري مراجعته')),
                    DropdownMenuItem(value: 'تعذر الوصول للموقع بسبب زحام شديد أو طقس', child: Text('تعذر الوصول للموقع')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedReason = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تاريخ التسليم الجديد:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text('${selectedDate.year}-${selectedDate.month}-${selectedDate.day}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الفترة المفضلة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: selectedSlot,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: 'الفترة الصباحية (١٠ص - ٢ظ)', child: Text('صباحي (١٠-٢)', style: TextStyle(fontSize: 11))),
                              DropdownMenuItem(value: 'الفترة المسائية (٤م - ٨م)', child: Text('مسائي (٤-٨)', style: TextStyle(fontSize: 11))),
                              DropdownMenuItem(value: 'فترة ليلية (٨م - ١١م)', child: Text('ليلي (٨-١١)', style: TextStyle(fontSize: 11))),
                            ],
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedSlot = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات المندوب للمتابعة'),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إحداثيات الموقع المسجل:', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('30.0444° N, 31.2357° E (GPS Verified ✓)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPostponed),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⏱️ تم تأجيل الشحنة #${order.orderNumber} لـ (${selectedDate.year}-${selectedDate.month}-${selectedDate.day} $selectedSlot) وتوثيق GPS الإدارة بنجاح.'),
                    backgroundColor: AppColors.statusPostponed,
                  ),
                );
              },
              child: const Text('تأكيد التأجيل والجدولة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(driverAssignedOrdersProvider(widget.driverId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Center(child: Text('أم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.black, fontSize: 13))),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كابتن: أحمد محمود', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                Text('فرع القاهرة المركزي (المعادي) | ⭐ 4.9', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.statusCanceled),
            tooltip: 'مركز الدعم وبلاغات الطوارئ',
            onPressed: _openDriverSupportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'المحفظة وتوريد العهدة',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DriverFinancialsScreen(driverId: widget.driverId)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. شبكة الإحصائيات المكثفة للمندوب (العهدة، العمولات، المبيعات، نسبة النجاح)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('العهدة الكاش بحوزتك:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('١٤,٥٠٠ ج.م', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black, color: AppColors.accent, fontFamily: 'monospace')),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DriverFinancialsScreen(driverId: widget.driverId))),
                          child: const Text('توريد للشركة ➔', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('عمولتك اليوم:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('+١,٤٥٠ ج.م', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black, color: AppColors.statusDelivered, fontFamily: 'monospace')),
                        SizedBox(height: 6),
                        Text('↑ جاهزة للصرف', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusDelivered)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الشحنات المسلمة:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('١٨ / ٢٠ شحنة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.black, fontFamily: 'monospace')),
                        SizedBox(height: 4),
                        Text('باقي ٢ للبونص 🎯', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('معدل الإنجاز:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('٩٦.٤٪', style: TextStyle(fontSize: 15, fontWeight: FontWeight.black, color: Colors.purple, fontFamily: 'monospace')),
                        SizedBox(height: 4),
                        Text('١ شحنة مؤجلة', style: TextStyle(fontSize: 10, color: AppColors.statusPostponed, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. شريط حافز البونص
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFEA580C)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تارجت البونص اليومي: ٩٠٪ مكتمل 🎯', style: TextStyle(color: Colors.white, fontWeight: FontWeight.black, fontSize: 12)),
                        Text('سلم أوردرين إضافيين واحصل على +٢٠٠ ج.م بونص فوري اليوم.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. قائمة أوردرات خط السير مع زر التأجيل الفوري
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('شحنات خط السير الحالي:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('المحطة ١ من ٤', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(child: Text('لا توجد شحنات على خط السير حالياً.'));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'monospace')),
                                StatusBadge(status: order.status),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 13)),
                                const Spacer(),
                                Text(
                                  order.isCod ? '${order.totalAmount.toStringAsFixed(2)} ج.م' : 'مدفوع إلكترونياً',
                                  style: TextStyle(fontWeight: FontWeight.black, fontSize: 12, color: order.isCod ? AppColors.accent : AppColors.statusDelivered, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${order.shippingAddress}، ${order.city}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => DriverOrderActionScreen(order: order)),
                                    ),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 10)),
                                    child: const Text('معاينة وتسليم ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton(
                                    onPressed: () => _openPostponeDialog(order),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: const BorderSide(color: AppColors.statusPostponed),
                                    ),
                                    child: const Text('⏱️ تأجيل', style: TextStyle(color: AppColors.statusPostponed, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
