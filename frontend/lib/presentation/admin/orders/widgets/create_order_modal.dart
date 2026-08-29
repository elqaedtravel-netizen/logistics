import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/driver_provider.dart';

class CreateOrderModal extends ConsumerStatefulWidget {
  const CreateOrderModal({super.key});

  @override
  ConsumerState<CreateOrderModal> createState() => _CreateOrderModalState();
}

class _CreateOrderModalState extends ConsumerState<CreateOrderModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGovernorate = 'القاهرة';
  String _selectedPaymentMethod = AppConstants.paymentCod;
  String? _assignedDriverId;

  final List<Map<String, dynamic>> _selectedItems = [];
  bool _isSubmitting = false;

  double get _subtotal {
    return _selectedItems.fold<double>(
      0.0,
      (sum, item) => sum + ((item['product'] as ProductModel).price * (item['quantity'] as int)),
    );
  }

  double get _shippingFee {
    if (_selectedGovernorate == 'القاهرة' || _selectedGovernorate == 'الجيزة') return 50.0;
    if (_selectedGovernorate == 'الإسكندرية') return 65.0;
    return 80.0; // باقي المحافظات
  }

  double get _totalAmount => _subtotal + _shippingFee;

  void _addItem(ProductModel product) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere((i) => (i['product'] as ProductModel).id == product.id);
      if (existingIndex >= 0) {
        _selectedItems[existingIndex]['quantity'] = (_selectedItems[existingIndex]['quantity'] as int) + 1;
      } else {
        _selectedItems.add({'product': product, 'quantity': 1});
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة صنف واحد على الأقل للشحنة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'shipping_address': '${_addressController.text.trim()} - $_selectedGovernorate',
        'city': _selectedGovernorate,
        'payment_method': _selectedPaymentMethod,
        'assigned_driver_id': _assignedDriverId,
        'notes': _notesController.text.trim(),
        'items': _selectedItems.map((i) {
          final prod = i['product'] as ProductModel;
          return {
            'product_id': prod.id,
            'quantity': i['quantity'],
            'unit_price': prod.price,
          };
        }).toList(),
      };

      final created = await ref.read(orderRepositoryProvider).createOrder(payload);
      ref.refresh(ordersListProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم إنشاء بوليصة الشحن بنجاح برقم: ${created.orderNumber}'),
          backgroundColor: AppColors.statusDelivered,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إنشاء الأوردر: $e'), backgroundColor: AppColors.statusCanceled),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final driversAsync = ref.watch(driversListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 860,
        height: 680,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
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
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إنشاء إذن شحن وبوليصة توزيع جديدة',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.black, color: AppColors.textPrimary),
                          ),
                          Text(
                            'إدخال بيانات المستلم، تفاصيل الأصناف، وحساب مصاريف الشحن وتوريد الكاش',
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

              // جسم النافذة (مقسم لعمودين)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العمود الأيمن: بيانات العميل والشحن
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('بيانات المستلم وعنوان التسليم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'اسم العميل / المستلم بالكامل', prefixIcon: Icon(Icons.person)),
                              validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'رقم هاتف المستلم (مثال: 01012345678)', prefixIcon: Icon(Icons.phone)),
                              validator: (v) => v?.trim().length != 11 ? 'أدخل رقم هاتف مصري صحيح من ١١ رقم' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGovernorate,
                                    decoration: const InputDecoration(labelText: 'المحافظة', prefixIcon: Icon(Icons.map)),
                                    items: AppConstants.egyptianGovernorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                    onChanged: (v) => setState(() => _selectedGovernorate = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(labelText: 'العنوان التفصيلي (الشارع، رقم العمارة، الشقة، علامة مميزة)', prefixIcon: Icon(Icons.location_on)),
                              validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                            ),
                            const SizedBox(height: 16),
                            const Text('إسناد مندوب التوصيل وطريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 10),
                            driversAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const Text('تعذر تحميل المناديب'),
                              data: (drivers) => DropdownButtonFormField<String>(
                                value: _assignedDriverId,
                                decoration: const InputDecoration(labelText: 'مندوب خط السير المكلف', prefixIcon: Icon(Icons.delivery_dining)),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('احتفاظ بالمخزن (توزيع لاحق)')),
                                  ...drivers.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.fullName} (${d.phone ?? "بدون هاتف"})'))),
                                ],
                                onChanged: (v) => setState(() => _assignedDriverId = v),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedPaymentMethod,
                              decoration: const InputDecoration(labelText: 'طريقة التحصيل والدفع', prefixIcon: Icon(Icons.payment)),
                              items: AppConstants.paymentMethodArabic.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // العمود الأيسر: اختيار الأصناف وملخص الحساب
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إضافة أصناف الشحنة من المخزن:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          productsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('تعذر تحميل المنتجات'),
                            data: (products) => DropdownButtonFormField<ProductModel>(
                              hint: const Text('اختر صنفاً لإضافته للبوليصة...'),
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.inventory_2)),
                              items: products.where((p) => p.inStock).map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.price} ج.م)'))).toList(),
                              onChanged: (p) {
                                if (p != null) _addItem(p);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: _selectedItems.isEmpty
                                  ? const Center(child: Text('لم يتم اختيار أي أصناف بعد', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _selectedItems.length,
                                      separatorBuilder: (_, __) => const Divider(height: 8),
                                      itemBuilder: (ctx, idx) {
                                        final item = _selectedItems[idx];
                                        final prod = item['product'] as ProductModel;
                                        final qty = item['quantity'] as int;
                                        return ListTile(
                                          dense: true,
                                          title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          subtitle: Text('كود: ${prod.sku} | ${prod.price} ج.م × $qty'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('${(prod.price * qty).toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _removeItem(idx)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // بطاقة ملخص الحساب
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.sidebarBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('قيمة الأصناف:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  Text('${_subtotal.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ]),
                                const SizedBox(height: 4),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('مصاريف الشحن ($_selectedGovernorate):', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  Text('${_shippingFee.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ]),
                                const Divider(color: Colors.white24, height: 16),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('المبلغ الإجمالي للتحصيل:', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.black, fontSize: 13)),
                                  Text('${_totalAmount.toStringAsFixed(2)} ج.م', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.black, fontSize: 16)),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 28),

              // أزرار الحفظ والإلغاء
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.print, size: 18),
                    label: const Text('تأكيد وإصدار بوليصة الشحن', style: TextStyle(fontWeight: FontWeight.bold)),
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
