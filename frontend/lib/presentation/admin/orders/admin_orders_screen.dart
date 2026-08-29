import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/driver_provider.dart';
import '../../shared/status_badge.dart';
import '../../shared/waybill_dialog.dart';
import 'widgets/create_order_modal.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGovernorate;

  void _openCreateOrder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateOrderModal(),
    );
  }

  void _showAssignDriverDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => _AssignDriverDialog(order: order),
    );
  }

  void _showBulkScanDialog() {
    showDialog(
      context: context,
      builder: (context) => const _BulkScanUpdateDialog(),
    );
  }

  void _showWaybill(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => WaybillDialog(
        order: order,
        waybillQrPayload: order.waybillQrCode ?? 'WAYBILL:${order.orderNumber}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(ordersFilterProvider);
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إدارة الأوردرات وبوالص الشحن والتوزيع', style: TextStyle(fontWeight: FontWeight.black, fontSize: 17)),
            Text(
              'توزيع الشحنات على المناديب، متابعة التحصيل، وإصدار أذونات الشحن الفورية',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _openCreateOrder,
            icon: const Icon(Icons.add_task, size: 16),
            label: const Text('إذن شحن وتوزيع جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _showBulkScanDialog,
            icon: const Icon(Icons.qr_code_scanner, size: 16),
            label: const Text('تحديث جماعي بالباركود'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => ref.refresh(ordersListProvider),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // شريط الفرز والبحث المتقدم
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // البحث العام
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'بحث فوري برقم البوليصة، اسم العميل، الهاتف، أو المندوب...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(ordersFilterProvider.notifier).state = filter.copyWith(search: '');
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (val) {
                              ref.read(ordersFilterProvider.notifier).state = filter.copyWith(search: val.trim());
                            },
                          ),
                        ),
                        const SizedBox(width: 14),

                        // فلتر المحافظات
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            value: _selectedGovernorate,
                            isDense: true,
                            decoration: const InputDecoration(labelText: 'المحافظة', isDense: true, prefixIcon: Icon(Icons.location_city)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('جميع المحافظات')),
                              ...AppConstants.egyptianGovernorates.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedGovernorate = val);
                              ref.read(ordersFilterProvider.notifier).state = filter.copyWith(search: val ?? '');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // أزرار فلاتر الحالات الـ 7
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('جميع الشحنات', null, filter.status == null),
                          ...AppConstants.orderStatusArabic.entries.map(
                            (entry) => _buildFilterChip(
                              entry.value,
                              entry.key,
                              filter.status == entry.key,
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

            // جدول البيانات المتقدم
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('خطأ في تحميل الأوردرات: $err')),
                data: (data) {
                  final List<OrderModel> orders = data['orders'] ?? [];
                  final int count = data['count'] ?? 0;

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 14),
                          const Text('لا توجد شحنات مطابقة لمعايير البحث الحالية.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _openCreateOrder,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('إصدار أول بوليصة شحن الآن'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'إجمالي الشحنات المعروضة: $count أوردر',
                                style: const TextStyle(fontWeight: FontWeight.black, fontSize: 13),
                              ),
                              const Text('مرتب حسب الأحدث أولاً', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(AppColors.surfaceElevated),
                              columns: const [
                                DataColumn(label: Text('رقم البوليصة', style: TextStyle(fontWeight: FontWeight.black))),
                                DataColumn(label: Text('العميل والمستلم', style: TextStyle(fontWeight: FontWeight.black))),
                                DataColumn(label: Text('عنوان التسليم', style: TextStyle(fontWeight: FontWeight.black))),
                                DataColumn(label: Text('حالة الشحنة', style: TextStyle(fontWeight: FontWeight.black))),
                                DataColumn(label: Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.black))),
                                DataColumn(label: Text('مندوب التوصيل', style: TextStyle(fontWeight: FontWeight.black))),
                                DataColumn(label: Text('المبلغ الإجمالي', style: TextStyle(fontWeight: FontWeight.black))),
                                DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.black))),
                              ],
                              rows: orders.map((order) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        order.orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'monospace'),
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text(order.customerPhone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace')),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          '${order.shippingAddress}، ${order.city}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    DataCell(StatusBadge(status: order.status)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: order.isCod ? AppColors.accent.withOpacity(0.12) : AppColors.statusDelivered.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          order.isCod ? 'كاش عند الاستلام' : 'دفع إلكتروني',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: order.isCod ? AppColors.accent : AppColors.statusDelivered,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.delivery_dining,
                                            size: 16,
                                            color: order.assignedDriver != null ? AppColors.primaryLight : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            order.assignedDriver?.fullName ?? 'بالمخزن (غير مسند)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: order.assignedDriver != null ? AppColors.textPrimary : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${order.totalAmount.toStringAsFixed(2)} ج.م',
                                        style: const TextStyle(fontWeight: FontWeight.black, fontSize: 13, fontFamily: 'monospace'),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.print, size: 20, color: AppColors.primary),
                                            tooltip: 'طباعة بوليصة الشحن الحرارية',
                                            onPressed: () => _showWaybill(order),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.person_add_alt_1, size: 20, color: AppColors.brandSecondary),
                                            tooltip: 'إسناد / تغيير المندوب',
                                            onPressed: () => _showAssignDriverDialog(order),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? statusValue, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        onSelected: (selected) {
          ref.read(ordersFilterProvider.notifier).state = ref.read(ordersFilterProvider).copyWith(status: statusValue);
        },
      ),
    );
  }
}

