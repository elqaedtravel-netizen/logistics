import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());

class OrdersFilterState {
  final String? status;
  final String? driverId;
  final String? search;

  OrdersFilterState({this.status, this.driverId, this.search});

  OrdersFilterState copyWith({String? status, String? driverId, String? search}) {
    return OrdersFilterState(
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      search: search ?? this.search,
    );
  }
}

final ordersFilterProvider = StateProvider<OrdersFilterState>((ref) => OrdersFilterState());

final ordersListProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final filter = ref.watch(ordersFilterProvider);
  return repo.getAllOrders(
    status: filter.status,
    driverId: filter.driverId,
    search: filter.search,
  );
});

final driverAssignedOrdersProvider = FutureProvider.autoDispose.family<List<OrderModel>, String?>((ref, status) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getDriverAssignedOrders(status: status);
});

final singleOrderProvider = FutureProvider.autoDispose.family<OrderModel, String>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderById(id);
});

final orderTrackingProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, orderNumber) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.trackOrder(orderNumber);
});
