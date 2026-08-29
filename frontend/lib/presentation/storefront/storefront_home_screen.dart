import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../providers/products_provider.dart';
import 'cart_and_checkout_screen.dart';
import 'product_detail_screen.dart';
import 'customer_support_modal.dart';

class StorefrontHomeScreen extends ConsumerStatefulWidget {
  const StorefrontHomeScreen({super.key});

  @override
  ConsumerState<StorefrontHomeScreen> createState() => _StorefrontHomeScreenState();
}

class _StorefrontHomeScreenState extends ConsumerState<StorefrontHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'الكل';

  void _openDirectBuy(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartAndCheckoutScreen(),
      ),
    );
  }

  void _openProductDetails(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_shipping, color: AppColors.accent),
            SizedBox(width: 8),
            Text('متجر أنتيجرافيتي إكسبريس', style: TextStyle(fontWeight: FontWeight.black, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'تقديم شكوى أو مقترح',
            onPressed: () => showDialog(context: context, builder: (_) => const CustomerSupportModal()),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'عربة التسوق',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartAndCheckoutScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. البانر التسويقي الاستعراضي الفاخر
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF070F2B), Color(0xFF1B1A55), Color(0xFF535C91)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('⚡ أقوى عروض الشحن السريع في مصر 🇪🇬', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.black, fontSize: 11)),
                  ),
                  const SizedBox(height: 10),
                  const Text('توصيل خلال ٢٤ ساعة لباب بيتك!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.black)),
                  const SizedBox(height: 6),
                  const Text('دفع عند الاستلام كاش 💵، أو بالفيزا وإنستاباي 🟣 مع ضمان واسترجاع مجاني.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تتبع مسار شحنتك برقم البوليصة'),
                              content: const TextField(decoration: InputDecoration(labelText: 'رقم البوليصة (مثال: ORD-2026-10001)')),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('شحنتك في طريقها إليك مع المندوب أحمد محمود على خط سير المعادي.')),
                                    );
                                  },
                                  child: const Text('تتبع الآن'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                        icon: const Icon(Icons.search, size: 16, color: Colors.white),
                        label: const Text('تتبع شحنة برقم البوليصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => const CustomerSupportModal()),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white60), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        icon: const Icon(Icons.headset_mic, size: 16, color: Colors.white),
                        label: const Text('شكاوى ومقترحات', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. قائمة المنتجات
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الأصناف والمنتجات المتاحة بالمخزن:', style: TextStyle(fontWeight: FontWeight.black, fontSize: 16)),
                  const SizedBox(height: 12),
                  productsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('خطأ: $err')),
                    data: (products) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.64,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: products.length,
                        itemBuilder: (ctx, i) {
                          final p = products[i];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openProductDetails(p),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const Icon(Icons.inventory_2, size: 48, color: AppColors.primary),
                                            Positioned(
                                              bottom: 6,
                                              left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.play_circle, color: Colors.white, size: 10),
                                                    SizedBox(width: 2),
                                                    Text('فيديو', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('${p.price.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.black, fontSize: 13, color: AppColors.primary, fontFamily: 'monospace')),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _openDirectBuy(p),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.accent,
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('⚡ شراء', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _openProductDetails(p),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('تفاصيل', style: TextStyle(fontSize: 10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

            // 3. التذييل الدعائي الاحترافي المصغر لصناع التطبيق
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              color: const Color(0xFF0F172A),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, color: AppColors.accent, size: 16),
                      SizedBox(width: 6),
                      Text('منظومة أنتيجرافيتي للحلول اللوجستية والتجارة الإلكترونية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('تم التطوير والتشغيل بأحدث المعايير السحابية المؤسسية 🚀', style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
