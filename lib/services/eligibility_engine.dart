import 'dart:math';

import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';

class EligibilityEngine {
  const EligibilityEngine();

  // Evaluate single
  EligibilityModel evaluateScheme(
    SchemeModel scheme,
    Map<String, dynamic> userAnswers,
  ) {
    final normalized = _normalizeAnswers(userAnswers);
    final conditionResults = <EligibilityConditionResult>[];
    final missingInformation = <String>[];

    bool anyMandatoryFailed = false;
    bool anyMandatoryPending = false;

    for (final rule in scheme.eligibilityRules) {
      final result = _evaluateRule(rule, normalized);
      conditionResults.add(result);

      if (result.status == ConditionStatus.failed && rule.isMandatory) {
        anyMandatoryFailed = true;
      } else if (result.status == ConditionStatus.pending && rule.isMandatory) {
        anyMandatoryPending = true;
        if (!missingInformation.contains(rule.field)) {
          missingInformation.add(rule.field);
        }
      }
    }

    final EligibilityResult overallResult;
    if (anyMandatoryFailed) {
      overallResult = EligibilityResult.doesNotQualify;
    } else if (anyMandatoryPending) {
      overallResult = EligibilityResult.needsMoreInformation;
    } else {
      overallResult = EligibilityResult.mayQualify;
    }

    final explanation = _generateExplanation(conditionResults, scheme.name);
    final userId = userAnswers['userId']?.toString() ??
        userAnswers['uid']?.toString() ??
        'session_user';

    return EligibilityModel(
      assessmentId: _generateUuid(),
      userId: userId,
      schemeId: scheme.schemeId,
      result: overallResult,
      explanation: explanation,
      conditionResults: conditionResults,
      missingInformation: missingInformation,
      assessedAt: DateTime.now(),
    );
  }

  // Evaluate all
  List<EligibilityModel> evaluateAllSchemes(
    List<SchemeModel> schemes,
    Map<String, dynamic> userAnswers,
  ) {
    final schemeMap = {for (final s in schemes) s.schemeId: s};
    final evaluations = schemes
        .map((scheme) => evaluateScheme(scheme, userAnswers))
        .toList();

    evaluations.sort((a, b) {
      final rankA = _resultRank(a.result);
      final rankB = _resultRank(b.result);

      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }

      if (a.result == EligibilityResult.mayQualify) {
        final schemeA = schemeMap[a.schemeId];
        final schemeB = schemeMap[b.schemeId];

        final isPopularA = schemeA?.isPopular ?? false;
        final isPopularB = schemeB?.isPopular ?? false;
        if (isPopularA != isPopularB) {
          return isPopularA ? -1 : 1;
        }

        final popRankA = schemeA?.popularityRank ?? 999;
        final popRankB = schemeB?.popularityRank ?? 999;
        if (popRankA != popRankB) {
          return popRankA.compareTo(popRankB);
        }

        final passedA = a.conditionResults
            .where((c) => c.status == ConditionStatus.passed)
            .length;
        final passedB = b.conditionResults
            .where((c) => c.status == ConditionStatus.passed)
            .length;
        return passedB.compareTo(passedA);
      }

      if (a.result == EligibilityResult.needsMoreInformation) {
        return a.missingInformation.length
            .compareTo(b.missingInformation.length);
      }

      return 0;
    });

