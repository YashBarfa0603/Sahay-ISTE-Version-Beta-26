import 'package:sahay/models/scheme_model.dart';

/// Standard Health Check Response from FastAPI backend.
class BackendHealthResponse {
  final String status;
  final String app;
  final String version;
  final String ollamaModel;
  final int trustedDomainsCount;

  const BackendHealthResponse({
    required this.status,
    required this.app,
    required this.version,
    required this.ollamaModel,
    required this.trustedDomainsCount,
  });

  factory BackendHealthResponse.fromJson(Map<String, dynamic> json) {
    return BackendHealthResponse(
      status: json['status']?.toString() ?? 'unknown',
      app: json['app']?.toString() ?? 'SAHAY Backend API',
      version: json['version']?.toString() ?? '1.0.0',
      ollamaModel: json['ollama_model']?.toString() ?? 'qwen2.5:latest',
      trustedDomainsCount: (json['trusted_domains_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Request for Scheme Discovery Search.
class SchemeSearchApiRequest {
  final String query;
  final String? category;
  final GovernmentLevel? governmentLevel;
  final String? state;
  final bool forceDynamicDiscovery;

  const SchemeSearchApiRequest({
    required this.query,
    this.category,
    this.governmentLevel,
    this.state,
    this.forceDynamicDiscovery = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (governmentLevel != null) 'governmentLevel': governmentLevel!.name,
      if (state != null && state!.isNotEmpty) 'state': state,
      'forceDynamicDiscovery': forceDynamicDiscovery,
    };
  }
}

/// Structured Response from Dynamic Discovery API.
class SchemeSearchApiResponse {
  final int total;
  final List<SchemeModel> results;
  final bool isDynamicDiscovery;
  final List<String> sourcesChecked;
  final String message;

  const SchemeSearchApiResponse({
    required this.total,
    required this.results,
    required this.isDynamicDiscovery,
    required this.sourcesChecked,
    required this.message,
  });

  factory SchemeSearchApiResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    final schemes = rawResults
        .map((item) => SchemeModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return SchemeSearchApiResponse(
      total: (json['total'] as num?)?.toInt() ?? schemes.length,
      results: schemes,
      isDynamicDiscovery: json['isDynamicDiscovery'] as bool? ?? false,
      sourcesChecked: (json['sourcesChecked'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Income Estimation Request.
class IncomeEstimationRequest {
  final String primarySource;
  final double? monthlyEstimatedIncome;
  final int householdEarners;
  final bool hasAgriculturalIncome;
  final double? seasonalAgriculturalIncome;
  final String? notes;

  const IncomeEstimationRequest({
    required this.primarySource,
    this.monthlyEstimatedIncome,
    this.householdEarners = 1,
    this.hasAgriculturalIncome = false,
    this.seasonalAgriculturalIncome,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'primary_source': primarySource,
      'monthly_estimated_income': monthlyEstimatedIncome,
      'household_earners': householdEarners,
      'has_agricultural_income': hasAgriculturalIncome,
      'seasonal_agricultural_income': seasonalAgriculturalIncome,
      'notes': notes,
    };
  }
}

/// Income Estimation Result with conservative range.
class IncomeEstimationApiResponse {
  final double minAnnualIncome;
  final double maxAnnualIncome;
  final double medianEstimate;
  final String uncertaintyLevel; // 'low', 'moderate', 'high'
  final List<String> assumptions;
  final String explanation;
  final bool requiresOfficialVerification;

  const IncomeEstimationApiResponse({
    required this.minAnnualIncome,
    required this.maxAnnualIncome,
    required this.medianEstimate,
    required this.uncertaintyLevel,
    required this.assumptions,
    required this.explanation,
    this.requiresOfficialVerification = true,
  });

  factory IncomeEstimationApiResponse.fromJson(Map<String, dynamic> json) {
    return IncomeEstimationApiResponse(
      minAnnualIncome: (json['min_annual_income'] as num?)?.toDouble() ?? 0.0,
      maxAnnualIncome: (json['max_annual_income'] as num?)?.toDouble() ?? 0.0,
      medianEstimate: (json['median_estimate'] as num?)?.toDouble() ?? 0.0,
      uncertaintyLevel: json['uncertainty_level']?.toString() ?? 'moderate',
      assumptions: (json['assumptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      explanation: json['explanation']?.toString() ?? '',
      requiresOfficialVerification:
          json['requires_official_verification'] as bool? ?? true,
    );
  }
}

/// Rule Conflict or Inconsistency Report.
class ConflictReportModel {
  final String schemeId;
  final String schemeName;
  final String fieldName;
  final String conflictType; // 'official_discrepancy', 'outdated_rule', 'unverified_document'
  final List<String> conflictingSources;
  final String description;
  final String recommendedAction;
  final bool stopsAutomatedAssessment;

  const ConflictReportModel({
    required this.schemeId,
    required this.schemeName,
    required this.fieldName,
    required this.conflictType,
    required this.conflictingSources,
    required this.description,
    required this.recommendedAction,
    this.stopsAutomatedAssessment = false,
  });

  factory ConflictReportModel.fromJson(Map<String, dynamic> json) {
    return ConflictReportModel(
      schemeId: json['scheme_id']?.toString() ?? '',
      schemeName: json['scheme_name']?.toString() ?? '',
      fieldName: json['field_name']?.toString() ?? '',
      conflictType: json['conflict_type']?.toString() ?? 'official_discrepancy',
      conflictingSources: (json['conflicting_sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description']?.toString() ?? '',
      recommendedAction: json['recommended_action']?.toString() ?? '',
      stopsAutomatedAssessment:
          json['stops_automated_assessment'] as bool? ?? false,
    );
  }
}

/// Verified Common Service Centre (CSC) Model.
class CscCentreModel {
  final String centreId;
  final String name;
  final String vleName; // Village Level Entrepreneur
  final String state;
  final String district;
  final String pinCode;
  final String address;
  final String? contactNumber;
  final String? email;
  final List<String> servicesAvailable;
  final bool isVerified;
  final String officialPortalUrl;

  const CscCentreModel({
    required this.centreId,
    required this.name,
    required this.vleName,
    required this.state,
    required this.district,
    required this.pinCode,
    required this.address,
    this.contactNumber,
    this.email,
    required this.servicesAvailable,
    this.isVerified = true,
    this.officialPortalUrl = 'https://findmycsc.nic.in/',
  });

  factory CscCentreModel.fromJson(Map<String, dynamic> json) {
    return CscCentreModel(
      centreId: json['centre_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Common Service Centre',
      vleName: json['vle_name']?.toString() ?? 'CSC Operator',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      pinCode: json['pin_code']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString(),
      email: json['email']?.toString(),
      servicesAvailable: (json['services_available'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Scheme Application', 'Aadhaar eKYC', 'Certificate Issuance'],
      isVerified: json['is_verified'] as bool? ?? true,
      officialPortalUrl:
          json['official_portal_url']?.toString() ?? 'https://findmycsc.nic.in/',
    );
  }
}

/// CSC Search Response.
class CscSearchApiResponse {
  final int total;
  final List<CscCentreModel> centres;
  final String? state;
  final String? district;
  final String? pinCode;
  final String officialDirectoryUrl;

  const CscSearchApiResponse({
    required this.total,
    required this.centres,
    this.state,
    this.district,
    this.pinCode,
    this.officialDirectoryUrl = 'https://findmycsc.nic.in/',
  });

  factory CscSearchApiResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['centres'] as List<dynamic>? ?? [];
    final items = rawList
        .map((c) => CscCentreModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    return CscSearchApiResponse(
      total: (json['total'] as num?)?.toInt() ?? items.length,
      centres: items,
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      pinCode: json['pin_code']?.toString(),
      officialDirectoryUrl: json['official_directory_url']?.toString() ??
          'https://findmycsc.nic.in/',
    );
  }
}