// نافذة إسناد المندوب
class _AssignDriverDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  const _AssignDriverDialog({required this.order});

  @override
  ConsumerState<_AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends ConsumerState<_AssignDriverDialog> {
  String? _selectedDriverId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversListProvider);

    return AlertDialog(
      title: Text('إسناد الشحنة #${widget.order.orderNumber} لمندوب خط السير'),
      content: SizedBox(
        width: 420,
        child: driversAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('خطأ في تحميل المناديب: $err'),
          data: (drivers) {
            return DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: const InputDecoration(labelText: 'اختر المندوب المكلف', prefixIcon: Icon(Icons.delivery_dining)),
              items: drivers.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.fullName} (${d.phone ?? "بدون هاتف"})'))).toList(),
              onChanged: (val) => setState(() => _selectedDriverId = val),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _selectedDriverId == null || _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    await ref.read(orderRepositoryProvider).assignDriver(widget.order.id, _selectedDriverId!);
                    ref.refresh(ordersListProvider);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ تم إسناد الشحنة للمندوب بنجاح!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                  } finally {
                    setState(() => _isSubmitting = false);
                  }
                },
          child: const Text('تأكيد الإسناد'),
        ),
      ],
    );
  }
}

// نافذة التحديث الجماعي بماسح الباركود
class _BulkScanUpdateDialog extends ConsumerStatefulWidget {
  const _BulkScanUpdateDialog();

  @override
  ConsumerState<_BulkScanUpdateDialog> createState() => _BulkScanUpdateDialogState();
}

class _BulkScanUpdateDialogState extends ConsumerState<_BulkScanUpdateDialog> {
  final TextEditingController _inputController = TextEditingController();
  String _targetStatus = 'In_Warehouse';
  final List<String> _scannedList = [];
  bool _isProcessing = false;

  void _addBarcode(String code) {
    final trimmed = code.trim();
    if (trimmed.isNotEmpty && !_scannedList.contains(trimmed)) {
      setState(() => _scannedList.add(trimmed));
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner, color: AppColors.accent),
          SizedBox(width: 10),
          Text('تحديث واستلام جماعي بماسح الباركود'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الحالة المستهدفة للشحنات الممسوحة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _targetStatus,
              items: const [
                DropdownMenuItem(value: 'In_Warehouse', child: Text('تحويل إلى: في المخزن والتجهيز')),
                DropdownMenuItem(value: 'Dispatched_to_Driver', child: Text('تحويل إلى: مع المندوب للتوصيل')),
                DropdownMenuItem(value: 'Returned', child: Text('تحويل إلى: مرتجع للمخزن')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _targetStatus = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'امسح الباركود بالماسح الضوئي أو اكتب واضغط Enter...',
                suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: () => _addBarcode(_inputController.text)),
              ),
              onSubmitted: _addBarcode,
            ),
            const SizedBox(height: 12),
            Text('الشحنات الممسوحة (${_scannedList.length} بوليصة):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              height: 120,
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: _scannedList.isEmpty
                  ? const Center(child: Text('جاهز لمسح البوالص بالماسح الضوئي...', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: _scannedList.length,
                      itemBuilder: (ctx, i) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        title: Text(_scannedList[i], style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                        trailing: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _scannedList.removeAt(i))),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _scannedList.isEmpty || _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);
                  try {
                    final res = await ref.read(orderRepositoryProvider).bulkScanUpdate(_scannedList, _targetStatus);
                    ref.refresh(ordersListProvider);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ تم تحديث ${res["updatedCount"]} شحنة بنجاح!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                  } finally {
                    setState(() => _isProcessing = false);
                  }
                },
          child: Text('تحديث ${_scannedList.length} شحنة'),
        ),
      ],
    );
  }
}
