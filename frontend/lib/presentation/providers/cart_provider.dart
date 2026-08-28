import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartState {
  final Map<String, CartItem> items;

  CartState({this.items = const {}});

  int get totalItemsCount => items.values.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.values.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get shippingFee => items.isEmpty ? 0.0 : 50.0; // 50 EGP standard shipping in Cairo/Giza
  double get totalAmount => subtotal + shippingFee;

  CartState copyWith({Map<String, CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addProduct(ProductModel product, {int quantity = 1}) {
    final current = Map<String, CartItem>.from(state.items);
    if (current.containsKey(product.id)) {
      current[product.id]!.quantity += quantity;
    } else {
      current[product.id] = CartItem(product: product, quantity: quantity);
    }
    state = state.copyWith(items: current);
  }

  void updateQuantity(String productId, int quantity) {
    final current = Map<String, CartItem>.from(state.items);
    if (quantity <= 0) {
      current.remove(productId);
    } else if (current.containsKey(productId)) {
      current[productId]!.quantity = quantity;
    }
    state = state.copyWith(items: current);
  }

  void removeProduct(String productId) {
    final current = Map<String, CartItem>.from(state.items);
    current.remove(productId);
    state = state.copyWith(items: current);
  }

  void clearCart() {
    state = CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
