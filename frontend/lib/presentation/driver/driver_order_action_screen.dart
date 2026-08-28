import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../shared/status_badge.dart';

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

  void _showDeliverDialog() {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.statusDelivered),
            SizedBox(width: 8),
            Text('تأكيد تسليم الأوردر للعميل'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أوردر رقم: #${widget.order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (widget.order.isCod)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تأكد من تحصيل مبلغ ${widget.order.totalAmount.toStringAsFixed(2)} ج.م نقداً من العميل.',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('✅ مدفوع أونلاين. لا يتم تحصيل أي مبالغ نقدية.'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات التسليم (اختياري)',
                hintText: 'مثال: تم الاستلام باليد والتوقيع على البوليصة',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isSubmitting = true);
              try {
                await ref.read(orderRepositoryProvider).deliverOrder(
                      widget.order.id,
                      notes: notesController.text.trim(),
                    );
                ref.refresh(driverAssignedOrdersProvider(null));
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تسليم الأوردر وتحديث العهدة النقدية بنجاح!'),
                    backgroundColor: AppColors.statusDelivered,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل التسليم: $e')),
                );
              } finally {
                setState(() => _isSubmitting = false);
              }
            },
            child: const Text('تأكيد التسليم'),
          ),
        ],
      ),
    );
  }

  void _showPostponeDialog() {
    String selectedReason = AppConstants.postponementReasons.first['code']!;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.statusPostponed),
              SizedBox(width: 8),
              Text('تأجيل موعد تسليم الأوردر'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر سبب التأجيل الإلزامي:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: AppConstants.postponementReasons.map((r) {
                      return DropdownMenuItem<String>(
                        value: r['code'],
                        child: Text(
                          r['label']!,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات المندوب التشغيلية',
                      hintText: 'مثال: طلب العميل إعادة المحاولة غداً بعد الساعة ٤ عصراً',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
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
                    const SnackBar(
                      content: Text('تم تسجيل تأجيل الأوردر وإعادة الجدولة.'),
                      backgroundColor: AppColors.statusPostponed,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل التأجيل: $e')),
                  );
                } finally {
                  setState(() => _isSubmitting = false);
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
      appBar: AppBar(
        title: Text('أوردر #${order.orderNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // كارت الحالة والمبلغ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('حالة الشحنة', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        StatusBadge(status: order.status),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('المبلغ المطلوب تحصيله', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          order.isCod ? '${order.totalAmount.toStringAsFixed(2)} ج.م' : '٠.٠٠ ج.م (مدفوع)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: order.isCod ? AppColors.accent : AppColors.statusDelivered,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // كارت العميل وعنوان التوصيل
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات العميل ومكان التوصيل',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(order.customerPhone, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _callCustomer,
                          icon: const Icon(Icons.phone, color: Colors.white),
                          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${order.shippingAddress}، ${order.city}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // محتويات الشحنة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('محتويات الأوردر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...order.items.map(
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('• ${i.productName} (العدد: ${i.quantity})'),
                            Text('${i.totalPrice.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // أزرار الإجراءات
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _showDeliverDialog,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(order.isCod ? 'تحصيل الكاش وتأكيد التسليم' : 'تأكيد تسليم الأوردر للعميل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusDelivered,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showPostponeDialog,
                icon: const Icon(Icons.schedule, color: AppColors.statusPostponed),
                label: const Text('تأجيل موعد التسليم (يتطلب تحديد سبب)', style: TextStyle(color: AppColors.statusPostponed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.statusPostponed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
