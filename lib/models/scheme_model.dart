import 'package:sahay/services/document_catalogue_service.dart';

enum GovernmentLevel {
  central,
  state,
}

enum SchemeStatus {
  active,
  inactive,
  underVerification,
}

enum VerificationStatus {
  pending,
  verified,
  rejected,
}

enum SchemeSourceType {
  curated,
  discovered,
}

enum EligibilityOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  inList,
  notInList,
  isTrue,
  isFalse,
}

class EligibilityRule {
  final String field;
  final EligibilityOperator operator;
  final dynamic value;
  final bool isMandatory;
  final String? description;
  final String? descriptionHindi;
  final String? sourceUrl;
  final String? sourceQuote;
  final String? verifyingDocument;
  final String? verifyingDocumentHindi;

  const EligibilityRule({
    required this.field,
    required this.operator,
    required this.value,
    this.isMandatory = true,
    this.description,
    this.descriptionHindi,
    this.sourceUrl,
    this.sourceQuote,
    this.verifyingDocument,
    this.verifyingDocumentHindi,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'operator': operator.name,
      'value': value,
      'isMandatory': isMandatory,
      'description': description,
      'descriptionHindi': descriptionHindi,
      'sourceUrl': sourceUrl,
      'sourceQuote': sourceQuote,
      'verifyingDocument': verifyingDocument,
      'verifyingDocumentHindi': verifyingDocumentHindi,
    };
  }

  factory EligibilityRule.fromMap(Map<String, dynamic> map) {
    return EligibilityRule(
      field: map['field'] as String? ?? '',
      operator: EligibilityOperator.values.firstWhere(
        (e) => e.name == map['operator'],
        orElse: () => EligibilityOperator.equals,
      ),
      value: map['value'],
      isMandatory: map['isMandatory'] as bool? ?? true,
      description: map['description'] as String?,
      descriptionHindi: map['descriptionHindi'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
      sourceQuote: map['sourceQuote'] as String?,
      verifyingDocument: map['verifyingDocument'] as String?,
      verifyingDocumentHindi: map['verifyingDocumentHindi'] as String?,
    );
  }
}

class SchemeModel {
  // Unique identification
  final String schemeId;

  // Scheme information
  final String name;
  final String? nameHindi;
  final String description;
  final String? descriptionHindi;

  // Classification
  final String category;
  final String ministry;
  final GovernmentLevel governmentLevel;
  final List<String> applicableStates;

  // Benefits
  final String benefits;
  final String? benefitsHindi;

  // Eligibility
  final List<EligibilityRule> eligibilityRules;

  // Documents and application
  final List<String> requiredDocuments;
  final String applicationProcess;
  final String? applicationUrl;

  /// Returns canonical document IDs matched against DocumentCatalogueService
  List<String> get requiredDocumentIds =>
      requiredDocuments.map((doc) => DocumentCatalogueService.matchCanonicalId(doc)).toList();


  // Source information
  final String officialSourceUrl;
  final String? sourceName;
  final SchemeSourceType sourceType;
  final DateTime? discoveredAt;

  // Verification
  final VerificationStatus verificationStatus;
  final SchemeStatus status;
  final DateTime? lastVerified;

