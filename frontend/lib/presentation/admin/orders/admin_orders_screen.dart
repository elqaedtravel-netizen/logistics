import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/orders_provider.dart';
import '../../providers/driver_provider.dart';
import '../../shared/status_badge.dart';
import '../../shared/waybill_dialog.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

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
        title: const Text('إدارة الأوردرات والتوزيع للمناديب'),
        actions: [
          ElevatedButton.icon(
            onPressed: _showBulkScanDialog,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('تحديث جماعي بماسح الباركود'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
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
            // شريط البحث والفلترة
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث برقم الأوردر، اسم العميل، الهاتف...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(ordersFilterProvider.notifier).state =
                                        filter.copyWith(search: '');
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (val) {
                          ref.read(ordersFilterProvider.notifier).state =
                              filter.copyWith(search: val.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('جميع الحالات', null, filter.status == null),
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // جدول الأوردرات
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
                          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('لا توجد أوردرات مطابقة لخيارات البحث الحالية.'),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'عرض $count أوردر',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(AppColors.surfaceElevated),
                              columns: const [
                                DataColumn(label: Text('رقم البوليصة / الأوردر', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('عنوان التوصيل', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('طريقة الدفع', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المندوب', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المبلغ الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: orders.map((order) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        order.orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(order.customerPhone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 140,
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(order.isCod ? 'دفع عند الاستلام (كاش)' : 'دفع إلكتروني', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                          Text(order.isPaid ? 'تم الدفع' : 'غير مدفوع', style: TextStyle(fontSize: 10, color: order.isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        order.assignedDriver?.fullName ?? 'لم يحدد مندوب',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: order.assignedDriver != null ? AppColors.textPrimary : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${order.totalAmount.toStringAsFixed(2)} ج.م',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.qr_code, size: 20, color: AppColors.primary),
                                            tooltip: 'بوليصة الشحن وباركود QR',
                                            onPressed: () => _showWaybill(order),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.person_add_outlined, size: 20, color: AppColors.secondary),
                                            tooltip: 'إسناد للمندوب',
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
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary)),
        selected: isSelected,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          ref.read(ordersFilterProvider.notifier).state =
              ref.read(ordersFilterProvider).copyWith(status: statusValue);
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
      title: Text('إسناد الأوردر #${widget.order.orderNumber} لمندوب التوصيل'),
      content: SizedBox(
        width: 400,
        child: driversAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('خطأ في تحميل المناديب: $err'),
          data: (drivers) {
            if (drivers.isEmpty) {
              return const Text('لا يوجد مناديب متاحين حالياً.');
            }
            return DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: const InputDecoration(
                labelText: 'اختر المندوب',
                prefixIcon: Icon(Icons.delivery_dining),
              ),
              items: drivers.map((d) {
                return DropdownMenuItem<String>(
                  value: d.id,
                  child: Text('${d.fullName} (${d.phone ?? "بدون هاتف"})'),
                );
              }).toList>,
              onChanged: (val) {
                setState(() {
                  _selectedDriverId = val;
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _selectedDriverId == null || _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    await ref.read(orderRepositoryProvider).assignDriver(
                          widget.order.id,
                          _selectedDriverId!,
                        );
                    ref.refresh(ordersListProvider);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إسناد الأوردر وتحديث الحالة إلى "مع المندوب" بنجاح!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل الإسناد: $e')),
                    );
                  } finally {
                    setState(() => _isSubmitting = false);
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('تأكيد الإسناد'),
        ),
      ],
    );
  }
}

// نافذة التوزيع الجماعي بماسح الباركود
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
      setState(() {
        _scannedList.add(trimmed);
      });
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner, color: AppColors.secondary),
          SizedBox(width: 10),
          Text('توزيع وتحديث جماعي بماسح الباركود'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الحالة المستهدفة للأوردرات الممسوحة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _targetStatus,
              decoration: const InputDecoration(isDense: true),
              items: const [
                DropdownMenuItem(value: 'In_Warehouse', child: Text('تحويل إلى: في المخزن')),
                DropdownMenuItem(value: 'Dispatched_to_Driver', child: Text('تحويل إلى: مع المندوب')),
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
                hintText: 'امسح بوليصة الشحن بالماسح الضوئي أو اكتب واضغط Enter',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addBarcode(_inputController.text),
                ),
              ),
              onSubmitted: _addBarcode,
            ),
            const SizedBox(height: 12),
            Text(
              'قائمة الشحنات الممسوحة (${_scannedList.length} شحنة):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceElevated,
              ),
              child: _scannedList.isEmpty
                ? const Center(child: Text('امسح البوالص باستخدام ماسح الباركود المتصل...', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    itemCount: _scannedList.length,
                    itemBuilder: (ctx, i) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                      title: Text(_scannedList[i], style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => setState(() => _scannedList.removeAt(i)),
                      ),
                    ),
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
          onPressed: _scannedList.isEmpty || _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);
                  try {
                    final res = await ref.read(orderRepositoryProvider).bulkScanUpdate(
                          _scannedList,
                          _targetStatus,
                        );
                    ref.refresh(ordersListProvider);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم تحديث ${res["updatedCount"]} أوردر بنجاح!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  } finally {
                    setState(() => _isProcessing = false);
                  }
                },
          child: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('تحديث ${_scannedList.length} أوردر'),
        ),
      ],
    );
  }
}
