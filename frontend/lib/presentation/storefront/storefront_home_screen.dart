import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../providers/products_provider.dart';
import 'cart_and_checkout_screen.dart';
import 'order_tracking_screen.dart';

final cartItemsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

class StorefrontHomeScreen extends ConsumerStatefulWidget {
  const StorefrontHomeScreen({super.key});

  @override
  ConsumerState<StorefrontHomeScreen> createState() => _StorefrontHomeScreenState();
}

class _StorefrontHomeScreenState extends ConsumerState<StorefrontHomeScreen> {
  String _selectedCategory = 'All';

  void _addToCart(ProductModel product) {
    final cart = ref.read(cartItemsProvider);
    final idx = cart.indexWhere((i) => (i['product'] as ProductModel).id == product.id);
    if (idx >= 0) {
      cart[idx]['quantity'] = (cart[idx]['quantity'] as int) + 1;
      ref.read(cartItemsProvider.notifier).state = [...cart];
    } else {
      ref.read(cartItemsProvider.notifier).state = [
        ...cart,
        {'product': product, 'quantity': 1}
      ];
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛒 تم إضافة ${product.name} إلى سلة التسوق!'),
        backgroundColor: AppColors.statusDelivered,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'عرض السلة',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartAndCheckoutScreen()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final cart = ref.watch(cartItemsProvider);
    final cartCount = cart.fold<int>(0, (sum, i) => sum + (i['quantity'] as int));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: AppColors.accent),
            SizedBox(width: 10),
            Text('متجر أنتيجرافيتي إكسبريس للتسوق والشحن السريع', style: TextStyle(fontWeight: FontWeight.black, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'تتبع شحنة',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'عربة التسوق',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartAndCheckoutScreen()),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.black),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. بانر تسويقي جذاب (Hero Marketing Banner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.sidebarBg, AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                    ),
                    child: const Text(
                      '⚡ أقوى عروض الشحن السريع في مصر 🇪🇬 - توصيل ٢٤ ساعة',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.black, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'تسوق أحدث المنتجات مع خدمة الدفع عند الاستلام وباي موب',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.black, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر منتجاتك المفضلة وسيقوم مندوبنا بتوصيلها لباب بيتك مع إمكانية المعاينة قبل الدفع كاش أو إلكترونياً.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CartAndCheckoutScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('إتمام الشراء والدفع', style: TextStyle(fontWeight: FontWeight.black)),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.location_searching, size: 18),
                        label: const Text('تتبع مسار شحنتك'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. شريط المزايا التسويقية
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FeatureItem(icon: Icons.flash_on, title: 'شحن سريع ٢٤ ساعة', subtitle: 'كافة المحافظات'),
                  _FeatureItem(icon: Icons.payments_outlined, title: 'دفع عند الاستلام', subtitle: 'كاش مع المندوب'),
                  _FeatureItem(icon: Icons.security, title: 'دفع إلكتروني آمن', subtitle: 'Paymob / إنستاباي'),
                  _FeatureItem(icon: Icons.published_with_changes, title: 'استرجاع سهل', subtitle: 'خلال ١٤ يوماً'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. كتالوج المنتجات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('كتالوج المنتجات المتاحة بالمخزن:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 18)),
                  const SizedBox(height: 14),

                  // فلاتر الأقسام
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', 'جميع الأقسام'),
                        _buildCategoryChip('إلكترونيات', 'إلكترونيات'),
                        _buildCategoryChip('أجهزة ذكية', 'أجهزة ذكية'),
                        _buildCategoryChip('ملابس وأزياء', 'ملابس وأزياء'),
                        _buildCategoryChip('مستلزمات منزلية', 'مستلزمات منزلية'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // شبكة المنتجات
                  productsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('خطأ في تحميل المنتجات: $err')),
                    data: (products) {
                      final filtered = _selectedCategory == 'All'
                          ? products
                          : products.where((p) => p.category == _selectedCategory).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('لا توجد منتجات متوفرة حالياً في هذا القسم.'));
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final prod = filtered[i];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.devices, size: 48, color: AppColors.primaryLight),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    prod.sku,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    prod.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.black, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${prod.price.toStringAsFixed(2)} ج.م',
                                        style: const TextStyle(fontWeight: FontWeight.black, color: AppColors.primary, fontSize: 14),
                                      ),
                                      ElevatedButton(
                                        onPressed: prod.inStock ? () => _addToCart(prod) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text(
                                          prod.inStock ? 'أضف للسلة' : 'نفد الرصيد',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _selectedCategory = key),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
