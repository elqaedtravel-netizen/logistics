import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import 'order_tracking_screen.dart';

class CartAndCheckoutScreen extends ConsumerStatefulWidget {
  const CartAndCheckoutScreen({super.key});

  @override
  ConsumerState<CartAndCheckoutScreen> createState() => _CartAndCheckoutScreenState();
}

class _CartAndCheckoutScreenState extends ConsumerState<CartAndCheckoutScreen> {
  final _nameController = TextEditingController(text: 'سارة إبراهيم');
  final _phoneController = TextEditingController(text: '01098765432');
  final _addressController = TextEditingController(text: '١٥ ميدان التحرير، وسط البلد');
  final _cityController = TextEditingController(text: 'القاهرة');
  final _walletPhoneController = TextEditingController(text: '01012345678');

  String _selectedPaymentMethod = AppConstants.paymentCod;
  bool _isPlacingOrder = false;

  void _handleCheckout() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سلة المشتريات فارغة.')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى استكمال جميع بيانات عنوان التوصيل.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final orderItems = cart.items.values.map((i) {
        return {
          'product_id': i.product.id,
          'quantity': i.quantity,
        };
      }).toList();

      final orderPayload = {
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'shipping_address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'payment_method': _selectedPaymentMethod,
        'items': orderItems,
      };

      final createdOrder = await ref.read(orderRepositoryProvider).createOrder(orderPayload);
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.statusDelivered, size: 28),
              SizedBox(width: 10),
              Text('تم تأكيد الأوردر بنجاح!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رقم تتبع الشحنة: ${createdOrder.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text('إجمالي المبلغ: ${createdOrder.totalAmount.toStringAsFixed(2)} ج.م'),
              Text('طريقة الدفع: ${AppConstants.paymentMethodArabic[createdOrder.paymentMethod] ?? createdOrder.paymentMethod}'),
              const SizedBox(height: 12),
              const Text(
                'يقوم مخزن القاهرة المركزي بتجهيز الشحنة لتسليمها لمندوب خط السير.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                );
              },
              child: const Text('تتبع الأوردر لحظياً'),
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
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات وإتمام الطلب'),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_shopping_cart_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('سلة المشتريات فارغة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('تصفح المنتجات'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // قائمة المنتجات ونموذج العنوان
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // قائمة الأصناف
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('أصناف الأوردر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const Divider(height: 20),
                                    ...cart.items.values.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  Text('كود: ${item.product.sku}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                  Text('${item.product.price.toStringAsFixed(2)} ج.م', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                                  onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
                                                ),
                                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                                  onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
                                                ),
                                              ],
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

                            // بيانات التوصيل
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('عنوان التوصيل داخل مصر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const Divider(height: 20),
                                    TextField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(labelText: 'اسم المستلم بالكامل', isDense: true),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(labelText: 'رقم هاتف المستلم', isDense: true),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _addressController,
                                      decoration: const InputDecoration(labelText: 'الشارع ورقم العمارة والشقة', isDense: true),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _cityController,
                                      decoration: const InputDecoration(labelText: 'المحافظة / المدينة (مثال: القاهرة، الجيزة)', isDense: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // طرق الدفع وملخص الحساب
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            // طرق الدفع
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('طريقة الدفع (مصر)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    const Divider(height: 20),
                                    _buildPaymentOption(
                                      AppConstants.paymentCod,
                                      'دفع عند الاستلام (كاش)',
                                      'ادفع نقداً للمندوب عند استلام الشحنة',
                                      Icons.money,
                                      AppColors.primary,
                                    ),
                                    _buildPaymentOption(
                                      AppConstants.paymentPaymobCard,
                                      'باي موب: فيزا وماستركارد',
                                      'دفع إلكتروني آمن بالبطاقة البنكية',
                                      Icons.credit_card,
                                      AppColors.primaryLight,
                                    ),
                                    _buildPaymentOption(
                                      AppConstants.paymentPaymobMeeza,
                                      'باي موب: بطاقات ميزة الوطنية',
                                      'بطاقات الخصم المباشر ميزة',
                                      Icons.payment,
                                      AppColors.meezaGreen,
                                    ),
                                    _buildPaymentOption(
                                      AppConstants.paymentPaymobWallet,
                                      'باي موب: المحافظ الإلكترونية',
                                      'فودافون كاش، أورنج، إنستاباي',
                                      Icons.phone_android,
                                      AppColors.vodafoneRed,
                                    ),
                                    if (_selectedPaymentMethod == AppConstants.paymentPaymobWallet) ...[
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _walletPhoneController,
                                        decoration: const InputDecoration(
                                          labelText: 'رقم المحفظة (مثال: 01012345678)',
                                          isDense: true,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ملخص الحساب
                            Card(
                              color: AppColors.surfaceElevated,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('ملخص الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('مجموع المنتجات:'),
                                        Text('${cart.subtotal.toStringAsFixed(2)} ج.م'),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('مصاريف الشحن (القاهرة والجيزة):'),
                                        Text('${cart.shippingFee.toStringAsFixed(2)} ج.م'),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('الإجمالي المطلوب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(
                                          '${cart.totalAmount.toStringAsFixed(2)} ج.م',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: _isPlacingOrder ? null : _handleCheckout,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: _isPlacingOrder
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Text('تأكيد الطلب (${cart.totalAmount.toStringAsFixed(2)} ج.م)'),
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
            ),
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle, IconData icon, Color color) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentMethod,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(right: 28),
        child: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ),
      onChanged: (val) {
        if (val != null) setState(() => _selectedPaymentMethod = val);
      },
    );
  }
}
