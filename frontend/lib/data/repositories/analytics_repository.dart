import '../../core/network/api_client.dart';
import '../models/analytics_model.dart';

class AnalyticsRepository {
  final ApiClient _client = ApiClient();

  Future<DashboardDataModel> getDashboardMetrics() async {
    final response = await _client.get('/analytics/dashboard');
    return DashboardDataModel.fromJson(response);
  }
}
