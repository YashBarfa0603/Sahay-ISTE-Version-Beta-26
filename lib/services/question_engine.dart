import 'package:sahay/models/eligibility_model.dart';
import 'package:sahay/models/scheme_model.dart';
import 'package:sahay/services/eligibility_engine.dart';

class QuestionItem {
  final String id;
  final String type; // 'single_choice', 'number', 'text', 'boolean'
  final List<String>? options;
  final bool isConditional;
  final String? dependsOn;
  final dynamic dependsOnValue;
  final String? label;
  final String? labelHindi;
  final String? helperText;
  final String? unit;

  const QuestionItem({
    required this.id,
    required this.type,
    this.options,
    this.isConditional = false,
    this.dependsOn,
    this.dependsOnValue,
    this.label,
    this.labelHindi,
    this.helperText,
    this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'options': options,
      'isConditional': isConditional,
      'dependsOn': dependsOn,
      'dependsOnValue': dependsOnValue,
      'label': label,
      'labelHindi': labelHindi,
      'helperText': helperText,
      'unit': unit,
    };
  }

  factory QuestionItem.fromMap(Map<String, dynamic> map) {
    return QuestionItem(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'text',
      options: (map['options'] as List?)?.map((e) => e.toString()).toList(),
      isConditional: map['isConditional'] as bool? ?? false,
      dependsOn: map['dependsOn'] as String?,
      dependsOnValue: map['dependsOnValue'],
      label: map['label'] as String?,
      labelHindi: map['labelHindi'] as String?,
      helperText: map['helperText'] as String?,
      unit: map['unit'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AssessmentContradiction {
  final String conflictId;
  final List<String> conflictingFields;
  final String messageEn;
  final String messageHi;
  final String remedyEn;
  final String remedyHi;
  final bool isBlocking;

  const AssessmentContradiction({
    required this.conflictId,
    required this.conflictingFields,
    required this.messageEn,
    required this.messageHi,
    required this.remedyEn,
    required this.remedyHi,
    this.isBlocking = true,
  });
}

class QuestionEngine {
  final EligibilityEngine _eligibilityEngine;

  const QuestionEngine({EligibilityEngine? eligibilityEngine})
      : _eligibilityEngine = eligibilityEngine ?? const EligibilityEngine();

  // States
  static const List<String> indianStatesAndUTs = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // Questions
  List<QuestionItem> get allQuestions => const [
        // 1. Gender
        QuestionItem(
          id: 'gender',
          type: 'single_choice',
          options: ['male', 'female', 'other'],
          label: 'What is your gender?',
          labelHindi: 'आपका लिंग क्या है?',
          helperText: 'Certain welfare schemes are exclusively tailored for women or specific groups.',
        ),

        // 2. Age
        QuestionItem(
          id: 'age',
          type: 'number',
          label: 'What is your age?',
          labelHindi: 'आपकी आयु कितनी है?',
          helperText: 'Schemes have strict minimum and maximum age criteria.',
          unit: 'years',
        ),

        // 3. State
        QuestionItem(
          id: 'state',
          type: 'single_choice',
          options: indianStatesAndUTs,
          label: 'Which State or Union Territory do you reside in?',
          labelHindi: 'आप किस राज्य या केंद्र शासित प्रदेश में रहते हैं?',
          helperText: 'Filters schemes applicable specifically to your state or central level.',
        ),

        // 4. Residence Type
        QuestionItem(
          id: 'residenceType',
          type: 'single_choice',
          options: ['rural', 'urban', 'semi_urban'],
          label: 'What type of area do you live in?',
          labelHindi: 'आप किस प्रकार के क्षेत्र में रहते हैं?',
          helperText: 'Differentiates rural development schemes from urban programs.',
        ),

        // 5. Caste / Social Category
        QuestionItem(
          id: 'casteCategory',
          type: 'single_choice',
          options: ['general', 'obc', 'sc', 'st'],
          label: 'What is your social / caste category?',
          labelHindi: 'आपका सामाजिक वर्ग / जाति क्या है?',
          helperText: 'Many affirmative welfare benefits are reserved for specific communities.',
        ),

        // 6. Annual Income
        QuestionItem(
          id: 'annualIncome',
          type: 'number',
          label: 'What is your total annual household income?',
          labelHindi: 'आपकी कुल वार्षिक पारिवारिक आय (₹ में) कितनी है?',
          helperText: 'Determines BPL, EWS, and low-income bracket eligibility thresholds.',
          unit: '₹ per year',
        ),

        // 7. Occupation
        QuestionItem(
          id: 'occupation',
          type: 'single_choice',
          options: [
            'farmer',
            'agricultural_worker',
            'unorganized_worker',
            'construction_worker',
            'street_vendor',
            'artisan_craftsperson',
            'student',
            'salaried_private',
            'government_employee',
            'self_employed_business',
            'homemaker',
            'unemployed',
            'retired',
          ],
          label: 'What is your primary occupation?',
          labelHindi: 'आपका मुख्य व्यवसाय क्या है?',
          helperText: 'Helps identify farmer support, unorganized worker, and student benefits.',
        ),

        // 8. Marital Status
        QuestionItem(
          id: 'maritalStatus',
          type: 'single_choice',
          options: ['unmarried', 'married', 'widowed', 'divorced'],
          label: 'What is your marital status?',
          labelHindi: 'आपकी वैवाहिक स्थिति क्या है?',
          helperText: 'Some pension, housing, and protection programs prioritize widows or single persons.',
        ),

        // 9. Disability
        QuestionItem(
          id: 'disability',
          type: 'boolean',
          label: 'Do you have a benchmark disability (40% or more)?',
          labelHindi: 'क्या आप दिव्यांग (40% या अधिक) हैं?',
          helperText: 'Enables access to Divyangjan welfare assistance and reserved quotas.',
        ),

        // 10. Land Ownership (conditional: farmer)
        QuestionItem(
          id: 'landOwnership',
          type: 'number',
          isConditional: true,
          dependsOn: 'occupation',
          dependsOnValue: 'farmer',
          label: 'How much cultivable agricultural land do you own?',
          labelHindi: 'आपके पास कितनी कृषि भूमि है (हेक्टेयर में)?',
          helperText: 'Small and marginal farmers owning up to 2 hectares qualify for PM-KISAN.',
          unit: 'hectares',
        ),

        // 11. Existing LPG (conditional: female)
        QuestionItem(
          id: 'existingLPG',
          type: 'boolean',
          isConditional: true,
          dependsOn: 'gender',
          dependsOnValue: 'female',
          label: 'Does your household already possess an active LPG connection?',
          labelHindi: 'क्या आपके घर में पहले से सक्रिय एलपीजी गैस कनेक्शन है?',
          helperText: 'Ujjwala Yojana 2.0 requires applicant households to have no prior gas connection.',
        ),

        // 12. Ex-Serviceman Status
        QuestionItem(
          id: 'isExServiceman',
          type: 'boolean',
          label: 'Are you or your guardian/spouse an ex-serviceman or ex-coast guard?',
          labelHindi: 'क्या आप या आपके माता-पिता/पति/पत्नी पूर्व सैनिक या तटरक्षक हैं?',
          helperText: 'Qualifies dependent wards and widows for PM Scholarship and defense welfare.',
        ),

        // 13. Education Level
        QuestionItem(
          id: 'educationLevel',
          type: 'single_choice',
          options: [
            'noFormalEducation',
            'primary',
            'secondary',
            'higherSecondary',
            'graduate',
            'postGraduate',
          ],
          label: 'What is your highest level of education enrolled or completed?',
          labelHindi: 'आपकी उच्चतम शिक्षा का स्तर क्या है?',
          helperText: 'Required to match scholarship programs and skill training schemes.',
        ),

        // 14. Number of Children
        QuestionItem(
          id: 'numberOfChildren',
          type: 'number',
          label: 'How many dependent children do you have?',
          labelHindi: 'आपके कितने आश्रित बच्चे हैं?',
          helperText: 'Used for family-welfare, maternity, and girl child educational schemes.',
        ),

        // 15. Has House
        QuestionItem(
          id: 'hasHouse',
          type: 'boolean',
          label: 'Do you or your family own a pucca (concrete/permanent) house?',
          labelHindi: 'क्या आपके या आपके परिवार के पास पक्का मकान है?',
          helperText: 'Pradhan Mantri Awas Yojana strictly requires candidates to be houseless or living in kutcha dwellings.',
        ),

        // 16. Has Bank Account
        QuestionItem(
          id: 'hasBankAccount',
          type: 'boolean',
          label: 'Do you have an active bank account linked with Aadhaar?',
          labelHindi: 'क्या आपके पास आधार से जुड़ा सक्रिय बैंक खाता है?',
          helperText: 'Necessary for direct benefit cash transfers (DBT) under almost all government schemes.',
        ),

        // 17. Income Tax Payer
        QuestionItem(
          id: 'isIncomeTaxPayer',
          type: 'boolean',
          label: 'Has any member of your household paid Income Tax in the last assessment year?',
          labelHindi: 'क्या आपके परिवार के किसी सदस्य ने पिछले वित्तीय वर्ष में आयकर का भुगतान किया है?',
          helperText: 'Statutory exclusion parameter under PM-KISAN, Ladli Behna, and PMAY-G schemes.',
        ),

        // 18. Government Employee Status
        QuestionItem(
          id: 'isGovernmentEmployee',
          type: 'boolean',
          label: 'Is any member of your household a regular government employee or pensioner?',
          labelHindi: 'क्या आपके परिवार का कोई सदस्य नियमित सरकारी कर्मचारी या पेंशनभोगी है?',
          helperText: 'Exclusion criterion for PM-KISAN, Ladli Behna, and PMAY-G (Group D/MTS staff exempted for PM-KISAN).',
        ),

        // 19. Priority / Antyodaya Ration Card
        QuestionItem(
          id: 'hasPriorityRationCard',
          type: 'boolean',
          label: 'Does your household hold an Antyodaya (AAY), BPL, or NFSA Priority Ration Card?',
          labelHindi: 'क्या आपके परिवार के पास अंत्योदय (AAY), बीपीएल या प्राथमिकता राशन कार्ड है?',
          helperText: 'Primary beneficiary entitlement record for Ayushman Bharat (PM-JAY) and Ujjwala 2.0.',
        ),

        // 20. Motorized Vehicle
        QuestionItem(
          id: 'hasMotorizedVehicle',
          type: 'boolean',
          label: 'Does your household own a motorized 2/3/4-wheeler or agricultural equipment?',
          labelHindi: 'क्या आपके परिवार के पास दो/तीन/चार पहिया वाहन या कृषि मशीनरी है?',
          helperText: 'Statutory exclusion parameter under PMAY-G rural housing guidelines.',
        ),

        // 21. Four Wheeler
        QuestionItem(
          id: 'hasFourWheeler',
          type: 'boolean',
          label: 'Does your family own a motorized four-wheeler (car/jeep, excluding tractor)?',
          labelHindi: 'क्या आपके परिवार के पास चार पहिया वाहन (कार/जीप, ट्रैक्टर को छोड़कर) है?',
          helperText: 'Statutory exclusion criterion for Mukhyamantri Ladli Behna Yojana.',
        ),

        // 22. Professional Degree Course (for PMSS)
        QuestionItem(
          id: 'isProfessionalCourse',
          type: 'boolean',
          isConditional: true,
          dependsOn: 'isExServiceman',
          dependsOnValue: true,
          label: 'Are you enrolled in an approved technical/professional degree (Engineering, Medical, MBA, MCA)?',
          labelHindi: 'क्या आप मान्यता प्राप्त व्यावसायिक/तकनीकी डिग्री (इंजीनियरिंग, मेडिकल, एमबीए) में नामांकित हैं?',
          helperText: 'PMSS exclusively covers approved professional courses. General BA/BSc/BCom are excluded.',
        ),

        // 23. MEQ Marks Percentage (for PMSS)
        QuestionItem(
          id: 'meqMarksPercentage',
          type: 'number',
          isConditional: true,
          dependsOn: 'isExServiceman',
          dependsOnValue: true,
          label: 'What was your percentage in the Minimum Entry Qualification marksheet (Class 12 / Diploma / Degree)?',
          labelHindi: 'न्यूनतम प्रवेश योग्यता परीक्षा (12वीं/डिप्लोमा) में आपके कितने प्रतिशत अंक हैं?',
          helperText: 'PMSS requires at least 60% aggregate marks in entry qualification.',
          unit: '%',
        ),
      ];

  // Contradiction Detection (Phase 5)
  List<AssessmentContradiction> detectContradictions(Map<String, dynamic> answers) {
    final contradictions = <AssessmentContradiction>[];

    final age = _parseNum(answers['age']);
    final occupation = answers['occupation']?.toString().toLowerCase();
    final maritalStatus = answers['maritalStatus']?.toString().toLowerCase();
    final isGovEmployee = answers['isGovernmentEmployee'];
    final income = _parseNum(answers['annualIncome']);
    final hasPriorityCard = answers['hasPriorityRationCard'] == true || answers['bplCard'] == true;
    final land = _parseNum(answers['landOwnership']);

    // 1. Age vs Occupation
    if (age != null && occupation != null) {
      if (age < 18 && (occupation == 'salaried_private' || occupation == 'government_employee' || occupation == 'retired')) {
        contradictions.add(
          const AssessmentContradiction(
            conflictId: 'age_minor_formal_employment',
            conflictingFields: ['age', 'occupation'],
            messageEn: 'Age is recorded as under 18, but occupation indicates formal employment or retirement.',
            messageHi: 'आपकी आयु 18 वर्ष से कम दर्ज है, लेकिन व्यवसाय औपचारिक रोजगार या सेवानिवृत्त चुना गया है।',
            remedyEn: 'Please verify your birth year/age or select Student / Other.',
            remedyHi: 'कृपया अपनी सही आयु या उपयुक्त व्यवसाय चुनें।',
            isBlocking: true,
          ),
        );
      }
      if (age > 65 && occupation == 'student') {
        contradictions.add(
          const AssessmentContradiction(
            conflictId: 'age_senior_student',
            conflictingFields: ['age', 'occupation'],
            messageEn: 'Age is recorded as over 65 with full-time student status.',
            messageHi: 'आपकी आयु 65 वर्ष से अधिक है और व्यवसाय छात्र चुना गया है।',
            remedyEn: 'Please verify if you are currently enrolled in a recognized degree or retired/senior citizen.',
            remedyHi: 'कृपया सत्यापित करें कि क्या आप नियमित छात्र हैं या सेवानिवृत्त/वरिष्ठ नागरिक।',
            isBlocking: false,
          ),
        );
      }
    }

    // 2. Age vs Marital Status
    if (age != null && maritalStatus != null) {
      if (age < 18 && (maritalStatus == 'married' || maritalStatus == 'widowed' || maritalStatus == 'divorced')) {
        contradictions.add(
          const AssessmentContradiction(
            conflictId: 'age_minor_marriage',
            conflictingFields: ['age', 'maritalStatus'],
            messageEn: 'Under statutory welfare guidelines, formal applicant profiles require age 18+ for married welfare benefits.',
            messageHi: 'कल्याणकारी योजनाओं के वैधानिक नियमों के तहत वैवाहिक योजनाओं के लिए न्यूनतम आयु 18 वर्ष आवश्यक है।',
            remedyEn: 'Please review your age or marital status answer.',
            remedyHi: 'कृपया अपनी आयु या वैवाहिक स्थिति की समीक्षा करें।',
            isBlocking: true,
          ),
        );
      }
    }

    // 3. Occupation vs Government Employee Exclusion
    if (occupation == 'government_employee' && isGovEmployee == false) {
      contradictions.add(
        const AssessmentContradiction(
          conflictId: 'occupation_gov_emp_mismatch',
          conflictingFields: ['occupation', 'isGovernmentEmployee'],
          messageEn: 'Occupation is selected as government employee, but household government employment status is marked No.',
          messageHi: 'व्यवसाय में सरकारी कर्मचारी चुना गया है, लेकिन परिवार में सरकारी कर्मचारी होने से मना किया गया है।',
          remedyEn: 'Please align your occupation with the government employee exclusion declaration.',
          remedyHi: 'कृपया अपने व्यवसाय और सरकारी कर्मचारी घोषणा का मिलान करें।',
          isBlocking: true,
        ),
      );
    }

    // 4. High Income vs Priority/BPL Card (NFSA/BPL threshold is under ₹2.5L-3.0L)
    if (income != null && income > 300000 && hasPriorityCard) {
      contradictions.add(
        AssessmentContradiction(
          conflictId: 'high_income_bpl_card',
          conflictingFields: const ['annualIncome', 'hasPriorityRationCard'],
          messageEn: 'Annual family income is entered as ₹${income.toStringAsFixed(0)}, which exceeds BPL/Priority Ration Card income thresholds.',
          messageHi: 'वार्षिक पारिवारिक आय ₹${income.toStringAsFixed(0)} दर्ज है, जो बीपीएल/प्राथमिकता राशन कार्ड सीमा से काफी अधिक है।',
          remedyEn: 'Please verify your annual family income or ration card category.',
          remedyHi: 'कृपया अपनी वार्षिक आय या राशन कार्ड श्रेणी की पुष्टि करें।',
          isBlocking: false,
        ),
      );
    }

    // 5. Land Ownership vs Non-Agricultural Student/Homemaker with large land
    if (land != null && land > 5.0 && (occupation == 'student')) {
      contradictions.add(
        const AssessmentContradiction(
          conflictId: 'student_large_landholding',
          conflictingFields: ['occupation', 'landOwnership'],
          messageEn: 'Student profile lists individual agricultural landholding over 5 hectares.',
          messageHi: 'छात्र प्रोफाइल में 5 हेक्टेयर से अधिक व्यक्तिगत कृषि भूमि दर्ज की गई है।',
          remedyEn: 'Please verify if the land is registered under household farmer head.',
          remedyHi: 'कृपया सत्यापित करें कि क्या भूमि परिवार के मुखिया किसान के नाम पर पंजीकृत है।',
          isBlocking: false,
        ),
      );
    }

    return contradictions;
  }

  // Next question
  QuestionItem? getNextQuestion(
    Map<String, dynamic> currentAnswers,
    List<SchemeModel> schemes,
  ) {
    // If a blocking contradiction is detected, halt questionnaire until resolved
    final blockingContradictions = detectContradictions(currentAnswers).where((c) => c.isBlocking);
    if (blockingContradictions.isNotEmpty) {
      return null;
    }

    // Active schemes
    final activeSchemes = schemes.where((scheme) {
      final evaluation = _eligibilityEngine.evaluateScheme(scheme, currentAnswers);
      return evaluation.result != EligibilityResult.doesNotQualify;
    }).toList();

    if (activeSchemes.isEmpty) {
      return null;
    }

    // Candidate questions
    final candidateQuestions = allQuestions.where((q) {
      if (currentAnswers.containsKey(q.id) && currentAnswers[q.id] != null) {
        return false;
      }
      return _isQuestionEligible(q, currentAnswers);
    }).toList();

    if (candidateQuestions.isEmpty) {
      return null;
    }

    // Elimination power
    final eliminationPowers = _calculateEliminationPower(
      currentAnswers,
      activeSchemes,
    );

    // Filter
    final impactfulQuestions = candidateQuestions.where((q) {
      final power = eliminationPowers[q.id] ?? 0;
      return power > 0;
    }).toList();

    if (impactfulQuestions.isEmpty) {
      return null;
    }

    // Sort
    impactfulQuestions.sort((a, b) {
      final powerA = eliminationPowers[a.id] ?? 0;
      final powerB = eliminationPowers[b.id] ?? 0;
      if (powerA != powerB) {
        return powerB.compareTo(powerA);
      }
      return allQuestions.indexOf(a).compareTo(allQuestions.indexOf(b));
    });

    return impactfulQuestions.first;
  }

  // Completion check
  bool hasEnoughAnswers(
    Map<String, dynamic> currentAnswers,
    List<SchemeModel> schemes,
  ) {
    return getNextQuestion(currentAnswers, schemes) == null;
  }

  // Calculate power
  Map<String, int> _calculateEliminationPower(
    Map<String, dynamic> currentAnswers,
    List<SchemeModel> schemes,
  ) {
    final powers = <String, int>{};

    // Filter schemes that are not already disqualified
    final activeSchemes = schemes.where((scheme) {
      final eval = _eligibilityEngine.evaluateScheme(scheme, currentAnswers);
      return eval.result != EligibilityResult.doesNotQualify;
    }).toList();

    for (final question in allQuestions) {
      // If already answered, power is 0
      if (currentAnswers.containsKey(question.id) &&
          currentAnswers[question.id] != null) {
        powers[question.id] = 0;
        continue;
      }

      // If conditional dependency not met, power is 0
      if (!_isQuestionEligible(question, currentAnswers)) {
        powers[question.id] = 0;
        continue;
      }

      int power = 0;
      for (final scheme in activeSchemes) {
        // Check if scheme has an eligibility rule targeting this question's field
        final hasRule = scheme.eligibilityRules.any(
          (rule) => rule.field == question.id,
        );

        // Also check if scheme is state-specific and question is 'state'
        final isStateSpecific = scheme.applicableStates.isNotEmpty &&
            question.id == 'state';

        if (hasRule || isStateSpecific) {
          power++;
        }
      }

      powers[question.id] = power;
    }

    return powers;
  }

  // Prerequisites
  bool _isQuestionEligible(
    QuestionItem question,
    Map<String, dynamic> currentAnswers,
  ) {
    if (!question.isConditional) {
      return true;
    }

    final dependsOn = question.dependsOn;
    if (dependsOn == null) {
      return true;
    }

    if (!currentAnswers.containsKey(dependsOn) ||
        currentAnswers[dependsOn] == null) {
      return false;
    }

    final parentValue = currentAnswers[dependsOn].toString().trim().toLowerCase();
    final requiredValue =
        question.dependsOnValue?.toString().trim().toLowerCase();

    final matchesDependency = parentValue == requiredValue;
    if (!matchesDependency) {
      return false;
    }

    // Extra condition for existingLPG: only if income is below limit (if income is present)
    if (question.id == 'existingLPG') {
      if (currentAnswers.containsKey('annualIncome') &&
          currentAnswers['annualIncome'] != null) {
        final income = num.tryParse(currentAnswers['annualIncome'].toString());
        if (income != null && income > 300000) {
          return false;
        }
      }
    }

    return true;
  }

  /// Maps a canonical eligibility rule field name to its corresponding QuestionItem identifier.
  String mapFieldToQuestionId(String field) {
    const aliasMap = {
      'annualFamilyIncome': 'annualIncome',
      'ownsCultivableLand': 'landOwnership',
      'isDependentOfExServiceman': 'isExServiceman',
      'hasAadhaarOrIdProof': 'hasBankAccount',
      'isVulnerableCategory': 'casteCategory',
      'ownsFourWheeler': 'hasFourWheeler',
      'hasMotorizedVehicle': 'hasMotorizedVehicle',
      'bplCard': 'hasPriorityRationCard',
    };
    return aliasMap[field] ?? field;
  }

  /// Retrieves the QuestionItem corresponding to a field or its canonical alias.
  QuestionItem? getQuestionForField(String field) {
    final targetId = mapFieldToQuestionId(field);
    for (final q in allQuestions) {
      if (q.id == targetId) return q;
    }
    return null;
  }

  /// Returns the exact list of missing questions required for a specific scheme
  /// that have not yet been answered in [existingAnswers].
  List<QuestionItem> getMissingQuestionsForScheme(
    SchemeModel scheme,
    Map<String, dynamic> existingAnswers, {
    EligibilityModel? assessment,
  }) {
    final eval = assessment ?? _eligibilityEngine.evaluateScheme(scheme, existingAnswers);
    final pendingConditions = eval.conditionResults
        .where((c) => c.status == ConditionStatus.pending && c.isMandatory)
        .toList();

    final missingQuestions = <QuestionItem>[];
    final seenIds = <String>{};

    for (final cond in pendingConditions) {
      final questionId = mapFieldToQuestionId(cond.field);

      // Skip if this question is already answered in existing answers
      if (existingAnswers.containsKey(questionId) &&
          existingAnswers[questionId] != null &&
          existingAnswers[questionId].toString().trim().isNotEmpty) {
        continue;
      }
      if (existingAnswers.containsKey(cond.field) &&
          existingAnswers[cond.field] != null &&
          existingAnswers[cond.field].toString().trim().isNotEmpty) {
        continue;
      }

      if (seenIds.contains(questionId)) continue;
      seenIds.add(questionId);

      final questionItem = getQuestionForField(cond.field) ??
          QuestionItem(
            id: cond.field,
            type: cond.expectedValue is bool
                ? 'boolean'
                : (cond.expectedValue is num ? 'number' : 'text'),
            label: cond.label ?? cond.field,
            labelHindi: cond.labelHindi,
            helperText: cond.requiredDescription,
          );

      missingQuestions.add(questionItem);
    }

    return missingQuestions;
  }

  num? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString().trim());
  }
}
