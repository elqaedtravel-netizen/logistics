import '../../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ApiClient _client = ApiClient();

  Future<List<ProductModel>> getProducts({String? category, String? search, bool activeOnly = true}) async {
    final response = await _client.get('/products', queryParameters: {
      if (category != null && category != 'All') 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
      'activeOnly': activeOnly,
    });
    return (response as List).map((p) => ProductModel.fromJson(p)).toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await _client.get('/products/$id');
    return ProductModel.fromJson(response);
  }

  Future<ProductModel> getProductBySku(String sku) async {
    final response = await _client.get('/products/sku/$sku');
    return ProductModel.fromJson(response);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> productData) async {
    final response = await _client.post('/products', data: productData);
    return ProductModel.fromJson(response);
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> productData) async {
    final response = await _client.put('/products/$id', data: productData);
    return ProductModel.fromJson(response);
  }

  Future<Map<String, dynamic>> getPrintableQr(String id) async {
    final response = await _client.get('/products/$id/qr-label');
    return response;
  }

  Future<List<ProductModel>> getLowStockAlerts({int threshold = 5}) async {
    final response = await _client.get('/products/alerts/low-stock', queryParameters: {
      'threshold': threshold,
    });
    return (response as List).map((p) => ProductModel.fromJson(p)).toList();
  }
}