    return evaluations;
  }

  // Evaluate rule
  EligibilityConditionResult _evaluateRule(
    EligibilityRule rule,
    Map<String, dynamic> userAnswers,
  ) {
    if (!userAnswers.containsKey(rule.field) ||
        userAnswers[rule.field] == null) {
      return EligibilityConditionResult(
        field: rule.field,
        condition: rule.operator.name,
        expectedValue: rule.value,
        actualValue: null,
        status: ConditionStatus.pending,
        isMandatory: rule.isMandatory,
        explanation: rule.description ??
            'Information for ${rule.field} is required to assess eligibility.',
      );
    }

    final userValue = userAnswers[rule.field];
    final isSatisfied = _evaluateOperator(
      operator: rule.operator,
      userValue: userValue,
      ruleValue: rule.value,
    );

    final status =
        isSatisfied ? ConditionStatus.passed : ConditionStatus.failed;
    final explanation = isSatisfied
        ? (rule.description != null
            ? '${rule.description} (Criteria Met)'
            : 'Requirement for ${rule.field} is met.')
        : (rule.description != null
            ? 'Criteria not met: ${rule.description}'
            : 'Current ${rule.field} ($userValue) does not satisfy requirement (${rule.operator.name} ${rule.value}).');

    return EligibilityConditionResult(
      field: rule.field,
      condition: rule.operator.name,
      expectedValue: rule.value,
      actualValue: userValue,
      status: status,
      isMandatory: rule.isMandatory,
      explanation: explanation,
    );
  }

  // Operators
  bool _evaluateOperator({
    required EligibilityOperator operator,
    required dynamic userValue,
    required dynamic ruleValue,
  }) {
    switch (operator) {
      case EligibilityOperator.equals:
        return _checkEquals(userValue, ruleValue);

      case EligibilityOperator.notEquals:
        return !_checkEquals(userValue, ruleValue);

      case EligibilityOperator.greaterThan:
        final uNum = _parseNum(userValue);
        final rNum = _parseNum(ruleValue);
        if (uNum == null || rNum == null) return false;
        return uNum > rNum;

      case EligibilityOperator.greaterThanOrEqual:
        final uNum = _parseNum(userValue);
        final rNum = _parseNum(ruleValue);
        if (uNum == null || rNum == null) return false;
        return uNum >= rNum;

      case EligibilityOperator.lessThan:
        final uNum = _parseNum(userValue);
        final rNum = _parseNum(ruleValue);
        if (uNum == null || rNum == null) return false;
        return uNum < rNum;

      case EligibilityOperator.lessThanOrEqual:
        final uNum = _parseNum(userValue);
        final rNum = _parseNum(ruleValue);
        if (uNum == null || rNum == null) return false;
        return uNum <= rNum;

      case EligibilityOperator.inList:
        return _checkInList(userValue, ruleValue);

      case EligibilityOperator.notInList:
        return !_checkInList(userValue, ruleValue);

      case EligibilityOperator.isTrue:
        return _isTruthy(userValue);

      case EligibilityOperator.isFalse:
        return _isFalsy(userValue);
    }
  }

  // Explanation
  String _generateExplanation(
    List<EligibilityConditionResult> results,
    String schemeName,
  ) {
    final failedMandatory = results
        .where((c) => c.status == ConditionStatus.failed && c.isMandatory)
        .toList();
    final pendingMandatory = results
        .where((c) => c.status == ConditionStatus.pending && c.isMandatory)
        .toList();

    if (failedMandatory.isNotEmpty) {
      final reasons = failedMandatory
          .map((c) => c.explanation ?? '${c.field} did not match')
          .join('; ');
      return 'You currently do not qualify for $schemeName. Reason: $reasons.';
    }

    if (pendingMandatory.isNotEmpty) {
      final missingFields =
          pendingMandatory.map((c) => c.field).toSet().join(', ');
      return 'More information is required to confirm eligibility for $schemeName. Please provide details for: $missingFields.';
    }

    final failedOptional = results
        .where((c) => c.status == ConditionStatus.failed && !c.isMandatory)
        .toList();
    if (failedOptional.isNotEmpty) {
      final notes = failedOptional
          .map((c) => c.explanation ?? '${c.field} optional criteria missed')
          .join('; ');
      return 'You qualify for all mandatory requirements of $schemeName! Note regarding optional criteria: $notes.';
    }

    return 'Congratulations! You appear to satisfy all mandatory eligibility criteria for $schemeName.';
  }

  // Borderline
  List<String> _detectBorderlineConditions(
    List<EligibilityConditionResult> results,
    Map<String, dynamic> userAnswers,
  ) {
    final warnings = <String>[];

    for (final result in results) {
      final actual = _parseNum(result.actualValue ?? userAnswers[result.field]);
      final expected = _parseNum(result.expectedValue);

      if (actual == null || expected == null || expected == 0) {
        continue;
      }

      final op = result.condition;
      final isNumericCondition = op == EligibilityOperator.greaterThan.name ||
          op == EligibilityOperator.greaterThanOrEqual.name ||
          op == EligibilityOperator.lessThan.name ||
          op == EligibilityOperator.lessThanOrEqual.name;

      if (!isNumericCondition) {
        continue;
      }

      final difference = (actual - expected).abs();
      final threshold = expected.abs() * 0.10;

      if (difference <= threshold) {
        final percentage = (difference / expected.abs() * 100).toStringAsFixed(1);
        final statusDesc = result.status == ConditionStatus.passed
            ? 'meets the requirement but is near the boundary'
            : 'missed the cutoff by a small margin';

        warnings.add(
          'Borderline for ${result.field}: Your value ($actual) is within $percentage% of the scheme limit ($expected). '
          'Your status currently $statusDesc. Official documentation and allowable deductions may influence final acceptance.',
        );
      }
    }

    return warnings;
  }

  List<String> detectBorderlineConditions(
    EligibilityModel model,
    Map<String, dynamic> userAnswers,
  ) {
    return _detectBorderlineConditions(model.conditionResults, userAnswers);
  }

  Map<String, dynamic> _normalizeAnswers(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);

    // 1. Synthesize ownsCultivableLand from landOwnership if present
    if (!normalized.containsKey('ownsCultivableLand') && normalized.containsKey('landOwnership')) {
      final land = _parseNum(normalized['landOwnership']);
      if (land != null && land > 0) {
        normalized['ownsCultivableLand'] = true;
      }
    }

    // 2. Synthesize isDependentOfExServiceman from isExServiceman
    if (!normalized.containsKey('isDependentOfExServiceman') && normalized.containsKey('isExServiceman')) {
      normalized['isDependentOfExServiceman'] = normalized['isExServiceman'];
    }

    // 3. Synthesize isVulnerableCategory from caste or BPL/ration card
    if (!normalized.containsKey('isVulnerableCategory')) {
      final caste = normalized['casteCategory']?.toString().toLowerCase();
      final hasPriority = normalized['hasPriorityRationCard'] == true || normalized['bplCard'] == true;
      if (caste == 'sc' || caste == 'st' || hasPriority) {
        normalized['isVulnerableCategory'] = true;
      }
    }

    // 4. Synthesize hasAadhaarOrIdProof from bank account or explicit aadhaar
    if (!normalized.containsKey('hasAadhaarOrIdProof')) {
      if (normalized['hasBankAccount'] == true || normalized['hasAadhaar'] == true) {
        normalized['hasAadhaarOrIdProof'] = true;
      }
    }

    // 5. Ayushman Vay Vandana: Senior citizens 70+ qualify for PM-JAY regardless of ration card
    if (!normalized.containsKey('hasPriorityRationCard') && normalized.containsKey('age')) {
      final ageNum = _parseNum(normalized['age']);
      if (ageNum != null && ageNum >= 70) {
        normalized['hasPriorityRationCard'] = true;
      }
    }

    // 6. Legally exempt from income tax if declared income is <= ₹2.5L
    if (!normalized.containsKey('isIncomeTaxPayer') && normalized.containsKey('annualIncome')) {
      final inc = _parseNum(normalized['annualIncome']);
      if (inc != null && inc <= 250000) {
        normalized['isIncomeTaxPayer'] = false;
      }
    }

    // 7. Non-government employee inference from declared non-government occupation
    if (!normalized.containsKey('isGovernmentEmployee') && normalized.containsKey('occupation')) {
      final occ = normalized['occupation'].toString().toLowerCase();
      if (occ != 'government_employee') {
        normalized['isGovernmentEmployee'] = false;
      }
    }

    // 8. Individual citizen applicant is not an institutional landholder
    if (!normalized.containsKey('isInstitutionalLandholder')) {
      normalized['isInstitutionalLandholder'] = false;
    }

    // 9. Unify motorized vehicle and four wheeler flags
    if (!normalized.containsKey('hasFourWheeler') && normalized.containsKey('hasMotorizedVehicle')) {
      normalized['hasFourWheeler'] = normalized['hasMotorizedVehicle'];
    }
    if (!normalized.containsKey('hasMotorizedVehicle') && normalized.containsKey('hasFourWheeler')) {
      normalized['hasMotorizedVehicle'] = normalized['hasFourWheeler'];
    }
    if (!normalized.containsKey('hasFourWheeler') && normalized.containsKey('ownsFourWheeler')) {
      normalized['hasFourWheeler'] = normalized['ownsFourWheeler'];
    }
    if (!normalized.containsKey('ownsFourWheeler') && normalized.containsKey('hasFourWheeler')) {
      normalized['ownsFourWheeler'] = normalized['hasFourWheeler'];
    }

    return normalized;
  }

  // Helpers
  int _resultRank(EligibilityResult result) {
    switch (result) {
      case EligibilityResult.mayQualify:
        return 0;
      case EligibilityResult.needsMoreInformation:
        return 1;
      case EligibilityResult.doesNotQualify:
        return 2;
    }
  }

  bool _checkEquals(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    final aNum = _parseNum(a);
    final bNum = _parseNum(b);
    if (aNum != null && bNum != null) {
      return (aNum - bNum).abs() < 0.000001;
    }

    if (a is bool || b is bool) {
      return _isTruthy(a) == _isTruthy(b);
    }

    return a.toString().trim().toLowerCase() ==
        b.toString().trim().toLowerCase();
  }

  bool _checkInList(dynamic userValue, dynamic ruleValue) {
    if (ruleValue is! Iterable) {
      return _checkEquals(userValue, ruleValue);
    }

    final targetList = ruleValue.toList();

    if (userValue is Iterable) {
      for (final u in userValue) {
        if (targetList.any((r) => _checkEquals(u, r))) {
          return true;
        }
      }
      return false;
    }

    return targetList.any((r) => _checkEquals(userValue, r));
  }

  bool _isTruthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final str = v.toString().trim().toLowerCase();
    return str == 'true' || str == 'yes' || str == '1';
  }

  bool _isFalsy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return !v;
    if (v is num) return v == 0;
    final str = v.toString().trim().toLowerCase();
    return str == 'false' || str == 'no' || str == '0';
  }

  num? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString().trim());
  }

  // UUID generator
  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
