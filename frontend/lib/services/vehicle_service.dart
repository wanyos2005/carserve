import 'package:car_platform/services/api_service.dart';

class VehicleService {
  static Future<List<dynamic>> listVehicles() async {
    final res = await ApiService.get("/vehicles/");
    return res ?? [];
  }

  static Future<Map<String, dynamic>?> addVehicle(Map<String, dynamic> vehicle) async {
    return await ApiService.post("/vehicles/", vehicle);
  }


  static Future<bool> deleteVehicle(String id) async {
    return await ApiService.delete("/vehicles/$id");
  }
}
