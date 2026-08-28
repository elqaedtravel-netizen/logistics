import 'product_model.dart';
import 'user_model.dart';

class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final String productSku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productSku: json['product_sku'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

class OrderTrackingTimelineItem {
  final String? previousStatus;
  final String status;
  final DateTime timestamp;
  final String? notes;
  final String? reasonCode;
  final String actor;

  OrderTrackingTimelineItem({
    this.previousStatus,
    required this.status,
    required this.timestamp,
    this.notes,
    this.reasonCode,
    required this.actor,
  });

  factory OrderTrackingTimelineItem.fromJson(Map<String, dynamic> json) {
    return OrderTrackingTimelineItem(
      previousStatus: json['previous_status'],
      status: json['status'] ?? json['new_status'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      notes: json['notes'],
      reasonCode: json['reason_code'],
      actor: json['actor'] ?? 'System',
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String? customerId;
  final UserModel? customer;
  final String customerName;
  final String customerPhone;
  final String shippingAddress;
  final String city;
  final double? geoLat;
  final double? geoLng;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final String? assignedDriverId;
  final UserModel? assignedDriver;
  final DateTime? scheduledDeliveryDate;
  final String? postponementReason;
  final String? postponementNotes;
  final String? waybillQrCode;
  final DateTime? deliveredAt;
  final List<OrderItemModel> items;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.customer,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    required this.city,
    this.geoLat,
    this.geoLng,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.shippingFee,
    required this.totalAmount,
    this.assignedDriverId,
    this.assignedDriver,
    this.scheduledDeliveryDate,
    this.postponementReason,
    this.postponementNotes,
    this.waybillQrCode,
    this.deliveredAt,
    this.items = const [],
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      customerId: json['customer_id'],
      customer: json['customer'] != null ? UserModel.fromJson(json['customer']) : null,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      shippingAddress: json['shipping_address'] ?? '',
      city: json['city'] ?? 'Cairo',
      geoLat: json['geo_lat'] != null ? double.tryParse(json['geo_lat'].toString()) : null,
      geoLng: json['geo_lng'] != null ? double.tryParse(json['geo_lng'].toString()) : null,
      status: json['status'] ?? 'Pending',
      paymentMethod: json['payment_method'] ?? 'CASH_ON_DELIVERY',
      paymentStatus: json['payment_status'] ?? 'UNPAID',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      shippingFee: double.tryParse(json['shipping_fee']?.toString() ?? '0') ?? 50.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      assignedDriverId: json['assigned_driver_id'],
      assignedDriver: json['assigned_driver'] != null
          ? UserModel.fromJson(json['assigned_driver'])
          : null,
      scheduledDeliveryDate: json['scheduled_delivery_date'] != null
          ? DateTime.parse(json['scheduled_delivery_date'])
          : null,
      postponementReason: json['postponement_reason'],
      postponementNotes: json['postponement_notes'],
      waybillQrCode: json['waybill_qr_code'],
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  bool get isCod => paymentMethod == 'CASH_ON_DELIVERY';
  bool get isPaid => paymentStatus == 'PAID';
}
