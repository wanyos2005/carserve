import 'package:car_platform/services/api_service.dart';

class InsuranceService {
  static const String _basePath = '/insurance';

  /// Get insurance health status
  static Future<Map<String, dynamic>?> getHealth() async {
    try {
      final response = await ApiService.get('$_basePath/health');
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error getting insurance health: $e');
    }
  }

  /// Get all insurance partners
  static Future<List<Map<String, dynamic>>> getPartners() async {
    try {
      final response = await ApiService.get('$_basePath/partners');
      if (response != null && response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Error getting insurance partners: $e');
    }
  }

  /// Get insurance quotes from multiple partners
  static Future<Map<String, dynamic>?> getQuotes({
    required String vehicleId,
    required int userId,
    required String coverageType,
    int? coverageAmount,
    int? deductibleAmount,
  }) async {
    try {
      final body = {
        'vehicle_id': vehicleId,
        'user_id': userId,
        'coverage_type': coverageType,
        if (coverageAmount != null) 'coverage_amount': coverageAmount,
        if (deductibleAmount != null) 'deductible_amount': deductibleAmount,
      };

      final response = await ApiService.post('$_basePath/quotes', body);
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error getting insurance quotes: $e');
    }
  }

  /// Get user's insurance policies
  static Future<List<Map<String, dynamic>>> getPolicies({int? userId}) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
      } else {
        // Use current user ID from context if not provided
        final currentUserId = ApiService.getCurrentUserId();
        if (currentUserId != null) {
          queryParams['user_id'] = currentUserId;
        }
      }

      final response = await ApiService.get('$_basePath/policies', query: queryParams);
      if (response != null && response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Error getting insurance policies: $e');
    }
  }

  /// Create a new insurance policy
  static Future<Map<String, dynamic>?> createPolicy({
    required int ownerId,
    required String vehicleId,
    required String providerId,
    required String insuranceType,
    DateTime? commencementDate,
    DateTime? expiryDate,
    int? premiumAmount,
    Map<String, dynamic>? coverageDetails,
    int? deductibleAmount,
    String? policyNumber,
  }) async {
    try {
      final body = {
        'owner_id': ownerId,
        'vehicle_id': vehicleId,
        'provider_id': providerId,
        'insurance_type': insuranceType,
        if (commencementDate != null) 'commencement_date': commencementDate.toIso8601String(),
        if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String(),
        if (premiumAmount != null) 'premium_amount': premiumAmount,
        if (coverageDetails != null) 'coverage_details': coverageDetails,
        if (deductibleAmount != null) 'deductible_amount': deductibleAmount,
        if (policyNumber != null) 'policy_number': policyNumber,
      };

      final response = await ApiService.post('$_basePath/policies', body);
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error creating insurance policy: $e');
    }
  }

  /// Get insurance claims for a user
  static Future<List<Map<String, dynamic>>> getClaims({int? userId}) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
      } else {
        // Use current user ID from context if not provided
        final currentUserId = ApiService.getCurrentUserId();
        if (currentUserId != null) {
          queryParams['user_id'] = currentUserId;
        }
      }

      final response = await ApiService.get('$_basePath/claims/', query: queryParams);
      if (response != null && response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Error getting insurance claims: $e');
    }
  }

  /// Submit a new insurance claim
  static Future<Map<String, dynamic>?> submitClaim({
    required String policyId,
    required String vehicleId,
    required int userId,
    required String claimType,
    required DateTime incidentDate,
    required String description,
    int? estimatedCost,
    List<String>? evidenceFiles,
    List<Map<String, dynamic>>? repairQuotes,
  }) async {
    try {
      final body = {
        'policy_id': policyId,
        'vehicle_id': vehicleId,
        'user_id': userId,
        'claim_type': claimType,
        'incident_date': incidentDate.toIso8601String(),
        'description': description,
        if (estimatedCost != null) 'estimated_cost': estimatedCost,
        if (evidenceFiles != null) 'evidence_files': evidenceFiles,
        if (repairQuotes != null) 'repair_quotes': repairQuotes,
      };

      final response = await ApiService.post('$_basePath/claims/', body);
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error submitting insurance claim: $e');
    }
  }

  /// Get risk scores for a vehicle
  static Future<Map<String, dynamic>?> getRiskScore({
    required String vehicleId,
    required int userId,
  }) async {
    try {
      final response = await ApiService.get('$_basePath/risk/$vehicleId', query: {'user_id': userId.toString()});
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error getting risk score: $e');
    }
  }

  /// Calculate/update risk score for a vehicle
  static Future<Map<String, dynamic>?> calculateRiskScore({
    required String vehicleId,
    required int userId,
  }) async {
    try {
      final response = await ApiService.post('$_basePath/risk/calculate/$vehicleId?user_id=$userId', {});
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error calculating risk score: $e');
    }
  }

  /// Renew an insurance policy
  static Future<Map<String, dynamic>?> renewPolicy({
    required String policyId,
    DateTime? newExpiryDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (newExpiryDate != null) {
        body['expiry_date'] = newExpiryDate.toIso8601String();
      }

      final response = await ApiService.post('$_basePath/policies/$policyId/renew', body);
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error renewing insurance policy: $e');
    }
  }

  /// Cancel an insurance policy
  static Future<Map<String, dynamic>?> cancelPolicy({
    required String policyId,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null) {
        body['reason'] = reason;
      }

      final response = await ApiService.post('$_basePath/policies/$policyId/cancel', body);
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error canceling insurance policy: $e');
    }
  }

  /// Create a new insurance partner
  static Future<Map<String, dynamic>?> createPartner(Map<String, dynamic> partnerData) async {
    try {
      final response = await ApiService.post('$_basePath/partners', partnerData);
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Error creating insurance partner: $e');
    }
  }
}