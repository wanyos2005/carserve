import 'package:car_platform/services/api_service.dart';

class VehicleService {
  // --- LIST VEHICLES ---
  static Future<List<dynamic>> listVehicles({
    String? plate,
    int skip = 0,
    int limit = 50,
  }) async {
    final query = {
      if (plate != null) 'plate': plate,
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    final res = await ApiService.get("/vehicles/", query: query);
    return res ?? [];
  }

  // --- CREATE VEHICLE (USER OWNED) ---
  static Future<Map<String, dynamic>?> addVehicle(Map<String, dynamic> vehicle) async {
    return await ApiService.post("/vehicles/", vehicle);
  }

  // --- GET SINGLE VEHICLE ---
  static Future<Map<String, dynamic>?> getByVehicleId(String id) async {
    final res = await ApiService.get("/vehicles/$id");
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  // --- UPDATE VEHICLE ---
  static Future<Map<String, dynamic>?> updateVehicle(String id, Map<String, dynamic> data) async {
    final res = await ApiService.put("/vehicles/$id", data);
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  // --- DELETE VEHICLE ---
  static Future<bool> deleteVehicle(String id) async {
    return await ApiService.delete("/vehicles/$id");
  }

  // --- CREATE GUEST VEHICLE ---
  static Future<Map<String, dynamic>?> createGuestVehicle(Map<String, dynamic> vehicle) async {
    final res = await ApiService.post("/vehicles/guest", vehicle);
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }
}
