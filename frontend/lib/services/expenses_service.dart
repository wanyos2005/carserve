import 'package:car_platform/services/api_service.dart';

class ExpensesService {
  static Future<List<dynamic>> listExpenses({int? ownerId, String? vehicleId}) async {
    final query = <String, String>{
      if (ownerId != null) 'owner_id': ownerId.toString(),
      if (vehicleId != null) 'vehicle_id': vehicleId,
    };
    final res = await ApiService.get('/expense/get-expenses', query: query);
    return (res is List) ? res : <dynamic>[];
  }

  static Future<dynamic> createExpense({
    required int ownerId,
    required String vehicleId,
    String? providerId,
    required String expenseType,
    String? location,
    required int cost,
  }) async {
    final body = {
      'owner_id': ownerId,
      'vehicle_id': vehicleId,
      'provider_id': providerId,
      'expense_type': expenseType,
      'location': location,
      'cost': cost,
    };
    return ApiService.post('/expense/create-expense', body);
  }

  static Future<Map<String, dynamic>> getStats({required int ownerId, String? vehicleId}) async {
    final query = <String, String>{
      'owner_id': ownerId.toString(),
      if (vehicleId != null) 'vehicle_id': vehicleId,
    };
    final res = await ApiService.get('/expense/stats', query: query);
    return (res is Map<String, dynamic>) ? res : <String, dynamic>{'total': 0, 'count': 0};
  }
}


