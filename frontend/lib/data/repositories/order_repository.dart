import '../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getAllOrders({
    String? status,
    String? driverId,
    String? search,
  }) async {
    final response = await _client.get('/orders', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (driverId != null && driverId.isNotEmpty) 'driver_id': driverId,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    final List<dynamic> ordersList = response['orders'] ?? [];
    final int count = response['count'] ?? 0;

    return {
      'orders': ordersList.map((o) => OrderModel.fromJson(o)).toList(),
      'count': count,
    };
  }

  Future<OrderModel> getOrderById(String id) async {
    final response = await _client.get('/orders/$id');
    return OrderModel.fromJson(response);
  }

  Future<OrderModel> getOrderByNumber(String orderNumber) async {
    final response = await _client.get('/orders/track/$orderNumber');
    return OrderModel.fromJson(response);
  }

  Future<Map<String, dynamic>> trackOrder(String orderNumber) async {
    final response = await _client.get('/orders/track/$orderNumber');
    return response;
  }

  Future<List<OrderModel>> getDriverAssignedOrders({String? status}) async {
    final response = await _client.get('/orders/driver/assigned', queryParameters: {
      if (status != null) 'status': status,
    });
    return (response as List).map((o) => OrderModel.fromJson(o)).toList();
  }

  Future<OrderModel> createOrder(Map<String, dynamic> orderData) async {
    final response = await _client.post('/orders', data: orderData);
    return OrderModel.fromJson(response);
  }

  Future<OrderModel> assignDriver(String orderId, String driverId, {DateTime? scheduledDate}) async {
    final response = await _client.put('/orders/$orderId/assign-driver', data: {
      'driver_id': driverId,
      if (scheduledDate != null) 'scheduled_delivery_date': scheduledDate.toIso8601String(),
    });
    return OrderModel.fromJson(response);
  }

  Future<OrderModel> updateStatus(String orderId, String status, {String? notes}) async {
    final response = await _client.patch('/orders/$orderId/status', data: {
      'status': status,
      if (notes != null) 'notes': notes,
    });
    return OrderModel.fromJson(response);
  }

  Future<OrderModel> deliverOrder(String orderId, {String? notes, String? signatureUrl}) async {
    final response = await _client.post('/orders/$orderId/deliver', data: {
      if (notes != null) 'delivery_notes': notes,
      if (signatureUrl != null) 'signature_url': signatureUrl,
    });
    return OrderModel.fromJson(response);
  }

  Future<OrderModel> postponeOrder(String orderId, String reason, {String? notes, DateTime? newDate}) async {
    final response = await _client.post('/orders/$orderId/postpone', data: {
      'reason': reason,
      if (notes != null) 'notes': notes,
      if (newDate != null) 'new_delivery_date': newDate.toIso8601String(),
    });
    return OrderModel.fromJson(response);
  }

  Future<Map<String, dynamic>> getWaybill(String orderId) async {
    final response = await _client.get('/orders/$orderId/waybill');
    return response;
  }

  Future<Map<String, dynamic>> bulkScanUpdate(List<String> barcodes, String targetStatus) async {
    final response = await _client.post('/orders/bulk-scan-update', data: {
      'barcodes': barcodes,
      'target_status': targetStatus,
    });
    return response;
  }
}
