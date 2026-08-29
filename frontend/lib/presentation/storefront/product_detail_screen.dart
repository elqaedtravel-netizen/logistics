import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import 'cart_and_checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  bool _isPlayingVideo = false;

  void _buyNowDirectly() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartAndCheckoutScreen(),
      ),
    );
  }

  void _addToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛒 تم إضافة "${widget.product.name}" إلى عربة التسوق بنجاح!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ رابط الصنف للمشاركة!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. معرض الصور وفيديو الشرح (Photo Gallery & Video Preview)
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.headphones, size: 90, color: Colors.white),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isPlayingVideo = !_isPlayingVideo);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('▶ جاري تشغيل فيديو المعاينة والشرح بدقة 4K!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 20),
                        label: const Text('معاينة فيديو المنتج بدقة 4K', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                      child: const Text('ضمان عامين رسمي 🛡️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.black, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // صور مصغرة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isSelected = _selectedImageIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        index == 0 ? Icons.headphones : index == 1 ? Icons.inventory_2 : Icons.cable,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // 2. بطاقة السعر والتوافر
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.black, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.statusDelivered.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Text('متوفر بالمخزن A12 🚀', style: TextStyle(color: AppColors.statusDelivered, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('كود الصنف: ${product.sku}', style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace', fontSize: 12)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('سعر الصنف:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          '${product.price.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.black, color: AppColors.primary, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. المواصفات الفنية والشرح
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المواصفات الفنية والشرح:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 15)),
                    const SizedBox(height: 10),
                    Text(
                      product.description ?? 'منتج عالي الجودة معتمد ومضمون للشحن الفوري لباب منزلك مع إمكانية المعاينة قبل الدفع.',
                      style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    const Text('✓ شحن سريع ٢٤ ساعة لكافة محافظات مصر.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('✓ استرجاع واستبدال مجاني خلال ١٤ يوماً.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('✓ دفع عند الاستلام (كاش) أو فيزا وإنستاباي.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. أزرار الشراء الفوري والسلة المزدوجة
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _buyNowDirectly,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    label: const Text('⚡ شراء الآن مباشرة', style: TextStyle(fontWeight: FontWeight.black, fontSize: 14, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _addToCart,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                    label: const Text('🛒 للسلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
