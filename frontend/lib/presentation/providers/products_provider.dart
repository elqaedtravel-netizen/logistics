import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) => ProductRepository());

class ProductsFilterState {
  final String category;
  final String search;
  final bool activeOnly;

  ProductsFilterState({
    this.category = 'All',
    this.search = '',
    this.activeOnly = true,
  });

  ProductsFilterState copyWith({String? category, String? search, bool? activeOnly}) {
    return ProductsFilterState(
      category: category ?? this.category,
      search: search ?? this.search,
      activeOnly: activeOnly ?? this.activeOnly,
    );
  }
}

final productsFilterProvider = StateProvider<ProductsFilterState>((ref) => ProductsFilterState());

final productsListProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final filter = ref.watch(productsFilterProvider);
  return repo.getProducts(
    category: filter.category,
    search: filter.search,
    activeOnly: filter.activeOnly,
  );
});

final lowStockAlertsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getLowStockAlerts();
});
