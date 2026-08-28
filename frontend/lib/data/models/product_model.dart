class ProductModel {
  final String id;
  final String sku;
  final String name;
  final String? description;
  final double price;
  final double costPrice;
  final int stockQuantity;
  final String warehouseLocation;
  final String? barcodeQrData;
  final String? imageUrl;
  final String category;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    required this.price,
    this.costPrice = 0.0,
    required this.stockQuantity,
    this.warehouseLocation = 'Warehouse-Cairo-Main',
    this.barcodeQrData,
    this.imageUrl,
    this.category = 'General',
    this.isActive = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      costPrice: double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0.0,
      stockQuantity: int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      warehouseLocation: json['warehouse_location'] ?? 'Warehouse-Cairo-Main',
      barcodeQrData: json['barcode_qr_data'],
      imageUrl: json['image_url'],
      category: json['category'] ?? 'General',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'description': description,
      'price': price,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'warehouse_location': warehouseLocation,
      'barcode_qr_data': barcodeQrData,
      'image_url': imageUrl,
      'category': category,
      'is_active': isActive,
    };
  }

  bool get inStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity <= 5;
}
