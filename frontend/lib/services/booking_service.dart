//lib/services/booking_services.dart
import 'package:car_platform/services/api_service.dart';

class BookingService {
  static Future<Map<String, dynamic>?> createBooking(Map<String, dynamic> bookingData) async {
    return await ApiService.post("/bookings/", bookingData);
  }

  static Future<List<dynamic>> listBookingsForUser(int userId) async {
    final data = await ApiService.get("/bookings/user/$userId");
    return data ?? [];
  }

  static Future<List<dynamic>> listBookingsForProvider(String providerId) async {
    final data = await ApiService.get("/bookings/provider/$providerId");
    return data ?? [];
  }


  static Future<bool> updateBooking(String id, Map<String, dynamic> updates) async {
    print('DEBUG BookingService: Updating booking $id with: $updates');
    final result = await ApiService.put("/bookings/$id", updates);
    print('DEBUG BookingService: Update result: $result');
    final success = result != null;
    print('DEBUG BookingService: Update success: $success');
    return success; // Return true if we got a response, false if null
  }

  static Future<bool> deleteBooking(String id) async {  // 🔄 UUID is a string
    return await ApiService.delete("/bookings/$id");
  }

  static Future<Map<String, dynamic>?> getProvider(String providerId) async {
    return await ApiService.get("/service-providers/$providerId");
  }

  // ----------------- SERVICE LOGS -----------------

  static Future<Map<String, dynamic>?> createServiceLog(Map<String, dynamic> logData) async {
    return await ApiService.post("/service-logs/", logData);
  }

  static Future<List<dynamic>> listServiceLogsForUser(int userId) async {
    final data = await ApiService.get("/service-logs/user/$userId");
    return data ?? [];
  }

  static Future<List<dynamic>> listServiceLogsForProvider(String providerId) async {
    final data = await ApiService.get("/service-logs/provider/$providerId");
    return data ?? [];
  }

  static Future<Map<String, dynamic>?> getService(String serviceId) async {
    return await ApiService.get("/services/$serviceId");
  }
   static Future<List<dynamic>> createBulkServiceLogs(List<Map<String, dynamic>> logsData) async {
    final data = await ApiService.post("/service-logs/bulk", logsData);
    return data ?? [];
  }
}
