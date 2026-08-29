import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../providers/driver_provider.dart';
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
  final _cashReceivedController = TextEditingController(text: '2000');
  double _changeAmount = 500.0;
  bool _photoPodTaken = false;
  bool _signatureTaken = false;
  bool _isSubmitting = false;

  // Partial Delivery state
  bool _isPartialDeliveryMode = false;
  double _adjustedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _adjustedAmount = widget.order.totalAmount;
    _recalculateChange();
  }

  void _recalculateChange() {
    final received = double.tryParse(_cashReceivedController.text.trim()) ?? 0.0;
    final required = _isPartialDeliveryMode ? _adjustedAmount : widget.order.totalAmount;
    setState(() {
      _changeAmount = (received - required).clamp(0.0, double.infinity);
    });
  }

  void _callCustomer() async {
    final phone = widget.order.customerPhone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openGoogleMaps() async {
    final query = Uri.encodeComponent('${widget.order.shippingAddress}, ${widget.order.city}, Egypt');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _takePhotoPod() {
    setState(() => _photoPodTaken = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📷 تم التقاط صورة إثبات التسليم (Photo POD) بنجاح!'), backgroundColor: AppColors.statusDelivered),
    );
  }

  void _takeSignature() {
    setState(() => _signatureTaken = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✍️ تم تسجيل توقيع العميل الإلكتروني بنجاح!'), backgroundColor: AppColors.statusDelivered),
    );
  }

  void _openPartialDeliveryModal() {
    double item1Price = 1450.0;
    double item2Price = 500.0;
    bool item1Accepted = true;
    bool item2Accepted = false; // العميل رفض الصنف الثاني

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final calculated = (item1Accepted ? item1Price : 0.0) + (item2Accepted ? item2Price : 0.0) + 50.0; // شامل الشحن

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.checklist, color: AppColors.primary),
                SizedBox(width: 8),
                Text('تسليم جزئي (تعديل الأصناف على أرض الواقع)'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حدد الأصناف التي استلمها العميل والأصناف المرفوضة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    dense: true,
                    value: item1Accepted,
                    title: const Text('سماعات بلوتوث ANC Pro (١,٤٥٠ ج.م)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text(item1Accepted ? '✓ تم الاستلام' : '❌ مرفوض (مرتجع للمخزن)'),
                    onChanged: (v) => setDialogState(() => item1Accepted = v!),
                  ),
                  CheckboxListTile(
                    dense: true,
                    value: item2Accepted,
                    title: const Text('شاحن سريع MagSafe (٥٠٠ ج.م)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text(item2Accepted ? '✓ تم الاستلام' : '❌ مرفوض (مرتجع للمخزن RTO)'),
                    onChanged: (v) => setDialogState(() => item2Accepted = v!),
                  ),
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ المعدل المطلوب تحصيله:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${calculated.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 16, color: AppColors.accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () {
                  setState(() {
                    _isPartialDeliveryMode = true;
                    _adjustedAmount = calculated;
                    _recalculateChange();
                  });
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تعديل المبلغ المطلوب إلى ${_adjustedAmount.toStringAsFixed(2)} ج.م بناءً على التسليم الجزئي.')),
                  );
                },
                child: const Text('تأكيد التعديل وإعادة الحساب'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSwipeDelivery() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(orderRepositoryProvider).deliverOrder(
            widget.order.id,
            notes: _isPartialDeliveryMode
                ? 'تسليم جزئي معدل: تم تحصيل $_adjustedAmount ج.م ورفض باقي الأصناف المرتجعة.'
                : 'تسليم كامل مع إثبات وتوقيع العميل وتحصيل المبلغ.',
          );
      ref.refresh(driverAssignedOrdersProvider(null));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPartialDeliveryMode ? '✅ تم تأكيد التسليم الجزئي وتعديل حساب التاجر!' : '🎉 مبروك! تم تأكيد التسليم بنجاح!'),
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

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final currentAmount = _isPartialDeliveryMode ? _adjustedAmount : order.totalAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('شحنة #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.black)),
        actions: [
          TextButton.icon(
            onPressed: _openPartialDeliveryModal,
            icon: const Icon(Icons.tune, size: 16, color: AppColors.accent),
            label: const Text('تسليم جزئي', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. بطاقة رأس الأوردر والمبلغ المطلوب
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: _isPartialDeliveryMode ? 'Partially_Delivered' : order.status, fontSize: 13),
                        Text(
                          order.isCod ? 'تحصيل كاش باليد' : 'مدفوع إلكترونياً',
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isPartialDeliveryMode ? 'المبلغ بعد التسليم الجزئي:' : 'المبلغ المطلوب تحصيله:', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(_isPartialDeliveryMode ? 'تم خصم الأصناف المرفوضة' : 'شامل مصاريف الشحن', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                        Text(
                          order.isCod ? '${currentAmount.toStringAsFixed(2)} ج.م' : '٠.٠٠ ج.م',
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

            // 2. بطاقة العميل والتواصل
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                              icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                              style: IconButton.styleFrom(backgroundColor: AppColors.brandSecondary),
                              tooltip: 'خرائط جوجل',
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _callCustomer,
                              icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                              style: IconButton.styleFrom(backgroundColor: AppColors.statusDelivered),
                              tooltip: 'اتصال هاتفي',
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

            // 3. أدوات إثبات التسليم (Photo POD & Signature)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takePhotoPod,
                        icon: Icon(_photoPodTaken ? Icons.check_circle : Icons.camera_alt, color: _photoPodTaken ? AppColors.statusDelivered : AppColors.primary),
                        label: Text(_photoPodTaken ? 'تم تصوير التسليم ✓' : 'تصوير إثبات تسليم', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takeSignature,
                        icon: Icon(_signatureTaken ? Icons.check_circle : Icons.draw, color: _signatureTaken ? AppColors.statusDelivered : AppColors.primary),
                        label: Text(_signatureTaken ? 'تم التوقيع ✓' : 'توقيع العميل', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. الخط الزمني لمراحل الشحنة
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                text: 'اسحب لتأكيد التسليم وتحصيل ${currentAmount.toStringAsFixed(2)} ج.م',
                onSwiped: _handleSwipeDelivery,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل سبب التأجيل وإحداثيات الموقع بنجاح.'), backgroundColor: AppColors.statusPostponed),
                  );
                },
                icon: const Icon(Icons.schedule, color: AppColors.statusPostponed),
                label: const Text('تأجيل موعد التسليم مع تسجيل الموقع GPS', style: TextStyle(color: AppColors.statusPostponed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.statusPostponed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
