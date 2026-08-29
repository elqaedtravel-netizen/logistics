import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/products_provider.dart';

class AddProductModal extends ConsumerStatefulWidget {
  const AddProductModal({super.key});

  @override
  ConsumerState<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends ConsumerState<AddProductModal> {
  final _formKey = GlobalKey<FormState>();

  final _skuController = TextEditingController(text: 'ELEC-${Random().nextInt(9000) + 1000}');
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(text: '1250');
  final _costPriceController = TextEditingController(text: '950');
  final _stockController = TextEditingController(text: '45');
  final _minStockController = TextEditingController(text: '10');

  String _selectedCategory = 'إلكترونيات';
  String _selectedWarehouseLocation = AppConstants.warehouseZones.first;
  bool _isSubmitting = false;

  void _generateNewSku() {
    setState(() {
      final prefix = _selectedCategory == 'إلكترونيات'
          ? 'ELEC'
          : _selectedCategory == 'ملابس وأزياء'
              ? 'FASH'
              : 'HOME';
      _skuController.text = '$prefix-${Random().nextInt(9000) + 1000}';
    });
  }

  void _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final price = double.parse(_priceController.text.trim());
      final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
      final stock = int.parse(_stockController.text.trim());

      final payload = {
        'sku': _skuController.text.trim(),
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': price,
        'cost_price': costPrice,
        'stock_quantity': stock,
        'category': _selectedCategory,
        'warehouse_location': _selectedWarehouseLocation,
      };

      await ref.read(productRepositoryProvider).createProduct(payload);
      ref.refresh(productsListProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تمت إضافة الصنف ${_nameController.text.trim()} وتوليد باركود QR بنجاح!'),
          backgroundColor: AppColors.statusDelivered,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إضافة الصنف: $e'), backgroundColor: AppColors.statusCanceled),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 720,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الهيدر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إضافة صنف جديد وإصدار باركود QR للمخزن',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.black, color: AppColors.textPrimary),
                          ),
                          Text(
                            'تسجيل الأرصدة، مكان التخزين، أسعار البيع والتكلفة، وتنبيهات النواقص',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 28),

              // حقول الإدخال
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _skuController,
                              decoration: InputDecoration(
                                labelText: 'كود الصنف الفريد (SKU)',
                                prefixIcon: const Icon(Icons.qr_code_2),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.autorenew, color: AppColors.primary),
                                  tooltip: 'توليد كود تلقائي',
                                  onPressed: _generateNewSku,
                                ),
                              ),
                              validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(labelText: 'القسم / التصنيف'),
                              items: const [
                                DropdownMenuItem(value: 'إلكترونيات', child: Text('إلكترونيات')),
                                DropdownMenuItem(value: 'أجهزة ذكية', child: Text('أجهزة ذكية')),
                                DropdownMenuItem(value: 'ملابس وأزياء', child: Text('ملابس وأزياء')),
                                DropdownMenuItem(value: 'مستلزمات منزلية', child: Text('مستلزمات منزلية')),
                                DropdownMenuItem(value: 'إكسسوارات', child: Text('إكسسوارات')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedCategory = v);
                                  _generateNewSku();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج بالكامل (عربي / إنجليزي)',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'سعر البيع للعميل (ج.م)',
                                prefixIcon: Icon(Icons.sell),
                              ),
                              validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'سعر التكلفة بالجملة (ج.م)',
                                prefixIcon: Icon(Icons.price_change_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الرصيد الأولي بالمخزن',
                                prefixIcon: Icon(Icons.archive),
                              ),
                              validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedWarehouseLocation,
                        decoration: const InputDecoration(
                          labelText: 'موقع التخزين والرف بالمخزن',
                          prefixIcon: Icon(Icons.warehouse),
                        ),
                        items: AppConstants.warehouseZones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                        onChanged: (v) => setState(() => _selectedWarehouseLocation = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 28),

              // الأزرار
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitProduct,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 18),
                    label: const Text('حفظ الصنف وطباعة الباركود', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
