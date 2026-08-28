import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'cart_and_checkout_screen.dart';
import 'order_tracking_screen.dart';
import 'auth/login_screen.dart';

class StorefrontHomeScreen extends ConsumerWidget {
  const StorefrontHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productsFilterProvider);
    final productsAsync = ref.watch(productsListProvider);
    final cart = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);

    final categories = ['الكل', 'إلكترونيات', 'ملابس وأزياء', 'أجهزة منزلية'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('متجر أنتيجرافيتي إكسبريس', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // زر تتبع الأوردر
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
              );
            },
            icon: const Icon(Icons.location_searching, color: AppColors.primary),
            label: const Text('تتبع أوردرك', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),

          // سلة الشراء مع عداد الأصناف
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 26),
                tooltip: 'سلة المشتريات',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartAndCheckoutScreen()),
                  );
                },
              ),
              if (cart.totalItemsCount > 0)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cart.totalItemsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // تسجيل الدخول / الخروج
          if (authState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () => ref.read(authProvider.notifier).logout(),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('تسجيل الدخول'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // بانر المتجر
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'شحن وتوصيل فوري خلال نفس اليوم (القاهرة والجيزة) ⚡',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'أفضل الأجهزة الإلكترونية ومستلزمات الحياة العصرية',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'ادفع عند الاستلام كاش مع المندوب، أو عبر فيزا وميزة ومحافظ فودافون كاش وإنستاباي.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شريط الأقسام
          SliverToBoxAdapter(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSelected = filter.category == cat || (cat == 'الكل' && filter.category == 'All');
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(productsFilterProvider.notifier).state = filter.copyWith(category: cat == 'الكل' ? 'All' : cat);
                      }
                    },
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // شبكة المنتجات
          productsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Center(child: Text('خطأ في تحميل المنتجات: $err')),
            ),
            data: (products) {
              if (products.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('لا توجد منتجات متاحة في هذا القسم حالياً.'))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final product = products[idx];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // صورة المنتج
                            Expanded(
                              flex: 5,
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: AppColors.surfaceElevated,
                                    child: product.imageUrl != null
                                        ? Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Center(
                                              child: Icon(Icons.image_not_supported, color: AppColors.textMuted),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.inventory_2, size: 48, color: AppColors.primaryLight),
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: product.inStock ? Colors.green[700] : Colors.red[700],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product.inStock ? 'متوفر بالمخزن (${product.stockQuantity})' : 'نفد المخزون',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // بيانات المنتج
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.category,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${product.price.toStringAsFixed(2)} ج.م',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        IconButton.filled(
                                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                                          style: IconButton.styleFrom(
                                            backgroundColor: product.inStock ? AppColors.primary : Colors.grey,
                                            padding: const EdgeInsets.all(6),
                                          ),
                                          onPressed: product.inStock
                                              ? () {
                                                  ref.read(cartProvider.notifier).addProduct(product);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('تمت إضافة ${product.name} لسلة الشراء!'),
                                                      duration: const Duration(seconds: 1),
                                                    ),
                                                  );
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
