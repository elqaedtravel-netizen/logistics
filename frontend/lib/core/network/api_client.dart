import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.keyAuthToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // If response is wrapped in standard API envelope: { success, statusCode, data, timestamp }
          if (response.data is Map<String, dynamic> &&
              response.data.containsKey('data') &&
              response.data.containsKey('success')) {
            response.data = response.data['data'];
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          String errorMessage = 'An unexpected network error occurred';
          if (e.response?.data != null && e.response?.data is Map) {
            errorMessage = e.response?.data['message'] ??
                e.response?.data['error'] ??
                e.message;
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: errorMessage,
            ),
          );
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final res = await _dio.get(path, queryParameters: queryParameters);
    return res.data;
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    final res = await _dio.post(path, data: data, queryParameters: queryParameters);
    return res.data;
  }

  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    final res = await _dio.put(path, data: data, queryParameters: queryParameters);
    return res.data;
  }

  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    final res = await _dio.patch(path, data: data, queryParameters: queryParameters);
    return res.data;
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    final res = await _dio.delete(path, queryParameters: queryParameters);
    return res.data;
  }
}
