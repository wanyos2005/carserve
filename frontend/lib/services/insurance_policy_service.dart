import 'package:car_platform/services/api_service.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class InsurancePolicyService {
  final String baseUrl = "http://localhost:8001"; // another microservice

  Future<List<dynamic>> fetchVehicles() async {
    final response = await http.get(Uri.parse("$baseUrl/users"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // assuming it's a JSON list
    } else {
      throw Exception("Failed to fetch vehicles: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> fetchVehicleById(String id) async {
    final response = await http.get(Uri.parse("$baseUrl/users/$id"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Vehicle not found");
    }
  }

   static Future<List<dynamic>> listInsurancePolicies() async {
    final res = await ApiService.get("/vehicles/");
    return res ?? [];
  }

  static Future<Map<String, dynamic>?> addInsurancePolicy(Map<String, dynamic> vehicle) async {
    return await ApiService.post("/vehicles/", vehicle);
  }


  static Future<bool> deleteInsurancePolicy(String id) async {
    return await ApiService.delete("/vehicles/$id");
  }
}
