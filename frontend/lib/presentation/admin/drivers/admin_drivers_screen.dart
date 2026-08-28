import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/driver_ledger_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/driver_provider.dart';

class AdminDriversScreen extends ConsumerStatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  ConsumerState<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends ConsumerState<AdminDriversScreen> {
  void _showSettlementDialog(DriverBalanceModel driverBalance) {
    showDialog(
      context: context,
      builder: (context) => _SettlementPayoutDialog(driverBalance: driverBalance),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driversSummaryAsync = ref.watch(allDriversSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المناديب وحساب العهدة وتوريد النقدية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => ref.refresh(allDriversSummaryProvider),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: driversSummaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('خطأ في تحميل بيانات حسابات المناديب: $err')),
          data: (summaries) {
            if (summaries.isEmpty) {
              return const Center(child: Text('لا يوجد مناديب مسجلين بالنظام.'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'كشف حساب العهدة النقدية والعمولات للمناديب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: summaries.length,
                    itemBuilder: (context, idx) {
                      final item = summaries[idx];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        child: const Icon(Icons.person, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.driverName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            'كود المندوب: ${item.driverId.substring(0, 8)}...',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showSettlementDialog(item),
                                    icon: const Icon(Icons.handshake_outlined, size: 16),
                                    label: const Text('توريد عهدة كاش'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildFinanceMetric(
                                    'كاش مع المندوب',
                                    '${item.currentCashInHandToHandover.toStringAsFixed(2)} ج.م',
                                    AppColors.accent,
                                  ),
                                  _buildFinanceMetric(
                                    'العمولات المستحقة',
                                    '+${item.totalCommissionEarned.toStringAsFixed(2)} ج.م',
                                    AppColors.statusDelivered,
                                  ),
                                  _buildFinanceMetric(
                                    'إجمالي المبالغ الموردة',
                                    '${item.totalSettledPayouts.toStringAsFixed(2)} ج.م',
                                    AppColors.primaryLight,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFinanceMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// نافذة توريد النقدية بالخزينة
class _SettlementPayoutDialog extends ConsumerStatefulWidget {
  final DriverBalanceModel driverBalance;

  const _SettlementPayoutDialog({required this.driverBalance});

  @override
  ConsumerState<_SettlementPayoutDialog> createState() => _SettlementPayoutDialogState();
}

class _SettlementPayoutDialogState extends ConsumerState<_SettlementPayoutDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.driverBalance.currentCashInHandToHandover.toStringAsFixed(2);
    _descController.text = 'توريد نقدية خط سير اليوم للمندوب ${widget.driverBalance.driverName}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('توريد عهدة نقدية: ${widget.driverBalance.driverName}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'العهدة النقدية الحالية مع المندوب: ${widget.driverBalance.currentCashInHandToHandover.toStringAsFixed(2)} ج.م',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ المورد للخزينة (ج.م)',
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'بيان التوريد / رقم إيصال الاستلام',
                prefixIcon: Icon(Icons.description),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  final amount = double.tryParse(_amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);
                  try {
                    await ref.read(driverLedgerRepositoryProvider).recordSettlementPayout(
                          widget.driverBalance.driverId,
                          amount,
                          _descController.text.trim(),
                        );
                    ref.refresh(allDriversSummaryProvider);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم تسجيل توريد مبلغ $amount ج.م بالخزينة بنجاح!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل التسجيل: $e')),
                    );
                  } finally {
                    setState(() => _isSubmitting = false);
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('تأكيد استلام النقدية بالخزينة'),
        ),
      ],
    );
  }
}
