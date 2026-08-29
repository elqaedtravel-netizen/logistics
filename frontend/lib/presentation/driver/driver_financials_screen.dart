import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/driver_provider.dart';

class DriverFinancialsScreen extends ConsumerStatefulWidget {
  final String? driverId;

  const DriverFinancialsScreen({super.key, this.driverId});

  @override
  ConsumerState<DriverFinancialsScreen> createState() => _DriverFinancialsScreenState();
}

class _DriverFinancialsScreenState extends ConsumerState<DriverFinancialsScreen> {
  void _openPayoutDialog(double cashBalance) {
    final refController = TextEditingController(text: 'INSTA-TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    String selectedMethod = 'تحويل فوري عبر إنستاباي InstaPay لحساب الشركة';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.account_balance, color: AppColors.secondary),
              SizedBox(width: 10),
              Text('توريد العهدة النقدية لإدارة الشركة'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المبلغ المطلوب توريده:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('${cashBalance.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 16, color: AppColors.accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('اختر وسيلة التوريد والسداد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'تحويل فوري عبر إنستاباي InstaPay لحساب الشركة', child: Text('تحويل فوري عبر إنستاباي InstaPay', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'تحويل محفظة إلكترونية فودافون كاش لشركة أنتيجرافيتي', child: Text('محفظة إلكترونية (فودافون كاش)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'إيداع بنكي مباشر في حساب البنك الأهلي / CIB', child: Text('إيداع بنكي بحساب الشركة (CIB / NBE)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'تسليم كاش مباشر في خزينة الفرع الرئيسي', child: Text('تسليم نقدية كاش بخزينة الفرع', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMethod = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refController,
                  decoration: const InputDecoration(labelText: 'رقم المرجع أو إيصال التحويل (Ref No)', prefixIcon: Icon(Icons.receipt)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                        await ref.read(driverLedgerRepositoryProvider).recordSettlementPayout(
                              widget.driverId ?? 'default_driver',
                              cashBalance,
                              'تم التوريد عبر: $selectedMethod | مرجع: ${refController.text.trim()}',
                            );
                        ref.refresh(driverFinancialsProvider(widget.driverId));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ تم تسجيل توريد العهدة النقدية بنجاح!'), backgroundColor: AppColors.statusDelivered),
                        );

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                      }
                    },
              child: const Text('تأكيد التوريد للخزينة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financialsAsync = ref.watch(driverFinancialsProvider(widget.driverId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حساب العهدة النقدية وتوريد المبالغ', style: TextStyle(fontWeight: FontWeight.black)),
      ),
      body: financialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('خطأ في تحميل البيانات المالية: $err')),
        data: (data) {
          final double cashBalance = (data['cashBalanceEgp'] ?? 14500.0).toDouble();
          final double commissionBalance = (data['commissionEarnedEgp'] ?? 1450.0).toDouble();
          final List<dynamic> history = data['settlementHistory'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // كارت العهدة وزر التوريد
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('العهدة النقدية المحصلة (كاش مع المندوب):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                            Icon(Icons.payments, color: AppColors.accent, size: 24),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${cashBalance.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.black, color: AppColors.accent, fontFamily: 'monospace'),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('العمولة المكتسبة:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                Text('${commissionBalance.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 16, color: AppColors.statusDelivered)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openPayoutDialog(cashBalance),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                              icon: const Icon(Icons.send_to_mobile, size: 18),
                              label: const Text('توريد العهدة للشركة', style: TextStyle(fontWeight: FontWeight.black)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // سجل التوريدات السابقة
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('سجل عمليات توريد العهدة النقدية السابقة:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                        const Divider(height: 20),
                        if (history.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('لا توجد عمليات توريد سابقة مسجلة.')),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: history.length,
                            separatorBuilder: (_, __) => const Divider(height: 12),
                            itemBuilder: (ctx, i) {
                              final item = history[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.check_circle, color: AppColors.statusDelivered),
                                title: Text('${item['amount']} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(item['notes'] ?? 'توريد نقدية'),
                                trailing: Text(item['date'] ?? 'اليوم', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