  // Popular schemes
  final bool isPopular;
  final int popularityRank;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchemeModel({
    required this.schemeId,
    required this.name,
    this.nameHindi,
    required this.description,
    this.descriptionHindi,
    required this.category,
    required this.ministry,
    required this.governmentLevel,
    this.applicableStates = const [],
    required this.benefits,
    this.benefitsHindi,
    this.eligibilityRules = const [],
    this.requiredDocuments = const [],
    required this.applicationProcess,
    this.applicationUrl,
    required this.officialSourceUrl,
    this.sourceName,
    this.sourceType = SchemeSourceType.curated,
    this.discoveredAt,
    this.verificationStatus = VerificationStatus.pending,
    this.status = SchemeStatus.underVerification,
    this.lastVerified,
    this.isPopular = false,
    this.popularityRank = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert object into Map
  Map<String, dynamic> toMap() {
    return {
      'schemeId': schemeId,
      'name': name,
      'nameHindi': nameHindi,
      'description': description,
      'descriptionHindi': descriptionHindi,
      'category': category,
      'ministry': ministry,
      'governmentLevel': governmentLevel.name,
      'applicableStates': applicableStates,
      'benefits': benefits,
      'benefitsHindi': benefitsHindi,
      'eligibilityRules':
          eligibilityRules.map((rule) => rule.toMap()).toList(),
      'requiredDocuments': requiredDocuments,
      'applicationProcess': applicationProcess,
      'applicationUrl': applicationUrl,
      'officialSourceUrl': officialSourceUrl,
      'sourceName': sourceName,
      'sourceType': sourceType.name,
      'discoveredAt': discoveredAt?.toIso8601String(),
      'verificationStatus': verificationStatus.name,
      'status': status.name,
      'lastVerified': lastVerified?.toIso8601String(),
      'isPopular': isPopular,
      'popularityRank': popularityRank,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert Map into object
  factory SchemeModel.fromMap(Map<String, dynamic> map) {
    return SchemeModel(
      schemeId: map['schemeId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameHindi: map['nameHindi'] as String?,
      description: map['description'] as String? ?? '',
      descriptionHindi: map['descriptionHindi'] as String?,
      category: map['category'] as String? ?? '',
      ministry: map['ministry'] as String? ?? '',

      governmentLevel: GovernmentLevel.values.firstWhere(
        (e) => e.name == map['governmentLevel'],
        orElse: () => GovernmentLevel.central,
      ),

      applicableStates:
          List<String>.from(map['applicableStates'] ?? []),

      benefits: map['benefits'] as String? ?? '',
      benefitsHindi: map['benefitsHindi'] as String?,

      eligibilityRules:
          (map['eligibilityRules'] as List? ?? [])
              .map(
                (rule) => EligibilityRule.fromMap(
                  Map<String, dynamic>.from(rule),
                ),
              )
              .toList(),

      requiredDocuments:
          List<String>.from(map['requiredDocuments'] ?? []),

      applicationProcess:
          map['applicationProcess'] as String? ?? '',

      applicationUrl: map['applicationUrl'] as String?,

      officialSourceUrl:
          map['officialSourceUrl'] as String? ?? '',

      sourceName: map['sourceName'] as String?,

      sourceType: SchemeSourceType.values.firstWhere(
        (e) => e.name == map['sourceType'],
        orElse: () => SchemeSourceType.curated,
      ),

      discoveredAt: _parseDate(map['discoveredAt']),

      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == map['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),

      status: SchemeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SchemeStatus.underVerification,
      ),

      lastVerified: _parseDate(map['lastVerified']),

      isPopular: map['isPopular'] as bool? ?? false,
      popularityRank: map['popularityRank'] as int? ?? 0,

      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  // Create updated copy
  SchemeModel copyWith({
    String? name,
    String? nameHindi,
    String? description,
    String? descriptionHindi,
    String? category,
    String? ministry,
    GovernmentLevel? governmentLevel,
    List<String>? applicableStates,
    String? benefits,
    String? benefitsHindi,
    List<EligibilityRule>? eligibilityRules,
    List<String>? requiredDocuments,
    String? applicationProcess,
    String? applicationUrl,
    String? officialSourceUrl,
    String? sourceName,
    SchemeSourceType? sourceType,
    DateTime? discoveredAt,
    VerificationStatus? verificationStatus,
    SchemeStatus? status,
    DateTime? lastVerified,
    bool? isPopular,
    int? popularityRank,
    DateTime? updatedAt,
  }) {
    return SchemeModel(
      schemeId: schemeId,
      name: name ?? this.name,
      nameHindi: nameHindi ?? this.nameHindi,
      description: description ?? this.description,
      descriptionHindi: descriptionHindi ?? this.descriptionHindi,
      category: category ?? this.category,
      ministry: ministry ?? this.ministry,
      governmentLevel: governmentLevel ?? this.governmentLevel,
      applicableStates: applicableStates ?? this.applicableStates,
      benefits: benefits ?? this.benefits,
      benefitsHindi: benefitsHindi ?? this.benefitsHindi,
      eligibilityRules: eligibilityRules ?? this.eligibilityRules,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      applicationProcess: applicationProcess ?? this.applicationProcess,
      applicationUrl: applicationUrl ?? this.applicationUrl,
      officialSourceUrl: officialSourceUrl ?? this.officialSourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      verificationStatus:
          verificationStatus ?? this.verificationStatus,
      status: status ?? this.status,
      lastVerified: lastVerified ?? this.lastVerified,
      isPopular: isPopular ?? this.isPopular,
      popularityRank: popularityRank ?? this.popularityRank,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Date conversion helper
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
