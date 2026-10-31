import 'dart:math';

import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';

class EligibilityEngine {
  const EligibilityEngine();

  // Evidence metadata and formatting helpers
  static const Map<String, Map<String, String>> _fieldMeta = {
    'age': {
      'label': 'Age',
      'labelHindi': 'आयु',
      'unit': 'years',
      'unitHindi': 'वर्ष',
      'document': 'Aadhaar Card / Birth Certificate',
      'documentHindi': 'आधार कार्ड / जन्म प्रमाण पत्र',
    },
    'annualIncome': {
      'label': 'Annual Income',
      'labelHindi': 'वार्षिक आय',
      'isCurrency': 'true',
      'document': 'Income Certificate',
      'documentHindi': 'आय प्रमाण पत्र',
    },
    'annualFamilyIncome': {
      'label': 'Annual Family Income',
      'labelHindi': 'वार्षिक पारिवारिक आय',
      'isCurrency': 'true',
      'document': 'Income Certificate (Tehsildar / SDO)',
      'documentHindi': 'आय प्रमाण पत्र (तहसीलदार / एसडीएम)',
    },
    'occupation': {
      'label': 'Primary Occupation',
      'labelHindi': 'मुख्य व्यवसाय',
      'document': 'Occupational ID / e-Shram Card / Labour Card',
      'documentHindi': 'व्यवसाय पहचान पत्र / ई-श्रम कार्ड',
    },
    'state': {
      'label': 'State / Domicile',
      'labelHindi': 'राज्य / मूल निवास',
      'document': 'Domicile Certificate / Aadhaar Card',
      'documentHindi': 'मूल निवास प्रमाण पत्र / आधार कार्ड',
    },
    'gender': {
      'label': 'Gender',
      'labelHindi': 'लिंग',
      'document': 'Aadhaar Card / Voter ID',
      'documentHindi': 'आधार कार्ड / मतदाता पहचान पत्र',
    },
    'casteCategory': {
      'label': 'Social / Caste Category',
      'labelHindi': 'सामाजिक वर्ग / जाति',
      'document': 'Caste Certificate',
      'documentHindi': 'जाति प्रमाण पत्र',
    },
    'residenceType': {
      'label': 'Residential Area',
      'labelHindi': 'निवास क्षेत्र',
      'document': 'Electricity Bill / Ration Card',
      'documentHindi': 'बिजली बिल / राशन कार्ड',
    },
    'maritalStatus': {
      'label': 'Marital Status',
      'labelHindi': 'वैवाहिक स्थिति',
      'document': 'Marriage Certificate / Death Certificate',
      'documentHindi': 'विवाह प्रमाण पत्र',
    },
    'disability': {
      'label': 'Benchmark Disability (40%+)',
      'labelHindi': 'दिव्यांगता (40% या अधिक)',
      'document': 'UDID Card / Disability Certificate',
      'documentHindi': 'यूडीआईडी कार्ड / दिव्यांगता प्रमाण पत्र',
    },
    'landOwnership': {
      'label': 'Agricultural Land Holding',
      'labelHindi': 'कृषि भूमि का स्वामित्व',
      'unit': 'hectares',
      'unitHindi': 'हेक्टेयर',
      'document': 'Land Revenue Records (Khasra-Khatoni)',
      'documentHindi': 'भू-अभिलेख (खसरा-खतौनी)',
    },
    'ownsCultivableLand': {
      'label': 'Cultivable Land Ownership',
      'labelHindi': 'कृषि भूमि का स्वामित्व',
      'document': 'Land Revenue Records (Khasra / Khatoni)',
      'documentHindi': 'भू-अभिलेख (खसरा / खतौनी)',
    },
    'hasBankAccount': {
      'label': 'Bank Account',
      'labelHindi': 'बैंक खाता',
      'document': 'Bank Passbook / Cancelled Cheque',
      'documentHindi': 'बैंक पासबुक / आधार लिंक बैंक खाता',
    },
    'hasAadhaar': {
      'label': 'Aadhaar Card',
      'labelHindi': 'आधार कार्ड',
      'document': 'Aadhaar Card',
      'documentHindi': 'आधार कार्ड',
    },
    'bplCard': {
      'label': 'BPL / Priority Ration Card',
      'labelHindi': 'बीपीएल / प्राथमिकता राशन कार्ड',
      'document': 'BPL Ration Card / NFSA Card',
      'documentHindi': 'बीपीएल राशन कार्ड',
    },
    'isFarmer': {
      'label': 'Farmer Status',
      'labelHindi': 'किसान स्थिति',
      'document': 'Land Records / Kisan Credit Card',
      'documentHindi': 'भू-अभिलेख / किसान क्रेडिट कार्ड',
    },
    'isGovtEmployee': {
      'label': 'Government Employment Status',
      'labelHindi': 'सरकारी नौकरी स्थिति',
      'document': 'Salary Slip / Departmental Declaration',
      'documentHindi': 'वेतन पर्ची / विभागीय घोषणा पत्र',
    },
    'isTaxpayer': {
      'label': 'Income Tax Payer Status',
      'labelHindi': 'आयकरदाता स्थिति',
      'document': 'ITR Acknowledgment / Form 16',
      'documentHindi': 'आईटीआर पावती / फॉर्म 16',
    },
  };

