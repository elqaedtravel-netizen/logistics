import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/driver_ledger_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/driver_ledger_repository.dart';

final driverLedgerRepositoryProvider = Provider<DriverLedgerRepository>((ref) => DriverLedgerRepository());

final driverMyBalanceProvider = FutureProvider.autoDispose<DriverBalanceModel>((ref) async {
  final repo = ref.watch(driverLedgerRepositoryProvider);
  return repo.getMyBalance();
});

final driverMyStatementProvider = FutureProvider.autoDispose<List<DriverLedgerEntryModel>>((ref) async {
  final repo = ref.watch(driverLedgerRepositoryProvider);
  return repo.getMyStatement();
});

final allDriversSummaryProvider = FutureProvider.autoDispose<List<DriverBalanceModel>>((ref) async {
  final repo = ref.watch(driverLedgerRepositoryProvider);
  return repo.getAllDriversSummary();
});

final driversListProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.watch(driverLedgerRepositoryProvider);
  return repo.getDriversList();
});

final driverStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, driverId) async {
  final repo = ref.watch(driverLedgerRepositoryProvider);
  return repo.getDriverPerformanceStats(driverId);
});

final driverRepositoryProvider = Provider<DriverLedgerRepository>((ref) => ref.watch(driverLedgerRepositoryProvider));

final driverFinancialsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String?>((ref, driverId) async {
  return {
    'cashBalanceEgp': 14500.0,
    'commissionEarnedEgp': 1450.0,
    'settlementHistory': [
      {'amount': '12500.00', 'notes': 'توريد نقدية عبر إنستاباي', 'date': '2026-08-28'},
      {'amount': '8400.00', 'notes': 'توريد كاش بخزينة الفرع', 'date': '2026-08-27'},
    ]
  };
});

