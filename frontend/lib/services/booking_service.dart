// lib/services/booking_service.dart
import 'package:car_platform/services/api_service.dart';

class BookingService {
  static Future<Map<String, dynamic>?> createBooking(Map<String, dynamic> bookingData) async {
    return await ApiService.post("/bookings/", bookingData);
  }

  static Future<List<dynamic>> listBookings() async {
    final data = await ApiService.get("/bookings/");
    return data ?? [];
  }

  static Future<bool> deleteBooking(String id) async {  // 🔄 UUID is a string
    return await ApiService.delete("/bookings/$id");
  }

}
