import 'dart:async';

import 'package:sahay/models/scheme_model.dart';

class SchemeDataService {
  const SchemeDataService();

  // All schemes
  Future<List<SchemeModel>> getAllSchemes() async {
    return List<SchemeModel>.unmodifiable(_curatedSchemes);
  }

  // By category
  Future<List<SchemeModel>> getSchemesByCategory(String category) async {
    final cleanCategory = category.trim().toLowerCase();
    return _curatedSchemes
        .where((scheme) => scheme.category.toLowerCase() == cleanCategory)
        .toList();
  }

  // By ID
  Future<SchemeModel?> getSchemeById(String schemeId) async {
    try {
      return _curatedSchemes.firstWhere(
        (scheme) => scheme.schemeId == schemeId,
      );
    } catch (_) {
      return null;
    }
  }

  // Search
  Future<List<SchemeModel>> searchSchemes(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return getAllSchemes();
    }

    return _curatedSchemes.where((scheme) {
      final matchesEnglishName =
          scheme.name.toLowerCase().contains(cleanQuery);
      final matchesHindiName =
          scheme.nameHindi?.toLowerCase().contains(cleanQuery) ?? false;
      final matchesDescription =
          scheme.description.toLowerCase().contains(cleanQuery);
      final matchesHindiDescription =
          scheme.descriptionHindi?.toLowerCase().contains(cleanQuery) ?? false;
      final matchesCategory =
          scheme.category.toLowerCase().contains(cleanQuery);
      final matchesMinistry =
          scheme.ministry.toLowerCase().contains(cleanQuery);
      final matchesBenefits =
          scheme.benefits.toLowerCase().contains(cleanQuery);
      final matchesDocuments = scheme.requiredDocuments.any(
        (doc) => doc.toLowerCase().contains(cleanQuery),
      );

      return matchesEnglishName ||
          matchesHindiName ||
          matchesDescription ||
          matchesHindiDescription ||
          matchesCategory ||
          matchesMinistry ||
          matchesBenefits ||
          matchesDocuments;
    }).toList();
  }

  // Schemes
  static final List<SchemeModel> _curatedSchemes = [
    // PM-KISAN
    SchemeModel(
      schemeId: 'pm-kisan',
      name: 'PM Kisan Samman Nidhi',
      nameHindi: 'प्रधानमंत्री किसान सम्मान निधि',
      description:
          'A central sector welfare scheme with 100% funding from the Government of India, providing income support to all landholding farmer families across the country to supplement their financial needs for agricultural inputs and domestic obligations.',
      descriptionHindi:
          'भारत सरकार द्वारा शत-प्रतिशत वित्त पोषित योजना, जिसके तहत सभी पात्र भूमिधारक किसान परिवारों को कृषि आदानों और घरेलू आवश्यकताओं के लिए प्रति वर्ष ₹6,000 की वित्तीय सहायता तीन समान किस्तों में प्रदान की जाती है।',
      category: 'agriculture',
      ministry: 'Ministry of Agriculture & Farmers Welfare',
      governmentLevel: GovernmentLevel.central,
      applicableStates: const [],
      benefits:
          'Financial benefit of ₹6,000 per year per family payable in three equal four-monthly installments of ₹2,000 directly deposited into Aadhaar-seeded bank accounts.',
      benefitsHindi:
          'प्रत्येक पात्र परिवार को प्रति वर्ष ₹6,000 का वित्तीय लाभ, जो ₹2,000 की तीन समान किस्तों में सीधे आधार-सीडेड बैंक खाते में भेजा जाता है।',
      eligibilityRules: const [
        EligibilityRule(
          field: 'occupation',
          operator: EligibilityOperator.equals,
          value: 'farmer',
          isMandatory: true,
          description: 'Applicant must be an active landholding cultivator/farmer.',
        ),
        EligibilityRule(
          field: 'ownsCultivableLand',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must hold registered cultivable agricultural land (per June 2019 Cabinet reform, all land sizes qualify; 2ha limit was abolished).',
        ),
        EligibilityRule(
          field: 'hasBankAccount',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must possess an active bank account linked with Aadhaar for Direct Benefit Transfer (DBT).',
        ),
        EligibilityRule(
          field: 'isIncomeTaxPayer',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Exclusion criterion: Neither applicant nor any family member must have paid income tax in the last assessment year.',
        ),
        EligibilityRule(
          field: 'isGovernmentEmployee',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Exclusion criterion: Serving or retired officers/employees of Central/State government/PSUs are excluded (Multi-Tasking Staff / Group D exempted).',
        ),
        EligibilityRule(
          field: 'isInstitutionalLandholder',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: false,
          description: 'Exclusion criterion: Institutional landholders are not eligible.',
        ),
      ],
      requiredDocuments: const [
        'Aadhaar Card of the applicant farmer',
        'Land Ownership Records (Khasra/Khatauni/Record of Rights - RoR)',
        'Active Bank Account Passbook (Aadhaar-seeded)',
        'Citizenship / Domicile Certificate',
      ],
      applicationProcess:
          'Farmers can register online through the PM-KISAN portal under the "Farmer Corner" > "New Farmer Registration" section, or visit the nearest Common Service Centre (CSC) or local Agriculture Nodal Officer with land records.',
      applicationUrl: 'https://pmkisan.gov.in/RegistrationFormNew.aspx',
      officialSourceUrl: 'https://www.myscheme.gov.in/schemes/pm-kisan',
      sourceName: 'myScheme & Ministry of Agriculture & Farmers Welfare',
      sourceType: SchemeSourceType.curated,
      verificationStatus: VerificationStatus.verified,
      status: SchemeStatus.active,
      lastVerified: DateTime(2026, 10, 20),
      isPopular: true,
      popularityRank: 1,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2026, 10, 20),
    ),

    // Ayushman Bharat
    SchemeModel(
      schemeId: 'pm-jay',
      name: 'Ayushman Bharat - Pradhan Mantri Jan Arogya Yojana (PM-JAY)',
      nameHindi: 'आयुष्मान भारत - प्रधानमंत्री जन आरोग्य योजना',
      description:
          'The flagship National Health Protection Scheme providing a financial health cover of ₹5 lakh per family per year for secondary and tertiary care hospitalization across public and empaneled private hospitals nationwide.',
      descriptionHindi:
          'देश भर के सरकारी और पैनलबद्ध निजी अस्पतालों में माध्यमिक और तृतीयक स्तर के कैशलेस इलाज हेतु प्रति वर्ष प्रति परिवार ₹5 लाख तक का स्वास्थ्य सुरक्षा कवच प्रदान करने वाली राष्ट्रीय योजना।',
      category: 'healthcare',
      ministry: 'Ministry of Health and Family Welfare',
      governmentLevel: GovernmentLevel.central,
      applicableStates: const [],
      benefits:
          'Cashless and paperless hospitalization coverage of up to ₹5,00,000 per family per year covering pre-existing conditions, diagnostic tests, treatments, ICU, and medicines with no capping on family size.',
      benefitsHindi:
          'बिना किसी पारिवारिक आकार सीमा के, पहले से मौजूद बीमारियों, जांच, दवाओं और गंभीर उपचार सहित प्रति परिवार प्रति वर्ष ₹5,00,000 तक का कैशलेस इलाज।',
      eligibilityRules: const [
        EligibilityRule(
          field: 'hasPriorityRationCard',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Household must be identified in SECC 2011 deprivation lists, hold an Antyodaya Anna Yojana (AAY) / BPL / Priority Ration Card under NFSA, or qualify under Ayushman Vay Vandana (Seniors 70+).',
        ),
        EligibilityRule(
          field: 'hasAadhaarOrIdProof',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must possess valid Aadhaar Card or authorized government photo identity proof for e-KYC.',
        ),
      ],
      requiredDocuments: const [
        'Aadhaar Card or Government Photo Identity Proof',
        'Ration Card / NFSA Card / SECC Household Family ID',
        'Income Certificate or BPL Card issued by competent authority',
        'Family Composition Document / Samagra ID (if applicable)',
      ],
      applicationProcess:
          'Beneficiaries can verify their inclusion on the PM-JAY Beneficiary Portal (beneficiary.nha.gov.in) or visit any empaneled hospital / CSC / Ayushman Mitra kiosk with Aadhaar and Ration Card to generate an Ayushman Card (Golden Card).',
      applicationUrl: 'https://beneficiary.nha.gov.in/',
      officialSourceUrl: 'https://www.myscheme.gov.in/schemes/ab-pmjay',
      sourceName: 'myScheme & National Health Authority (NHA)',
      sourceType: SchemeSourceType.curated,
      verificationStatus: VerificationStatus.verified,
      status: SchemeStatus.active,
      lastVerified: DateTime(2026, 10, 22),
      isPopular: true,
      popularityRank: 2,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2026, 10, 22),
    ),

    // PM Awas Yojana
    SchemeModel(
      schemeId: 'pmay-g',
      name: 'Pradhan Mantri Awas Yojana - Gramin (PMAY-G)',
      nameHindi: 'प्रधानमंत्री आवास योजना - ग्रामीण',
      description:
          'Flagship rural housing scheme by the Ministry of Rural Development aimed at providing a pucca house with basic amenities including piped water, sanitation, and electricity to all houseless rural families and those living in kutcha or dilapidated structures.',
      descriptionHindi:
          'ग्रामीण विकास मंत्रालय की प्रमुख आवास योजना, जिसका उद्देश्य ग्रामीण क्षेत्रों में बेघर परिवारों तथा कच्चे व जीर्ण-शीर्ण मकानों में रहने वाले लोगों को सभी बुनियादी सुविधाओं से युक्त पक्का मकान उपलब्ध कराना है।',
      category: 'housing',
      ministry: 'Ministry of Rural Development',
      governmentLevel: GovernmentLevel.central,
      applicableStates: const [],
      benefits:
          'Financial grant of ₹1,20,000 in plain areas and ₹1,30,000 in hilly/difficult/Himalayan states. Additionally, ₹12,000 assistance for toilet construction under Swachh Bharat Mission (Gramin) and 90-95 person-days of unskilled labor support under MGNREGA.',
      benefitsHindi:
          'मैदानी क्षेत्रों में ₹1.20 लाख और पहाड़ी/दुर्गम राज्यों में ₹1.30 लाख का प्रत्यक्ष अनुदान। साथ ही स्वच्छ भारत मिशन से शौचालय हेतु ₹12,000 और मनरेगा के तहत 90-95 दिनों की मजदूरी।',
      eligibilityRules: const [
        EligibilityRule(
          field: 'residenceType',
          operator: EligibilityOperator.equals,
          value: 'rural',
          isMandatory: true,
          description: 'Applicant must reside in a notified rural area.',
        ),
        EligibilityRule(
          field: 'hasHouse',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Applicant family must not own a pucca (concrete/permanent) house anywhere in India, and live in zero, one, or two-room kutcha dwelling.',
        ),
        EligibilityRule(
          field: 'hasBankAccount',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must have an active individual Aadhaar-linked bank account for installment disbursements.',
        ),
        EligibilityRule(
          field: 'hasMotorizedVehicle',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Exclusion criterion: Household must not own a motorized 2/3/4-wheeler, mechanized fishing boat, or heavy farm machinery.',
        ),
        EligibilityRule(
          field: 'isGovernmentEmployee',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Exclusion criterion: Household must not have any member as a regular government employee.',
        ),
      ],
      requiredDocuments: const [
        'Aadhaar Card of all adult family members',
        'BPL Ration Card / SECC Data Consent / Awaas+ Verification Slip',
        'Land Records / Patta Certificate or valid site ownership document',
        'Aadhaar-seeded Bank Account Passbook with IFSC',
        'Self-declaration / Affidavit confirming no pucca house ownership',
        'MGNREGA Job Card (for unskilled labor wage component)',
      ],
      applicationProcess:
          'Beneficiaries are identified and prioritized using the SECC 2011 and Awaas+ survey lists validated by the local Gram Sabha. Citizens can register claims through their Gram Panchayat or Block Development Officer (BDO).',
      applicationUrl: 'https://pmayg.nic.in/netiway/home.aspx',
      officialSourceUrl: 'https://www.myscheme.gov.in/schemes/pmay-g',
      sourceName: 'myScheme & Ministry of Rural Development',
      sourceType: SchemeSourceType.curated,
      verificationStatus: VerificationStatus.verified,
      status: SchemeStatus.active,
      lastVerified: DateTime(2026, 10, 18),
      isPopular: true,
      popularityRank: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2026, 10, 18),
    ),

    // Ujjwala Yojana
    SchemeModel(
      schemeId: 'ujjwala-2',
      name: 'Pradhan Mantri Ujjwala Yojana 2.0',
      nameHindi: 'प्रधानमंत्री उज्ज्वला योजना २.०',
      description:
          'Social welfare initiative providing deposit-free LPG connections to poor and vulnerable women from households without an existing LPG connection, promoting clean cooking fuel and mitigating respiratory health hazards.',
      descriptionHindi:
          'गरीब और वंचित परिवारों की वयस्क महिलाओं को बिना किसी जमा राशि के नया एलपीजी कनेक्शन, पहला भरा हुआ गैस सिलेंडर और चूल्हा निशुल्क प्रदान करने की कल्याणकारी योजना।',
      category: 'women_welfare',
      ministry: 'Ministry of Petroleum and Natural Gas',
      governmentLevel: GovernmentLevel.central,
      applicableStates: const [],
      benefits:
          'Complete deposit-free LPG connection including cylinder deposit waiver, pressure regulator, safety rubber hose, domestic gas consumer card (DGCC), free first 14.2 kg LPG refill, and a free 2-burner gas stove (hotplate).',
      benefitsHindi:
          'सिलेंडर सुरक्षा शुल्क और रेगुलेटर शुल्क की पूरी छूट, पहला 14.2 किग्रा भरा हुआ सिलेंडर मुफ्त, और 2 बर्नर वाला गैस चूल्हा निशुल्क।',
      eligibilityRules: const [
        EligibilityRule(
          field: 'gender',
          operator: EligibilityOperator.equals,
          value: 'female',
          isMandatory: true,
          description: 'Applicant must be an adult female (woman of the household).',
        ),
        EligibilityRule(
          field: 'age',
          operator: EligibilityOperator.greaterThanOrEqual,
          value: 18,
          isMandatory: true,
          description: 'Applicant must be at least 18 years of age.',
        ),
        EligibilityRule(
          field: 'existingLPG',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'No existing LPG connection must be registered in the name of any member of the household.',
        ),
        EligibilityRule(
          field: 'isVulnerableCategory',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Household must belong to an eligible vulnerable group (SC/ST, PMAY beneficiary, Antyodaya/BPL cardholder, Forest dweller, MBC, Tea garden tribes, or poor household submitting the 14-point declaration).',
        ),
        EligibilityRule(
          field: 'hasBankAccount',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must have a functional bank account in the applicant\'s name linked with Aadhaar.',
        ),
      ],
      requiredDocuments: const [
        'Aadhaar Card of the female applicant and adult family members',
        'Ration Card issued by State Government / Family Composition certificate',
        'Bank Passbook showing Account Number and IFSC',
        'Supplementary 14-Point Declaration / Self-declaration of no prior LPG connection',
      ],
      applicationProcess:
          'Apply online via pmuy.gov.in or download the application form and submit it in person to any authorized local LPG distributor (Indane, BharatGas, or HP Gas) with self-attested documents. Migrant workers can utilize self-declaration for address proof.',
      applicationUrl: 'https://www.pmuy.gov.in/ujjwala2.html',
      officialSourceUrl: 'https://www.myscheme.gov.in/schemes/pmuy',
      sourceName: 'myScheme & Ministry of Petroleum and Natural Gas',
      sourceType: SchemeSourceType.curated,
      verificationStatus: VerificationStatus.verified,
      status: SchemeStatus.active,
      lastVerified: DateTime(2026, 10, 24),
      isPopular: true,
      popularityRank: 4,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2026, 10, 24),
    ),

    // PM Scholarship
    SchemeModel(
      schemeId: 'pm-scholarship',
      name: 'Prime Minister\'s Scholarship Scheme (PMSS)',
      nameHindi: 'प्रधानमंत्री छात्रवृत्ति योजना',
      description:
          'Administered under the Department of Ex-Servicemen Welfare to encourage higher professional and technical education (Engineering, Medical, MBA, MCA, Architecture) for dependent wards and widows of ex-servicemen, ex-coast guard, and armed forces personnel.',
      descriptionHindi:
          'भूतपूर्व सैनिकों, भूतपूर्व तटरक्षक कर्मियों और रक्षा बलों के आश्रित बच्चों एवं विधवाओं को व्यावसायिक एवं तकनीकी उच्च शिक्षा में सहायता देने हेतु रक्षा मंत्रालय की प्रमुख छात्रवृत्ति योजना।',
      category: 'education',
      ministry: 'Ministry of Defence',
      governmentLevel: GovernmentLevel.central,
      applicableStates: const [],
      benefits:
          'Monthly scholarship grant of ₹2,500 for male students (₹30,000 per year) and ₹3,000 for female students (₹36,000 per year) disbursed annually for the sanctioned duration of the degree course.',
      benefitsHindi:
          'डिग्री पाठ्यक्रम की अवधि के लिए छात्रवृत्ति: बालकों को ₹2,500 प्रति माह (₹30,000 वार्षिक) और बालिकाओं को ₹3,000 प्रति माह (₹36,000 वार्षिक)।',
      eligibilityRules: const [
        EligibilityRule(
          field: 'isDependentOfExServiceman',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Applicant must be a dependent ward (son/daughter) or unmarried widow of an Ex-Serviceman or Ex-Coast Guard personnel (ESM themselves are not eligible).',
        ),
        EligibilityRule(
          field: 'educationLevel',
          operator: EligibilityOperator.inList,
          value: ['graduate', 'postGraduate'],
          isMandatory: true,
          description: 'Must be pursuing a full-time recognized professional or technical degree program (Graduation or Post-Graduation).',
        ),
        EligibilityRule(
          field: 'isProfessionalCourse',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must be enrolled in an approved technical or professional degree course (e.g. Engineering, MBBS, MBA, MCA, Pharmacy). General academic BA/BSc/BCom degrees are excluded.',
        ),
        EligibilityRule(
          field: 'meqMarksPercentage',
          operator: EligibilityOperator.greaterThanOrEqual,
          value: 60.0,
          isMandatory: true,
          description: 'Candidate must have scored at least 60% marks in the Minimum Entry Qualification marksheet (Class 12 / Diploma / Degree).',
        ),
        EligibilityRule(
          field: 'age',
          operator: EligibilityOperator.lessThanOrEqual,
          value: 30,
          isMandatory: true,
          description: 'Candidate must be aged 30 years or below at the time of admission.',
        ),
        EligibilityRule(
          field: 'hasBankAccount',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must have an active individual bank account linked with Aadhaar and mapped for DBT.',
        ),
      ],
      requiredDocuments: const [
        'Aadhaar Card of the student applicant',
        'Ex-Servicemen / Ex-Coast Guard Certificate (Discharge Book / PPO Copy)',
        'Bonafide Certificate / Admission confirmation from College / University',
        'Minimum Entry Qualification Marksheet (Class 12 / Diploma / Degree) showing minimum 60% marks',
        'Bank Passbook / Cancelled Cheque showing Account Number and IFSC',
      ],
      applicationProcess:
          'Applications must be submitted online through the Kendriya Sainik Board (KSB) portal (ksb.gov.in) or National Scholarship Portal (NSP) during the annual intake window, followed by digital verification by the concerned Zila Sainik Board.',
      applicationUrl: 'https://ksb.gov.in/how-to-apply-pmss.htm',
      officialSourceUrl: 'https://www.myscheme.gov.in/schemes/pmss',
      sourceName: 'myScheme & Kendriya Sainik Board',
      sourceType: SchemeSourceType.curated,
      verificationStatus: VerificationStatus.verified,
      status: SchemeStatus.active,
      lastVerified: DateTime(2026, 10, 12),
      isPopular: false,
      popularityRank: 5,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2026, 10, 12),
    ),

    // Ladli Behna
    SchemeModel(
      schemeId: 'ladli-behna-mp',
      name: 'Mukhyamantri Ladli Behna Yojana',
      nameHindi: 'मुख्यमंत्री लाड़ली बहना योजना',
      description:
          'A landmark state government welfare program by the Government of Madhya Pradesh to enhance women\'s economic self-reliance, improve nutritional health of families, and empower women in household economic decision making.',
      descriptionHindi:
          'मध्य प्रदेश शासन की युगांतरकारी योजना, जिसका उद्देश्य राज्य की महिलाओं के आर्थिक स्वावलंबन को सुदृढ़ करना, उनके स्वास्थ्य व पोषण स्तर में सुधार लाना तथा पारिवारिक निर्णयों में उनकी भागीदारी बढ़ाना है।',
      category: 'women_welfare',
      ministry: 'Department of Women & Child Development, Government of Madhya Pradesh',
      governmentLevel: GovernmentLevel.state,
      applicableStates: const ['Madhya Pradesh'],
      benefits:
          'Direct financial assistance of ₹1,250 per month (totaling ₹15,000 annually) deposited on the 10th of every month directly into the beneficiary woman\'s individual Aadhaar-linked and DBT-enabled bank account.',
      benefitsHindi:
          'प्रति माह ₹1,250 (वार्षिक ₹15,000) की नियमित आर्थिक सहायता, जो प्रत्येक माह की 10 तारीख को सीधे महिला के आधार-लिंक्ड और डीबीटी-सक्षम बैंक खाते में भेजी जाती है।',
      eligibilityRules: const [
        EligibilityRule(
          field: 'gender',
          operator: EligibilityOperator.equals,
          value: 'female',
          isMandatory: true,
          description: 'Applicant must be female.',
        ),
        EligibilityRule(
          field: 'state',
          operator: EligibilityOperator.equals,
          value: 'Madhya Pradesh',
          isMandatory: true,
          description: 'Applicant must be a bona fide resident of Madhya Pradesh with an active Samagra ID.',
        ),
        EligibilityRule(
          field: 'maritalStatus',
          operator: EligibilityOperator.inList,
          value: ['married', 'widowed', 'divorced'],
          isMandatory: true,
          description: 'Applicant must be a married, widowed, or divorced woman (unmarried women are strictly excluded under scheme guidelines).',
        ),
        EligibilityRule(
          field: 'age',
          operator: EligibilityOperator.greaterThanOrEqual,
          value: 21,
          isMandatory: true,
          description: 'Applicant must be at least 21 years of age as of 1st January of the calendar year.',
        ),
        EligibilityRule(
          field: 'age',
          operator: EligibilityOperator.lessThanOrEqual,
          value: 60,
          isMandatory: true,
          description: 'Applicant must not have completed 60 years of age.',
        ),
        EligibilityRule(
          field: 'annualIncome',
          operator: EligibilityOperator.lessThanOrEqual,
          value: 250000,
          isMandatory: true,
          description: 'Combined annual family income must not exceed ₹2.5 lakh.',
        ),
        EligibilityRule(
          field: 'hasBankAccount',
          operator: EligibilityOperator.isTrue,
          value: true,
          isMandatory: true,
          description: 'Must have an active individual bank account linked with Aadhaar and DBT enabled.',
        ),
        EligibilityRule(
          field: 'isIncomeTaxPayer',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Exclusion criterion: No member of the applicant household must be an income tax payer.',
        ),
        EligibilityRule(
          field: 'hasFourWheeler',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Exclusion criterion: Family must not own a four-wheeler motor vehicle (excluding tractor).',
        ),
        EligibilityRule(
          field: 'isGovernmentEmployee',
          operator: EligibilityOperator.isFalse,
          value: false,
          isMandatory: true,
          description: 'Exclusion criterion: No family member must be a regular/contractual government employee or pensioner.',
        ),
      ],
      requiredDocuments: const [
        'Samagra Family ID and Member ID (with e-KYC completed)',
        'Aadhaar Card of the applicant woman',
        'Individual Bank Account Passbook (Aadhaar linked and DBT active)',
        'Self-declaration of residency in Madhya Pradesh and income limit compliance',
      ],
      applicationProcess:
          'Applications are submitted during special facilitation camps organized at Gram Panchayat / Ward levels, or through designated MP Online kiosks and Common Service Centres. Biometric Aadhaar verification and Samagra e-KYC are validated on site.',
      applicationUrl: 'https://cmladlibehna.mp.gov.in/',
      officialSourceUrl: 'https://www.myscheme.gov.in/schemes/cmlby',
      sourceName: 'myScheme & Govt of Madhya Pradesh',
      sourceType: SchemeSourceType.curated,
      verificationStatus: VerificationStatus.verified,
      status: SchemeStatus.active,
      lastVerified: DateTime(2026, 10, 25),
      isPopular: true,
      popularityRank: 6,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2026, 10, 25),
    ),
  ];
}
