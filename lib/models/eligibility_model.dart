enum EligibilityResult {
  mayQualify,
  needsMoreInformation,
  doesNotQualify,
}

enum ConditionStatus {
  passed,
  failed,
  pending,
}

class EligibilityConditionResult {
  final String field;
  final String condition;
  final dynamic expectedValue;
  final dynamic actualValue;
  final ConditionStatus status;
  final bool isMandatory;
  final String? explanation;

  const EligibilityConditionResult({
    required this.field,
    required this.condition,
    this.expectedValue,
    this.actualValue,
    required this.status,
    this.isMandatory = true,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'condition': condition,
      'expectedValue': expectedValue,
      'actualValue': actualValue,
      'status': status.name,
      'isMandatory': isMandatory,
      'explanation': explanation,
    };
  }

  factory EligibilityConditionResult.fromMap(
    Map<String, dynamic> map,
  ) {
    return EligibilityConditionResult(
      field: map['field'] as String? ?? '',
      condition: map['condition'] as String? ?? '',
      expectedValue: map['expectedValue'],
      actualValue: map['actualValue'],
      status: ConditionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ConditionStatus.pending,
      ),
      isMandatory: map['isMandatory'] as bool? ?? true,
      explanation: map['explanation'] as String?,
    );
  }
}

class EligibilityModel {
  final String assessmentId;
  final String userId;
  final String schemeId;

  final EligibilityResult result;
  final String explanation;

  final List<EligibilityConditionResult> conditionResults;
  final List<String> missingInformation;

  final DateTime assessedAt;
  final DateTime? updatedAt;

  const EligibilityModel({
    required this.assessmentId,
    required this.userId,
    required this.schemeId,
    required this.result,
    required this.explanation,
    this.conditionResults = const [],
    this.missingInformation = const [],
    required this.assessedAt,
    this.updatedAt,
  });

  // Convert EligibilityModel into a Map.
  Map<String, dynamic> toMap() {
    return {
      'assessmentId': assessmentId,
      'userId': userId,
      'schemeId': schemeId,
      'result': result.name,
      'explanation': explanation,
      'conditionResults': conditionResults
          .map((condition) => condition.toMap())
          .toList(),
      'missingInformation': missingInformation,
      'assessedAt': assessedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create EligibilityModel from a Map.
  factory EligibilityModel.fromMap(Map<String, dynamic> map) {
    return EligibilityModel(
      assessmentId: map['assessmentId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      schemeId: map['schemeId'] as String? ?? '',

      result: EligibilityResult.values.firstWhere(
        (e) => e.name == map['result'],
        orElse: () => EligibilityResult.needsMoreInformation,
      ),

      explanation: map['explanation'] as String? ?? '',

      conditionResults: (map['conditionResults'] as List? ?? [])
          .map(
            (condition) => EligibilityConditionResult.fromMap(
              Map<String, dynamic>.from(condition),
            ),
          )
          .toList(),

      missingInformation:
          List<String>.from(map['missingInformation'] ?? []),

      assessedAt: _parseDate(map['assessedAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  // Create an updated copy of the assessment.
  EligibilityModel copyWith({
    EligibilityResult? result,
    String? explanation,
    List<EligibilityConditionResult>? conditionResults,
    List<String>? missingInformation,
    DateTime? updatedAt,
  }) {
    return EligibilityModel(
      assessmentId: assessmentId,
      userId: userId,
      schemeId: schemeId,
      result: result ?? this.result,
      explanation: explanation ?? this.explanation,
      conditionResults: conditionResults ?? this.conditionResults,
      missingInformation:
          missingInformation ?? this.missingInformation,
      assessedAt: assessedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