  static const Map<String, String> _stateCodeToName = {
    'AP': 'Andhra Pradesh',
    'AR': 'Arunachal Pradesh',
    'AS': 'Assam',
    'BR': 'Bihar',
    'CG': 'Chhattisgarh',
    'GA': 'Goa',
    'GJ': 'Gujarat',
    'HR': 'Haryana',
    'HP': 'Himachal Pradesh',
    'JH': 'Jharkhand',
    'KA': 'Karnataka',
    'KL': 'Kerala',
    'MP': 'Madhya Pradesh',
    'MH': 'Maharashtra',
    'MN': 'Manipur',
    'ML': 'Meghalaya',
    'MZ': 'Mizoram',
    'NL': 'Nagaland',
    'OD': 'Odisha',
    'PB': 'Punjab',
    'RJ': 'Rajasthan',
    'SK': 'Sikkim',
    'TN': 'Tamil Nadu',
    'TS': 'Telangana',
    'TR': 'Tripura',
    'UP': 'Uttar Pradesh',
    'UK': 'Uttarakhand',
    'WB': 'West Bengal',
    'DL': 'Delhi',
    'JK': 'Jammu and Kashmir',
    'LA': 'Ladakh',
    'CH': 'Chandigarh',
    'PY': 'Puducherry',
    'AN': 'Andaman and Nicobar Islands',
  };

  static String _formatCurrency(num value) {
    final intVal = value.toInt();
    final s = intVal.toString();
    if (s.length <= 3) return '₹$s';
    final lastThree = s.substring(s.length - 3);
    var remaining = s.substring(0, s.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      groups.insert(0, remaining);
    }
    return '₹${groups.join(',')},$lastThree';
  }

