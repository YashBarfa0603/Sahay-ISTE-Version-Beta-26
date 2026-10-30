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
            'laborer',
            'salaried',
            'selfEmployed',
            'student',
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
      ];

  // Next question
  QuestionItem? getNextQuestion(
    Map<String, dynamic> currentAnswers,
    List<SchemeModel> schemes,
  ) {
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
}
