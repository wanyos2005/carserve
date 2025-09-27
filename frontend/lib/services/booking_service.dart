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

  static Future<Map<String, dynamic>?> getService(String serviceId) async {
    return await ApiService.get("/services/$serviceId");
  }
}
