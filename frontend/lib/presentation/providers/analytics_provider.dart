import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) => AnalyticsRepository());

final dashboardAnalyticsProvider = FutureProvider.autoDispose<DashboardDataModel>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getDashboardMetrics();
});
