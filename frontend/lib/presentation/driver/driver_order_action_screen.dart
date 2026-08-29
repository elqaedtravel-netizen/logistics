import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../shared/status_badge.dart';
import '../shared/swipe_to_action_button.dart';
import '../shared/order_timeline_widget.dart';

class DriverOrderActionScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const DriverOrderActionScreen({super.key, required this.order});

  @override
  ConsumerState<DriverOrderActionScreen> createState() => _DriverOrderActionScreenState();
}

class _DriverOrderActionScreenState extends ConsumerState<DriverOrderActionScreen> {
  bool _isSubmitting = false;

  void _callCustomer() async {
    final phone = widget.order.customerPhone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openGoogleMaps() async {
    final query = Uri.encodeComponent('${widget.order.shippingAddress}, ${widget.order.city}, Egypt');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _handleSwipeDelivery() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(orderRepositoryProvider).deliverOrder(
            widget.order.id,
            notes: 'تم التسليم باليد للعميل وتأكيد تحصيل المبلغ عبر تطبيق المندوب.',
          );
      ref.refresh(driverAssignedOrdersProvider(null));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تم تأكيد التسليم وتحصيل العهدة النقدية بنجاح!'),
          backgroundColor: AppColors.statusDelivered,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تأكيد التسليم: $e'), backgroundColor: AppColors.statusCanceled),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPostponeDialog() {
    String selectedReason = AppConstants.postponementReasons.first['code']!;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.statusPostponed),
              SizedBox(width: 8),
              Text('تأجيل موعد تسليم الأوردر'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سبب التأجيل الإلزامي لتقرير خط السير:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  items: AppConstants.postponementReasons.map((r) {
                    return DropdownMenuItem(value: r['code'], child: Text(r['label']!, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات المندوب (مثال: طلب موعد بديل غداً)', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPostponed),
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isSubmitting = true);
                try {
                  await ref.read(orderRepositoryProvider).postponeOrder(
                        widget.order.id,
                        selectedReason,
                        notes: notesController.text.trim(),
                      );
                  ref.refresh(driverAssignedOrdersProvider(null));
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⏱️ تم تأجيل الشحنة وإعادة الجدولة بنجاح.'), backgroundColor: AppColors.statusPostponed),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              child: const Text('تأكيد التأجيل'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('شحنة #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة رأس الأوردر والمبلغ
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: order.status, fontSize: 13),
                        Text(
                          order.isCod ? 'تحصيل كاش' : 'مدفوع أونلاين',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: order.isCod ? AppColors.accent : AppColors.statusDelivered,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المبلغ المطلوب تحصيله باليد:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('يشمل مصاريف الشحن', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                        Text(
                          order.isCod ? '${order.totalAmount.toStringAsFixed(2)} ج.م' : '٠.٠٠ ج.م',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.black,
                            color: order.isCod ? AppColors.accent : AppColors.statusDelivered,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // بطاقة بيانات العميل وأزرار الاتصال والموقع
            Card(
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
                            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(order.customerPhone, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace', fontSize: 13)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton.filled(
                              onPressed: _openGoogleMaps,
                              icon: const Icon(Icons.navigation, color: Colors.white, size: 20),
                              style: IconButton.styleFrom(backgroundColor: AppColors.brandSecondary),
                              tooltip: 'فتح خرائط جوجل',
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _callCustomer,
                              icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                              style: IconButton.styleFrom(backgroundColor: AppColors.statusDelivered),
                              tooltip: 'اتصال هاتفي بالعميل',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${order.shippingAddress}، ${order.city}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الخط الزمني لمراحل الشحنة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تتبع مراحل ودورة الشحنة:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                    const Divider(height: 20),
                    OrderTimelineWidget(currentStatus: order.status, timelineHistory: const []),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // أزرار الإجراءات التفاعلية (Swipe to deliver)
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else if (order.status != 'Delivered') ...[
              SwipeToActionButton(
                text: order.isCod
                    ? 'اسحب لتأكيد التسليم وتحصيل الكاش'
                    : 'اسحب لتأكيد تسليم الأوردر للعميل',
                onSwiped: _handleSwipeDelivery,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showPostponeDialog,
                icon: const Icon(Icons.schedule, color: AppColors.statusPostponed),
                label: const Text('تأجيل موعد التسليم (تسجيل سبب إلزامي)', style: TextStyle(color: AppColors.statusPostponed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.statusPostponed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.statusDelivered.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.statusDelivered),
                    SizedBox(width: 8),
                    Text('تم تسليم هذا الأوردر بنجاح وتم توريد حسابه.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusDelivered)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
