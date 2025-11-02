import 'package:driveon_car_platform/services/api_service.dart';

class LoyaltyService {
  static const String _baseUrl = '/loyalty';

  /// Get provider loyalty configuration
  static Future<Map<String, dynamic>?> getProviderConfig(String providerId) async {
    final res = await ApiService.get('$_baseUrl/providers/$providerId/config');
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Get provider loyalty usage statistics
  static Future<Map<String, dynamic>?> getProviderUsage(String providerId) async {
    final res = await ApiService.get('$_baseUrl/providers/$providerId/usage');
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Enable/opt-in provider to loyalty program
  static Future<Map<String, dynamic>?> enableProvider({
    required String providerId,
    required String participationTier, // basic, premium, elite
    String billingPlan = 'monthly_subscription',
    int? monthlySubscriptionFee,
    double? billingRatePerPoint,
    int? monthlyPointBudget,
  }) async {
    final body = <String, dynamic>{
      'participation_tier': participationTier,
      'billing_plan': billingPlan,
    };

    if (monthlySubscriptionFee != null) {
      body['monthly_subscription_fee'] = monthlySubscriptionFee;
    }
    if (billingRatePerPoint != null) {
      body['billing_rate_per_point'] = billingRatePerPoint;
    }
    if (monthlyPointBudget != null) {
      body['monthly_point_budget'] = monthlyPointBudget;
    }

    final res = await ApiService.post('$_baseUrl/providers/$providerId/enable', body);
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Disable/opt-out provider from loyalty program
  static Future<Map<String, dynamic>?> disableProvider(String providerId) async {
    final res = await ApiService.post('$_baseUrl/providers/$providerId/disable', {});
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Update provider loyalty configuration
  static Future<Map<String, dynamic>?> updateProviderConfig({
    required String providerId,
    String? participationTier,
    String? billingPlan,
    int? monthlySubscriptionFee,
    double? billingRatePerPoint,
    int? monthlyPointBudget,
  }) async {
    final body = <String, dynamic>{};

    if (participationTier != null) {
      body['participation_tier'] = participationTier;
    }
    if (billingPlan != null) {
      body['billing_plan'] = billingPlan;
    }
    if (monthlySubscriptionFee != null) {
      body['monthly_subscription_fee'] = monthlySubscriptionFee;
    }
    if (billingRatePerPoint != null) {
      body['billing_rate_per_point'] = billingRatePerPoint;
    }
    if (monthlyPointBudget != null) {
      body['monthly_point_budget'] = monthlyPointBudget;
    }

    final res = await ApiService.put('$_baseUrl/providers/$providerId/config', body);
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Get user loyalty account
  static Future<Map<String, dynamic>?> getUserAccount(int userId) async {
    final res = await ApiService.get('$_baseUrl/account/$userId');
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Get user loyalty account summary
  static Future<Map<String, dynamic>?> getUserAccountSummary(int userId, {int limit = 10}) async {
    final res = await ApiService.get('$_baseUrl/account/$userId/summary?limit=$limit');
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Get user tier info
  static Future<Map<String, dynamic>?> getUserTierInfo(int userId) async {
    final res = await ApiService.get('$_baseUrl/account/$userId/tier');
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }

  /// Get user loyalty transactions
  static Future<List<dynamic>> getUserTransactions(int userId, {int limit = 50, int offset = 0}) async {
    final queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    final queryString = queryParams.entries
        .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
        .join("&");
    
    final res = await ApiService.get('$_baseUrl/transactions/user/$userId?$queryString');
    if (res is List) {
      return res;
    }
    return [];
  }

  /// Get all participating providers (admin)
  static Future<List<dynamic>> getParticipatingProviders() async {
    final res = await ApiService.get('$_baseUrl/providers/participating');
    if (res is List) {
      return res;
    }
    return [];
  }
}