  static String _formatUserValue(String field, dynamic val) {
    if (val == null) return 'Not Provided';
    final meta = _fieldMeta[field] ?? const {};
    if (meta['isCurrency'] == 'true' && val is num) {
      return _formatCurrency(val);
    }
    if (val is bool) {
      return val ? 'Yes' : 'No';
    }
    final unit = meta['unit'];
    if (unit != null) {
      return '$val $unit';
    }
    if (val is String) {
      return val.replaceAll('_', ' ').split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    return val.toString();
  }

  static Map<String, String> _formatRequirement(EligibilityRule rule) {
    final field = rule.field;
    final meta = _fieldMeta[field] ?? const {};
    final isCur = meta['isCurrency'] == 'true';
    final unit = meta['unit'] ?? '';
    final val = rule.value;

    switch (rule.operator) {
      case EligibilityOperator.lessThanOrEqual:
      case EligibilityOperator.lessThan:
        if (isCur && val is num) {
          return {
            'en': 'At most ${_formatCurrency(val)}',
            'hi': 'अधिकतम ${_formatCurrency(val)}',
          };
        }
        return {
          'en': 'At most $val $unit'.trim(),
          'hi': 'अधिकतम $val $unit'.trim(),
        };

      case EligibilityOperator.greaterThanOrEqual:
      case EligibilityOperator.greaterThan:
        return {
          'en': 'At least $val $unit'.trim(),
          'hi': 'न्यूनतम $val $unit'.trim(),
        };

      case EligibilityOperator.equals:
        return {
          'en': 'Must be ${_formatUserValue(field, val)}',
          'hi': '${_formatUserValue(field, val)} होना आवश्यक है',
        };

      case EligibilityOperator.inList:
        final list = val is List ? val : [val];
        final disp = list.map((e) => _formatUserValue(field, e)).join(', ');
        return {
          'en': 'One of: $disp',
          'hi': 'इनमें से एक: $disp',
        };

      case EligibilityOperator.isTrue:
        return {
          'en': 'Must be applicable (Yes)',
          'hi': 'लागू होना आवश्यक है (हाँ)',
        };

      case EligibilityOperator.isFalse:
        return {
          'en': 'Must not be applicable (No)',
          'hi': 'लागू नहीं होना चाहिए (नहीं)',
        };

      default:
        return {
          'en': rule.description ?? '${rule.operator.name} $val',
          'hi': rule.descriptionHindi ?? rule.description ?? '${rule.operator.name} $val',
        };
    }
  }


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

  // Evaluate rule with structured condition-by-condition evidence
  EligibilityConditionResult _evaluateRule(
    EligibilityRule rule,
    Map<String, dynamic> userAnswers,
  ) {
    final field = rule.field;
    final meta = _fieldMeta[field] ?? const {};
    final label = meta['label'] ?? field.replaceAll('_', ' ');
    final labelHindi = meta['labelHindi'] ?? label;
    final reqMap = _formatRequirement(rule);
    final reqEn = reqMap['en']!;
    final reqHi = reqMap['hi']!;
    final docEn = rule.verifyingDocument ?? meta['document'] ?? 'Official Certificate';
    final docHi = rule.verifyingDocumentHindi ?? meta['documentHindi'] ?? 'आधिकारिक प्रमाण पत्र';

    if (!userAnswers.containsKey(field) || userAnswers[field] == null) {
      return EligibilityConditionResult(
        field: field,
        condition: rule.operator.name,
        expectedValue: rule.value,
        actualValue: null,
        status: ConditionStatus.pending,
        isMandatory: rule.isMandatory,
        explanation: 'Information for $label has not been provided. Please provide this detail to verify eligibility.',
        label: label,
        labelHindi: labelHindi,
        requiredDescription: reqEn,
        requiredDescriptionHindi: reqHi,
        formattedUserValue: 'Not Provided',
        verifyingDocument: docEn,
        verifyingDocumentHindi: docHi,
        sourceUrl: rule.sourceUrl,
        sourceQuote: rule.sourceQuote,
      );
    }

    final userValue = userAnswers[field];
    final formattedUser = _formatUserValue(field, userValue);

    // Operator comparison with state aliasing support
    final isSatisfied = _evaluateOperatorWithAliasing(
      field: field,
      operator: rule.operator,
      userValue: userValue,
      ruleValue: rule.value,
    );

    // Calculate numeric differences and borderline status
    String? diffDesc;
    bool isBorderline = false;
    final uNum = _parseNum(userValue);
    final rNum = _parseNum(rule.value);

    if (uNum != null && rNum != null) {
      final diff = (uNum - rNum).abs();
      if (rNum != 0 && (diff / rNum.abs()) <= 0.10) {
        isBorderline = true;
      }

      if (!isSatisfied) {
        if (rule.operator == EligibilityOperator.lessThan ||
            rule.operator == EligibilityOperator.lessThanOrEqual) {
          final over = uNum - rNum;
          final overFormatted = meta['isCurrency'] == 'true'
              ? _formatCurrency(over)
              : '$over ${meta['unit'] ?? ''}'.trim();
          diffDesc = '$overFormatted above the prescribed limit';
        } else if (rule.operator == EligibilityOperator.greaterThan ||
            rule.operator == EligibilityOperator.greaterThanOrEqual) {
          final under = rNum - uNum;
          final underFormatted = '$under ${meta['unit'] ?? ''}'.trim();
          diffDesc = '$underFormatted below the minimum required limit';
        }
      }
    }

    final status = isSatisfied ? ConditionStatus.passed : ConditionStatus.failed;

    // Build understandable evidence-based explanation
    String explanation;
    if (isSatisfied) {
      if (rule.operator == EligibilityOperator.lessThan ||
          rule.operator == EligibilityOperator.lessThanOrEqual) {
        explanation = 'Your reported ${label.toLowerCase()} ($formattedUser) is within the prescribed limit of ${reqEn.toLowerCase()}.';
      } else if (rule.operator == EligibilityOperator.greaterThan ||
          rule.operator == EligibilityOperator.greaterThanOrEqual) {
        explanation = 'Your ${label.toLowerCase()} ($formattedUser) satisfies the minimum requirement of ${reqEn.toLowerCase()}.';
      } else if (rule.operator == EligibilityOperator.equals) {
        explanation = 'Your ${label.toLowerCase()} ($formattedUser) matches the scheme\'s eligible requirement.';
      } else {
        explanation = 'Requirement for $label ($formattedUser) is satisfied.';
      }
    } else {
      if (diffDesc != null) {
        explanation = 'Your reported ${label.toLowerCase()} is $formattedUser, which exceeds the limit of $reqEn by $diffDesc.';
      } else if (rule.operator == EligibilityOperator.equals) {
        final expectedDisp = _formatUserValue(field, rule.value);
        explanation = 'The scheme requires ${label.toLowerCase()} to be $expectedDisp, but your reported ${label.toLowerCase()} is $formattedUser.';
      } else if (rule.operator == EligibilityOperator.inList) {
        explanation = 'Your ${label.toLowerCase()} ($formattedUser) is not in the scheme\'s eligible list ($reqEn).';
      } else {
        explanation = 'Criteria not met for $label: current value ($formattedUser) does not satisfy requirement ($reqEn).';
      }
    }

    return EligibilityConditionResult(
      field: field,
      condition: rule.operator.name,
      expectedValue: rule.value,
      actualValue: userValue,
      status: status,
      isMandatory: rule.isMandatory,
      explanation: explanation,
      label: label,
      labelHindi: labelHindi,
      requiredDescription: reqEn,
      requiredDescriptionHindi: reqHi,
      formattedUserValue: formattedUser,
      differenceDescription: diffDesc,
      verifyingDocument: docEn,
      verifyingDocumentHindi: docHi,
      sourceUrl: rule.sourceUrl,
      sourceQuote: rule.sourceQuote,
      isBorderline: isBorderline,
      verificationStatus: 'self_reported',
    );
  }

  bool _evaluateOperatorWithAliasing({
    required String field,
    required EligibilityOperator operator,
    required dynamic userValue,
    required dynamic ruleValue,
  }) {
    if (field == 'state' && operator == EligibilityOperator.inList && ruleValue is List) {
      final userStr = userValue.toString().trim().toLowerCase();
      for (final item in ruleValue) {
        final itemStr = item.toString().trim().toLowerCase();
        if (itemStr == 'all_india' || userStr == itemStr) return true;
        // Check state code to name mapping
        final mappedName = _stateCodeToName[item.toString().trim().toUpperCase()]?.toLowerCase();
        if (mappedName != null && mappedName == userStr) return true;
      }
      return false;
    }
    return _evaluateOperator(operator: operator, userValue: userValue, ruleValue: ruleValue);
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

    // 6. Unify motorized vehicle and four wheeler flags (synonym normalization)
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

    // 7. Unify annualIncome and annualFamilyIncome
    if (!normalized.containsKey('annualFamilyIncome') && normalized.containsKey('annualIncome')) {
      normalized['annualFamilyIncome'] = normalized['annualIncome'];
    }
    if (!normalized.containsKey('annualIncome') && normalized.containsKey('annualFamilyIncome')) {
      normalized['annualIncome'] = normalized['annualFamilyIncome'];
    }

    // 8. Synthesize demographic & occupational flags from survey answers
    final occ = normalized['occupation']?.toString().toLowerCase() ?? '';
    if (!normalized.containsKey('isFarmer')) {
      if (occ == 'farmer' || normalized['ownsCultivableLand'] == true) {
        normalized['isFarmer'] = true;
      }
    }
    if (!normalized.containsKey('isStudent') && occ == 'student') {
      normalized['isStudent'] = true;
    }
    if (!normalized.containsKey('isStreetVendor') && occ == 'street_vendor') {
      normalized['isStreetVendor'] = true;
    }
    if (!normalized.containsKey('isConstructionWorker') && occ == 'construction_worker') {
      normalized['isConstructionWorker'] = true;
    }
    if (!normalized.containsKey('isUnorganizedWorker')) {
      if (['unorganized_worker', 'construction_worker', 'street_vendor', 'agricultural_worker', 'artisan_craftsperson'].contains(occ)) {
        normalized['isUnorganizedWorker'] = true;
      }
    }

    // Government employment exclusion check
    if (!normalized.containsKey('isGovtEmployee') && occ.isNotEmpty) {
      normalized['isGovtEmployee'] = ['government_employee', 'salaried_govt'].contains(occ);
    }

    // Income tax payer exclusion check
    if (!normalized.containsKey('isTaxpayer')) {
      final inc = _parseNum(normalized['annualFamilyIncome'] ?? normalized['annualIncome']);
      if (inc != null && inc > 0) {
        normalized['isTaxpayer'] = inc > 300000;
      }
    }

    // Gender & Age derived flags
    final gender = normalized['gender']?.toString().toLowerCase() ?? '';
    if (!normalized.containsKey('isWoman') && gender == 'female') {
      normalized['isWoman'] = true;
    }

    final age = _parseNum(normalized['age']);
    if (age != null) {
      if (!normalized.containsKey('isSeniorCitizen')) {
        normalized['isSeniorCitizen'] = age >= 60;
      }
      if (!normalized.containsKey('isYouth')) {
        normalized['isYouth'] = age >= 18 && age <= 35;
      }
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
