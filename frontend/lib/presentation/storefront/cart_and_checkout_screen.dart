import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_model.dart';
import '../providers/orders_provider.dart';
import 'storefront_home_screen.dart';
import 'order_tracking_screen.dart';

class CartAndCheckoutScreen extends ConsumerStatefulWidget {
  const CartAndCheckoutScreen({super.key});

  @override
  ConsumerState<CartAndCheckoutScreen> createState() => _CartAndCheckoutScreenState();
}

class _CartAndCheckoutScreenState extends ConsumerState<CartAndCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'سارة إبراهيم');
  final _phoneController = TextEditingController(text: '01098765432');
  final _addressController = TextEditingController(text: '١٥ ميدان التحرير، وسط البلد');
  final _couponController = TextEditingController();

  String _selectedGovernorate = 'القاهرة';
  String _selectedPaymentMethod = AppConstants.paymentCod;
  double _discount = 0.0;
  bool _isPlacingOrder = false;

  double _calculateSubtotal(List<Map<String, dynamic>> cart) {
    return cart.fold<double>(
      0.0,
      (sum, item) => sum + ((item['product'] as ProductModel).price * (item['quantity'] as int)),
    );
  }

  double _calculateShipping(String gov) {
    if (gov == 'القاهرة' || gov == 'الجيزة') return 50.0;
    if (gov == 'الإسكندرية') return 65.0;
    return 80.0;
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'EGYPT2026' || code == 'SAVE10') {
      setState(() => _discount = 100.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 تم تطبيق كود الخصم بقيمة ١٠٠ ج.م!'), backgroundColor: AppColors.statusDelivered),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كود الخصم غير صالح'), backgroundColor: AppColors.statusCanceled),
      );
    }
  }

  void _submitCheckout(List<Map<String, dynamic>> cart) async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سلة التسوق فارغة! أضف منتجات أولاً.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPlacingOrder = true);
    try {
      final payload = {
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'shipping_address': '${_addressController.text.trim()} - $_selectedGovernorate',
        'city': _selectedGovernorate,
        'payment_method': _selectedPaymentMethod,
        'items': cart.map((i) {
          final p = i['product'] as ProductModel;
          return {
            'product_id': p.id,
            'quantity': i['quantity'],
            'unit_price': p.price,
          };
        }).toList(),
      };

      final order = await ref.read(orderRepositoryProvider).createOrder(payload);
      ref.read(cartItemsProvider.notifier).state = []; // تفريغ السلة

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.statusDelivered, size: 28),
              SizedBox(width: 10),
              Text('تم تأكيد طلبك بنجاح!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم البوليصة: #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 16, color: AppColors.primary, fontFamily: 'monospace')),
              const SizedBox(height: 8),
              Text('المستلم: ${order.customerName} (${order.customerPhone})'),
              Text('العنوان: ${order.shippingAddress}'),
              Text('المبلغ الإجمالي: ${order.totalAmount.toStringAsFixed(2)} ج.م'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                child: const Text('⚡ تم إرسال الشحنة لمخزن القاهرة المركزي للتجهيز وإسناد المندوب فوراً.', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('العودة للمتجر'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                );
              },
              icon: const Icon(Icons.location_searching, size: 16),
              label: const Text('تتبع الشحنة لحظياً'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تأكيد الطلب: $e'), backgroundColor: AppColors.statusCanceled),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartItemsProvider);
    final subtotal = _calculateSubtotal(cart);
    final shipping = _calculateShipping(_selectedGovernorate);
    final total = (subtotal + shipping - _discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('عربة التسوق وإتمام الشراء (Checkout)', style: TextStyle(fontWeight: FontWeight.black)),
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_shopping_cart_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  const Text('سلة التسوق فارغة حالياً', style: TextStyle(fontWeight: FontWeight.black, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('تصفح المنتجات وأضف للسلة'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العمود الأيمن: بيانات الشحن والدفع
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. بيانات المستلم
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('١. بيانات المستلم وعنوان التوصيل:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                  const Divider(height: 20),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(labelText: 'اسم المستلم بالكامل', prefixIcon: Icon(Icons.person)),
                                    validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(labelText: 'رقم الهاتف للتواصل (١١ رقم)', prefixIcon: Icon(Icons.phone)),
                                    validator: (v) => v?.trim().length != 11 ? 'أدخل رقم هاتف صحيح' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _selectedGovernorate,
                                    decoration: const InputDecoration(labelText: 'المحافظة (حساب سعر الشحن)', prefixIcon: Icon(Icons.location_city)),
                                    items: AppConstants.egyptianGovernorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                    onChanged: (v) => setState(() => _selectedGovernorate = v!),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(labelText: 'العنوان بالتفصيل (الشارع، العمارة، الشقة، علامة مميزة)', prefixIcon: Icon(Icons.home)),
                                    validator: (v) => v?.trim().isEmpty == true ? 'حقل إلزامي' : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. بوابات ووسائل الدفع
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('٢. وسيلة الدفع المفضلة لديك:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                  const Divider(height: 20),
                                  ...AppConstants.paymentMethodArabic.entries.map((e) {
                                    return RadioListTile<String>(
                                      value: e.key,
                                      groupValue: _selectedPaymentMethod,
                                      activeColor: AppColors.accent,
                                      title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text(
                                        e.key == AppConstants.paymentCod
                                          ? 'ادفع نقداً عند استلام ومعاينة الشحنة من المندوب'
                                          : 'دفع إلكتروني فوري وآمن 100%',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                      onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // العمود الأيسر: ملخص السلة والحساب
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('أصناف السلة (${cart.length}):', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                  const Divider(height: 16),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: cart.length,
                                    separatorBuilder: (_, __) => const Divider(height: 12),
                                    itemBuilder: (ctx, i) {
                                      final item = cart[i];
                                      final prod = item['product'] as ProductModel;
                                      final qty = item['quantity'] as int;
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1),
                                                Text('${prod.price} ج.م × $qty', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              ],
                                            ),
                                          ),
                                          Text('${(prod.price * qty).toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // كود الخصم
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _couponController,
                                          decoration: const InputDecoration(hintText: 'كود الخصم (EGYPT2026)', isDense: true),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(onPressed: _applyCoupon, child: const Text('تطبيق')),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // الحسابات
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    const Text('قيمة المنتجات:'),
                                    Text('${subtotal.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text('مصاريف الشحن ($_selectedGovernorate):'),
                                    Text('${shipping.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ]),
                                  if (_discount > 0) ...[
                                    const SizedBox(height: 6),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      const Text('الخصم المطبق:', style: TextStyle(color: Colors.green)),
                                      Text('-${_discount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ]),
                                  ],
                                  const Divider(height: 20),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    const Text('الإجمالي النهائي:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                    Text('${total.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 18, color: AppColors.accent)),
                                  ]),
                                  const SizedBox(height: 20),

                                  ElevatedButton(
                                    onPressed: _isPlacingOrder ? null : () => _submitCheckout(cart),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                    child: _isPlacingOrder
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('تأكيد الطلب وإصدار البوليصة', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
