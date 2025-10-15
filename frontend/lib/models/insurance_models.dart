class InsurancePartner {
  final String id;
  final String name;
  final String code;
  final String? apiEndpoint;
  final String? webhookUrl;
  final bool supportsQuotes;
  final bool supportsClaims;
  final bool supportsDataFeeds;
  final bool isActive;
  final int? commissionRate;
  final Map<String, dynamic>? contactInfo;
  final List<String>? supportedCoverageTypes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Secondary Information (Decision Factors)
  final double? customerRating;
  final int? totalReviews;
  final String? claimsProcessingTime;
  final String? policyValidityPeriod;
  final List<String>? specialFeatures;
  
  // Tertiary Information (Nice to Have)
  final String? logoUrl;
  final String? websiteUrl;
  final int? establishedYear;
  final String? marketShare;
  final List<String>? awards;

  InsurancePartner({
    required this.id,
    required this.name,
    required this.code,
    this.apiEndpoint,
    this.webhookUrl,
    required this.supportsQuotes,
    required this.supportsClaims,
    required this.supportsDataFeeds,
    required this.isActive,
    this.commissionRate,
    this.contactInfo,
    this.supportedCoverageTypes,
    this.createdAt,
    this.updatedAt,
    // Secondary Information
    this.customerRating,
    this.totalReviews,
    this.claimsProcessingTime,
    this.policyValidityPeriod,
    this.specialFeatures,
    // Tertiary Information
    this.logoUrl,
    this.websiteUrl,
    this.establishedYear,
    this.marketShare,
    this.awards,
  });

  factory InsurancePartner.fromJson(Map<String, dynamic> json) {
    return InsurancePartner(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      apiEndpoint: json['api_endpoint'],
      webhookUrl: json['webhook_url'],
      supportsQuotes: json['supports_quotes'] ?? false,
      supportsClaims: json['supports_claims'] ?? false,
      supportsDataFeeds: json['supports_data_feeds'] ?? false,
      isActive: json['is_active'] ?? false,
      commissionRate: json['commission_rate'],
      contactInfo: json['contact_info'],
      supportedCoverageTypes: json['supported_coverage_types']?.cast<String>(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      // Secondary Information
      customerRating: json['customer_rating']?.toDouble(),
      totalReviews: json['total_reviews'],
      claimsProcessingTime: json['claims_processing_time'],
      policyValidityPeriod: json['policy_validity_period'],
      specialFeatures: json['special_features']?.cast<String>(),
      // Tertiary Information
      logoUrl: json['logo_url'],
      websiteUrl: json['website_url'],
      establishedYear: json['established_year'],
      marketShare: json['market_share'],
      awards: json['awards']?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'api_endpoint': apiEndpoint,
      'webhook_url': webhookUrl,
      'supports_quotes': supportsQuotes,
      'supports_claims': supportsClaims,
      'supports_data_feeds': supportsDataFeeds,
      'is_active': isActive,
      'commission_rate': commissionRate,
      'contact_info': contactInfo,
      'supported_coverage_types': supportedCoverageTypes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Secondary Information
      'customer_rating': customerRating,
      'total_reviews': totalReviews,
      'claims_processing_time': claimsProcessingTime,
      'policy_validity_period': policyValidityPeriod,
      'special_features': specialFeatures,
      // Tertiary Information
      'logo_url': logoUrl,
      'website_url': websiteUrl,
      'established_year': establishedYear,
      'market_share': marketShare,
      'awards': awards,
    };
  }
}

class InsurancePolicy {
  final String id;
  final int ownerId;
  final String vehicleId;
  final String providerId;
  final String insuranceType;
  final DateTime? commencementDate;
  final DateTime? expiryDate;
  final int? premiumAmount;
  final Map<String, dynamic>? coverageDetails;
  final int? deductibleAmount;
  final String? policyNumber;
  final String status;
  final bool renewalReminderSent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InsurancePolicy({
    required this.id,
    required this.ownerId,
    required this.vehicleId,
    required this.providerId,
    required this.insuranceType,
    this.commencementDate,
    this.expiryDate,
    this.premiumAmount,
    this.coverageDetails,
    this.deductibleAmount,
    this.policyNumber,
    required this.status,
    required this.renewalReminderSent,
    required this.createdAt,
    this.updatedAt,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? '',
      providerId: json['provider_id'] ?? '',
      insuranceType: json['insurance_type'] ?? '',
      commencementDate: json['commencement_date'] != null ? DateTime.parse(json['commencement_date']) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      premiumAmount: json['premium_amount'],
      coverageDetails: json['coverage_details'],
      deductibleAmount: json['deductible_amount'],
      policyNumber: json['policy_number'],
      status: json['status'] ?? 'active',
      renewalReminderSent: json['renewal_reminder_sent'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'vehicle_id': vehicleId,
      'provider_id': providerId,
      'insurance_type': insuranceType,
      'commencement_date': commencementDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'premium_amount': premiumAmount,
      'coverage_details': coverageDetails,
      'deductible_amount': deductibleAmount,
      'policy_number': policyNumber,
      'status': status,
      'renewal_reminder_sent': renewalReminderSent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon => expiryDate != null && 
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 30)));
}

class InsuranceClaim {
  //this is the model for the insurance claim, it is used to store the insurance claim data
  final String id;
  final String policyId;
  final String vehicleId;
  final int userId;
  final String claimType;
  final DateTime? incidentDate;
  final String? description;
  final int? estimatedCost;
  final int? actualCost;
  final String status;
  final String? claimNumber;
  final List<String>? evidenceFiles;
  final List<Map<String, dynamic>>? repairQuotes;
  final String? assignedAdjuster;
  final String? reviewNotes;
  final int? approvedAmount;
  final DateTime? paymentDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  //this is the constructor for the insurance claim model, it is used to create a new insurance claim
  InsuranceClaim({
    required this.id,
    required this.policyId,
    required this.vehicleId,
    required this.userId,
    required this.claimType,
    this.incidentDate,
    this.description,
    this.estimatedCost,
    this.actualCost,
    required this.status,
    this.claimNumber,
    this.evidenceFiles,
    this.repairQuotes,
    this.assignedAdjuster,
    this.reviewNotes,
    this.approvedAmount,
    this.paymentDate,
    required this.createdAt,
    this.updatedAt,
  });
  //this is the factory constructor for the insurance claim model, it is used to create a new insurance claim from a map of data
  
  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      id: json['id'] ?? '',
      policyId: json['policy_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      userId: json['user_id'] ?? 0,
      claimType: json['claim_type'] ?? '',
      incidentDate: json['incident_date'] != null ? DateTime.parse(json['incident_date']) : null,
      description: json['description'],
      estimatedCost: json['estimated_cost'],
      actualCost: json['actual_cost'],
      status: json['status'] ?? 'submitted',
      claimNumber: json['claim_number'],
      evidenceFiles: json['evidence_files']?.cast<String>(),
      repairQuotes: json['repair_quotes']?.cast<Map<String, dynamic>>(),
      assignedAdjuster: json['assigned_adjuster'],
      reviewNotes: json['review_notes'],
      approvedAmount: json['approved_amount'],
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'policy_id': policyId,
      'vehicle_id': vehicleId,
      'user_id': userId,
      'claim_type': claimType,
      'incident_date': incidentDate?.toIso8601String(),
      'description': description,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'status': status,
      'claim_number': claimNumber,
      'evidence_files': evidenceFiles,
      'repair_quotes': repairQuotes,
      'assigned_adjuster': assignedAdjuster,
      'review_notes': reviewNotes,
      'approved_amount': approvedAmount,
      'payment_date': paymentDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class RiskScore {
  final String id;
  final String vehicleId;
  final int userId;
  final int? vehicleRiskScore;
  final int? driverRiskScore;
  final int? combinedRiskScore;
  final Map<String, dynamic>? riskFactors;
  final String? scoringAlgorithmVersion;
  final Map<String, dynamic>? dataPointsUsed;
  final DateTime? lastUpdated;
  final DateTime createdAt;

  RiskScore({
    required this.id,
    required this.vehicleId,
    required this.userId,
    this.vehicleRiskScore,
    this.driverRiskScore,
    this.combinedRiskScore,
    this.riskFactors,
    this.scoringAlgorithmVersion,
    this.dataPointsUsed,
    this.lastUpdated,
    required this.createdAt,
  });

  factory RiskScore.fromJson(Map<String, dynamic> json) {
    return RiskScore(
      id: json['id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      userId: json['user_id'] ?? 0,
      vehicleRiskScore: json['vehicle_risk_score'],
      driverRiskScore: json['driver_risk_score'],
      combinedRiskScore: json['combined_risk_score'],
      riskFactors: json['risk_factors'],
      scoringAlgorithmVersion: json['scoring_algorithm_version'],
      dataPointsUsed: json['data_points_used'],
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'user_id': userId,
      'vehicle_risk_score': vehicleRiskScore,
      'driver_risk_score': driverRiskScore,
      'combined_risk_score': combinedRiskScore,
      'risk_factors': riskFactors,
      'scoring_algorithm_version': scoringAlgorithmVersion,
      'data_points_used': dataPointsUsed,
      'last_updated': lastUpdated?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get riskLevel {
    final score = combinedRiskScore ?? 0;
    if (score >= 80) return 'Low Risk';
    if (score >= 60) return 'Medium Risk';
    if (score >= 40) return 'High Risk';
    return 'Very High Risk';
  }

  String get riskColor {
    final score = combinedRiskScore ?? 0;
    if (score >= 80) return 'green';
    if (score >= 60) return 'orange';
    if (score >= 40) return 'red';
    return 'darkred';
  }
}

class InsuranceQuote {
  final String partnerId;
  final String partnerName;
  final int premiumAmount;
  final Map<String, dynamic> coverageDetails;
  final int deductibleAmount;
  final DateTime quoteValidUntil;
  final String? termsAndConditions;

  InsuranceQuote({
    required this.partnerId,
    required this.partnerName,
    required this.premiumAmount,
    required this.coverageDetails,
    required this.deductibleAmount,
    required this.quoteValidUntil,
    this.termsAndConditions,
  });

  factory InsuranceQuote.fromJson(Map<String, dynamic> json) {
    return InsuranceQuote(
      partnerId: json['partner_id'] ?? '',
      partnerName: json['partner_name'] ?? '',
      premiumAmount: json['premium_amount'] ?? 0,
      coverageDetails: json['coverage_details'] ?? {},
      deductibleAmount: json['deductible_amount'] ?? 0,
      quoteValidUntil: DateTime.parse(json['quote_valid_until']),
      termsAndConditions: json['terms_and_conditions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_id': partnerId,
      'partner_name': partnerName,
      'premium_amount': premiumAmount,
      'coverage_details': coverageDetails,
      'deductible_amount': deductibleAmount,
      'quote_valid_until': quoteValidUntil.toIso8601String(),
      'terms_and_conditions': termsAndConditions,
    };
  }

  String get formattedPremium => 'KSh ${(premiumAmount / 100).toStringAsFixed(0)}';
  String get formattedDeductible => 'KSh ${(deductibleAmount / 100).toStringAsFixed(0)}';
}
