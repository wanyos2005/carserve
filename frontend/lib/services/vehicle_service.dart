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

  // --- GET SINGLE VEHICLE (PUBLIC) ---
  static Future<Map<String, dynamic>?> getByVehicleIdPublic(String id) async {
    print('DEBUG VehicleService: Fetching public vehicle with ID: $id');
    final res = await ApiService.get("/vehicles/public/$id");
    print('DEBUG VehicleService: Vehicle response: $res');
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

  /// Search vehicles by partial or full plate (for autofill).
  static Future<List<dynamic>> searchVehicles(String plate) async {
    if (plate.isEmpty) return [];

    try {
      final res = await ApiService.get("/vehicles/search", query: {"plate": plate});
      if (res is List) {
        return res;
      } else {
        print("Unexpected vehicle search response: $res");
        return [];
      }
    } catch (e) {
      print("Error searching vehicles: $e");
      return [];
    }
  }

}
