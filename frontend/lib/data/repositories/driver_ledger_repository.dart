import '../../core/network/api_client.dart';
import '../models/driver_ledger_model.dart';
import '../models/user_model.dart';

class DriverLedgerRepository {
  final ApiClient _client = ApiClient();

  Future<DriverBalanceModel> getMyBalance() async {
    final response = await _client.get('/driver-ledger/my-balance');
    return DriverBalanceModel.fromJson(response);
  }

  Future<List<DriverLedgerEntryModel>> getMyStatement({int limit = 50}) async {
    final response = await _client.get('/driver-ledger/my-statement', queryParameters: {'limit': limit});
    return (response as List).map((e) => DriverLedgerEntryModel.fromJson(e)).toList();
  }

  Future<List<DriverBalanceModel>> getAllDriversSummary() async {
    final response = await _client.get('/driver-ledger/summary');
    return (response as List).map((s) => DriverBalanceModel.fromJson(s)).toList();
  }

  Future<DriverBalanceModel> getDriverBalance(String driverId) async {
    final response = await _client.get('/driver-ledger/$driverId/balance');
    return DriverBalanceModel.fromJson(response);
  }

  Future<List<DriverLedgerEntryModel>> getDriverStatement(String driverId, {int limit = 50}) async {
    final response = await _client.get('/driver-ledger/$driverId/statement', queryParameters: {'limit': limit});
    return (response as List).map((e) => DriverLedgerEntryModel.fromJson(e)).toList();
  }

  Future<dynamic> recordSettlementPayout(String driverId, double amount, String description, {String? refCode}) async {
    return await _client.post('/driver-ledger/settlement-payout', data: {
      'driver_id': driverId,
      'amount': amount,
      'description': description,
      if (refCode != null) 'reference_code': refCode,
    });
  }

  Future<List<UserModel>> getDriversList() async {
    final response = await _client.get('/users/drivers');
    return (response as List).map((u) => UserModel.fromJson(u)).toList();
  }

  Future<Map<String, dynamic>> getDriverPerformanceStats(String driverId) async {
    final response = await _client.get('/users/drivers/$driverId/stats');
    return response;
  }
}
