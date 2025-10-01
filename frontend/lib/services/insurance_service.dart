import 'package:car_platform/services/api_service.dart';

class InsuranceService {
  static Future<dynamic> createPolicy(Map<String, dynamic> payload) async {
    try {
      return await ApiService.post("/insurance/create-insurance-policy", payload);
    } catch (e) {
      return null; // or rethrow if you want to handle errors higher up
    }
  }


  static Future<List<dynamic>> getPoliciesByOwner(String ownerId) async {
    try {
      final res = await ApiService.get("/insurance/get-insurance-policy-by-owner/$ownerId");
      if (res is List) {
        return res;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
