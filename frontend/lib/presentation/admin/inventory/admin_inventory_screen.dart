import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../providers/products_provider.dart';
import 'widgets/add_product_modal.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _openAddProduct() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddProductModal(),
    );
  }

  void _showQrLabelDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => _ProductQrLabelDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productsFilterProvider);
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المخزن وإصدار باركود الأصناف (Warehouse & Stock)', style: TextStyle(fontWeight: FontWeight.black, fontSize: 17)),
            Text(
              'أرصدة المخزون، تنبيهات النواقص، تسعير التكلفة والبيع، وطباعة ملصقات الباركود QR',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _openAddProduct,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('إضافة صنف جديد للمخزن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => ref.refresh(productsListProvider),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // شريط البحث وتصنيف الأقسام
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث فوري بكود الصنف (SKU) أو اسم المنتج أو مكان التخزين...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(productsFilterProvider.notifier).state = filter.copyWith(search: '');
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (val) {
                          ref.read(productsFilterProvider.notifier).state = filter.copyWith(search: val.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: filter.category,
                        isDense: true,
                        decoration: const InputDecoration(labelText: 'القسم / التصنيف', isDense: true, prefixIcon: Icon(Icons.category)),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('جميع الأقسام والتصنيفات')),
                          DropdownMenuItem(value: 'إلكترونيات', child: Text('إلكترونيات')),
                          DropdownMenuItem(value: 'أجهزة ذكية', child: Text('أجهزة ذكية')),
                          DropdownMenuItem(value: 'ملابس وأزياء', child: Text('ملابس وأزياء')),
                          DropdownMenuItem(value: 'مستلزمات منزلية', child: Text('مستلزمات منزلية')),
                          DropdownMenuItem(value: 'إكسسوارات', child: Text('إكسسوارات')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(productsFilterProvider.notifier).state = filter.copyWith(category: val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // جدول بيانات المخزون
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('خطأ في تحميل الأصناف: $err')),
                data: (products) {
                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 14),
                          const Text('لا توجد أصناف مسجلة في هذا القسم بالمخزن.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _openAddProduct,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('إضافة أول صنف الآن'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.surfaceElevated),
                        columns: const [
                          DataColumn(label: Text('كود الصنف (SKU)', style: TextStyle(fontWeight: FontWeight.black))),
                          DataColumn(label: Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.black))),
                          DataColumn(label: Text('القسم', style: TextStyle(fontWeight: FontWeight.black))),
                          DataColumn(label: Text('سعر البيع', style: TextStyle(fontWeight: FontWeight.black))),
                          DataColumn(label: Text('سعر التكلفة', style: TextStyle(fontWeight: FontWeight.black))),
                          DataColumn(label: Text('الرصيد المتاح', style: TextStyle(fontWeight: FontWeight.black))),
                          DataColumn(label: Text('موقع التخزين والرف', style: TextStyle(fontWeight: FontWeight.black))),
                          DataColumn(label: Text('ملصق QR', style: TextStyle(fontWeight: FontWeight.black))),
                        ],
                        rows: products.map((prod) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  prod.sku,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'monospace'),
                                ),
                              ),
                              DataCell(
                                Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
                                  child: Text(prod.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataCell(
                                Text('${prod.price.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.black, fontFamily: 'monospace')),
                              ),
                              DataCell(
                                Text('${prod.costPrice.toStringAsFixed(2)} ج.م', style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace')),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: prod.isLowStock ? AppColors.statusCanceled.withOpacity(0.12) : AppColors.statusDelivered.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        prod.isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                        size: 14,
                                        color: prod.isLowStock ? AppColors.statusCanceled : AppColors.statusDelivered,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${prod.stockQuantity} قطعة',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: prod.isLowStock ? AppColors.statusCanceled : AppColors.statusDelivered,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(prod.warehouseLocation, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.qr_code, color: AppColors.primary),
                                  tooltip: 'معاينة وطباعة ملصق الباركود الحراري',
                                  onPressed: () => _showQrLabelDialog(prod),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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
}

// نافذة معاينة وطباعة ملصق الباركود
class _ProductQrLabelDialog extends StatelessWidget {
  final ProductModel product;
  const _ProductQrLabelDialog({required this.product});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ملصق باركود QR للصنف: ${product.sku}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: product.barcodeQrData ?? 'SKU:${product.sku}',
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('سعر البيع: ${product.price.toStringAsFixed(2)} ج.م', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            Text('الموقع: ${product.warehouseLocation}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ تم إرسال أمر طباعة الملصق الحراري للصنف ${product.sku}')),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.print, size: 16),
          label: const Text('طباعة ملصق حراري'),
        ),
      ],
    );
  }
}
