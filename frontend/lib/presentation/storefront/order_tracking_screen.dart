import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/orders_provider.dart';
import '../shared/status_badge.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String? initialOrderNumber;

  const OrderTrackingScreen({super.key, this.initialOrderNumber});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchedOrder = 'ORD-2026-10001';

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderNumber != null) {
      _searchedOrder = widget.initialOrderNumber!;
      _searchController.text = widget.initialOrderNumber!;
    } else {
      _searchController.text = _searchedOrder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingAsync = ref.watch(orderTrackingProvider(_searchedOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع مسار وحالة الشحنة لحظياً'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // مربع البحث
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'أدخل رقم الأوردر أو البوليصة',
                              hintText: 'مثال: ORD-2026-10001',
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setState(() => _searchedOrder = val.trim());
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_searchController.text.trim().isNotEmpty) {
                              setState(() => _searchedOrder = _searchController.text.trim());
                            }
                          },
                          child: const Text('تتبع الشحنة'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // نتائج التتبع
                trackingAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('الأوردر "$_searchedOrder" غير مسجل بالنظام.', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('يرجى التأكد من كتابة رقم البوليصة بشكل صحيح كما هو موضح في رسالة التأكيد.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  data: (data) {
                    final currentStatus = data['current_status'] ?? 'Pending';
                    final assignedDriver = data['assigned_driver'];
                    final List<dynamic> timeline = data['timeline'] ?? [];

                    return Column(
                      children: [
                        // كارت ملخص الحالة
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
                                        Text(
                                          data['order_number'] ?? '',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        Text(
                                          'العميل: ${data['customer_name']}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    StatusBadge(status: currentStatus, fontSize: 13),
                                  ],
                                ),
                                const Divider(height: 24),

                                // بيانات المندوب القائم بالتوصيل
                                if (assignedDriver != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primaryLight,
                                          child: const Icon(Icons.delivery_dining, color: Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('مندوب التوصيل المكلف بخط السير', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              Text(
                                                assignedDriver['name'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              Text(
                                                'هاتف المندوب: ${assignedDriver['phone'] ?? "غير متوفر"}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // كارت خط زمني لحركة الشحنة
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المراحل الزمنية للشحنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(height: 24),
                                if (timeline.isEmpty)
                                  const Text('لا توجد تحديثات زمنية مسجلة بعد.')
                                else
                                  ...timeline.map((step) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(top: 2),
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: AppColors.primaryLight,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    StatusBadge(status: step['status'] ?? ''),
                                                    Text(
                                                      step['timestamp'] != null
                                                          ? step['timestamp'].toString().split('T')[0]
                                                          : '',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  step['notes'] ?? '',
                                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                                ),
                                                if (step['reason_code'] != null)
                                                  Text(
                                                    'سبب التأجيل: ${step['reason_code']}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.statusPostponed, fontWeight: FontWeight.bold),
                                                  ),
                                              ],
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
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
