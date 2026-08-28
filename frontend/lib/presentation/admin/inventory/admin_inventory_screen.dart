import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../providers/products_provider.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddProductDialog(),
    );
  }

  void _showQrLabelDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => _ProductQrLabelDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productsFilterProvider);
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المخزن وإصدار باركود الأصناف'),
        actions: [
          ElevatedButton.icon(
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة منتج جديد للمخزن'),
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
            // شريط البحث
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث بكود الصنف (SKU) أو اسم المنتج...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(productsFilterProvider.notifier).state =
                                        filter.copyWith(search: '');
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (val) {
                          ref.read(productsFilterProvider.notifier).state =
                              filter.copyWith(search: val.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // جدول المنتجات والمخزون
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('خطأ في تحميل الأصناف: $err')),
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text('لا توجد أصناف مسجلة بالمخزن.'));
                  }

                  return Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.surfaceElevated),
                        columns: const [
                          DataColumn(label: Text('كود الصنف (SKU)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('اسم المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('القسم', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('السعر (ج.م)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الرصيد المتاح', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('موقع التخزين بالمخزن', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('طباعة الباركود', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: products.map((prod) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  prod.sku,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              DataCell(
                                Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataCell(Text(prod.category)),
                              DataCell(Text('${prod.price.toStringAsFixed(2)} ج.م')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: prod.isLowStock
                                        ? AppColors.statusCanceled.withOpacity(0.1)
                                        : AppColors.statusDelivered.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${prod.stockQuantity} قطعة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: prod.isLowStock ? AppColors.statusCanceled : AppColors.statusDelivered,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(prod.warehouseLocation)),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.qr_code, color: AppColors.primary),
                                  tooltip: 'معاينة وطباعة باركود الصنف',
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

// نافذة إضافة منتج جديد
class _AddProductDialog extends ConsumerStatefulWidget {
  const _AddProductDialog();

  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController(text: 'إلكترونيات');
  final _locationController = TextEditingController(text: 'مخزن القاهرة المركزي - قطاع A12');
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة منتج جديد لمخزن الشحن'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'كود الصنف الفريد SKU (مثال: ELEC-EARB-001)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج بالكامل'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر البيع (ج.م)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر التكلفة (ج.م)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الرصيد الأولي بالمخزن'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'القسم / التصنيف'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'مكان التخزين بالمخزن'),
              ),
            ],
          ),
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
                  setState(() => _isSubmitting = true);
                  try {
                    await ref.read(productRepositoryProvider).createProduct({
                      'sku': _skuController.text.trim(),
                      'name': _nameController.text.trim(),
                      'price': double.parse(_priceController.text.trim()),
                      'cost_price': double.tryParse(_costController.text.trim()) ?? 0,
                      'stock_quantity': int.parse(_stockController.text.trim()),
                      'category': _categoryController.text.trim(),
                      'warehouse_location': _locationController.text.trim(),
                    });
                    ref.refresh(productsListProvider);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة المنتج وتوليد باركود QR بنجاح!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  } finally {
                    setState(() => _isSubmitting = false);
                  }
                },
          child: const Text('حفظ المنتج'),
        ),
      ],
    );
  }
}

// نافذة طباعة باركود الصنف
class _ProductQrLabelDialog extends StatelessWidget {
  final ProductModel product;

  const _ProductQrLabelDialog({required this.product});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('باركود الصنف: ${product.sku}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: product.barcodeQrData ?? 'SKU:${product.sku}',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text(
              'كود: ${product.sku} | السعر: ${product.price.toStringAsFixed(2)} ج.م',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم إرسال باركود ${product.sku} لطابعة الملصقات الحرارية.')),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.print, size: 16),
          label: const Text('طباعة الملصق'),
        ),
      ],
    );
  }
}
