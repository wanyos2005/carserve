import 'package:car_platform/services/api_service.dart';

class FinanceService {
  static Future<dynamic> createLoanApplication(Map<String, dynamic> data) async {
    return await ApiService.post("/finance/loans", data);
  }
}
