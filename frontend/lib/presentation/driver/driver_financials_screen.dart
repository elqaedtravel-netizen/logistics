import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/driver_ledger_model.dart';
import '../providers/driver_provider.dart';

class DriverFinancialsScreen extends ConsumerWidget {
  const DriverFinancialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(driverMyBalanceProvider);
    final statementAsync = ref.watch(driverMyStatementProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(driverMyBalanceProvider);
          ref.refresh(driverMyStatementProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كارت المحفظة والعهدة النقدية
              balanceAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('خطأ في تحميل رصيد العهدة: $err'),
                  ),
                ),
                data: (balance) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'العهدة النقدية المحصلة (كاش مع المندوب)',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.account_balance_wallet, color: Colors.white70),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${balance.currentCashInHandToHandover.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'مبالغ جاهزة للتوريد والتصفية بخزينة مخزن القاهرة الرئيسي',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('إجمالي العمولات المستحقة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '+${balance.totalCommissionEarned.toStringAsFixed(2)} ج.م',
                                  style: const TextStyle(color: AppColors.statusDelivered, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('إجمالي المبالغ الموردة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '${balance.totalSettledPayouts.toStringAsFixed(2)} ج.م',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // كشف الحساب التفصيلي
              const Text(
                'سجل الحركات المالية وتوريد العهدة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              statementAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('خطأ في تحميل كشف الحساب: $err')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('لا توجد حركات مالية مسجلة حتى الآن.'),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = entries[idx];
                      final isCashIn = item.transactionType == 'CASH_COLLECTED';
                      final isCommission = item.transactionType == 'COMMISSION_EARNED';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCashIn
                                ? AppColors.accent.withOpacity(0.15)
                                : isCommission
                                    ? AppColors.statusDelivered.withOpacity(0.15)
                                    : AppColors.primaryLight.withOpacity(0.15),
                            child: Icon(
                              isCashIn
                                  ? Icons.arrow_downward
                                  : isCommission
                                      ? Icons.star_border
                                      : Icons.handshake,
                              color: isCashIn
                                  ? AppColors.accent
                                  : isCommission
                                      ? AppColors.statusDelivered
                                      : AppColors.primaryLight,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _translateTransactionDescription(item.description),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            '${item.createdAt.toLocal().toString().split('.')[0]} | مرجع: ${item.referenceCode ?? "N/A"}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isCashIn ? "+" : ""}${item.amount.toStringAsFixed(2)} ج.م',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isCommission
                                      ? AppColors.statusDelivered
                                      : isCashIn
                                          ? AppColors.textPrimary
                                          : AppColors.primaryLight,
                                ),
                              ),
                              Text(
                                'الرصيد: ${item.runningBalance.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
      ),
    );
  }

  String _translateTransactionDescription(String desc) {
    if (desc.contains('COD collected for delivered order')) {
      return desc.replaceAll('COD collected for delivered order', 'تحصيل كاش لأوردر مسلم رقم');
    }
    if (desc.contains('Delivery commission')) {
      return desc.replaceAll('Delivery commission', 'عمولة تسليم أوردر رقم');
    }
    return desc;
  }
}
