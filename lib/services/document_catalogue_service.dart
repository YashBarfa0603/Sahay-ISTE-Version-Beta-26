import 'package:sahay/models/document_info_model.dart';

/// Central repository of canonical government document types, specimen guides,
/// issuing authorities, verification checkpoints, and canonical fuzzy matching.
class DocumentCatalogueService {
  static final List<DocumentInfoModel> _allDocuments = [
    const DocumentInfoModel(
      documentType: 'aadhaar_card',
      displayName: 'Aadhaar Card',
      displayNameHindi: 'आधार कार्ड',
      category: 'Identity',
      categoryHindi: 'पहचान',
      description:
          '12-digit unique identity number issued by UIDAI with biometric and demographic details.',
      descriptionHindi:
          'यूआईडीएआई द्वारा जारी 12 अंकों की विशिष्ट पहचान संख्या जिसमें बायोमेट्रिक और जनसांख्यिकीय विवरण होते हैं।',
      purpose:
          'Primary proof of identity and Aadhaar-based Direct Benefit Transfer (DBT) verification.',
      purposeHindi:
          'पहचान का प्राथमिक प्रमाण और आधार आधारित प्रत्यक्ष लाभ अंतरण (DBT) सत्यापन।',
      provesInfo: [
        'Individual Identity',
        'Date of Birth',
        'Gender',
        'Residential Address',
      ],
      provesInfoHindi: [
        'व्यक्तिगत पहचान',
        'जन्म तिथि',
        'लिंग',
        'निवास का पता',
      ],
      issuingAuthority: 'Unique Identification Authority of India (UIDAI)',
      issuingAuthorityHindi: 'भारतीय विशिष्ट पहचान प्राधिकरण (UIDAI)',
      howToObtain: [
        'Visit any Aadhaar Seva Kendra, authorized Post Office, or Bank branch.',
        'Carry proof of identity (POI) and proof of address (POA).',
        'Complete biometric capture (fingerprints, iris scan, photo).',
        'Download digital e-Aadhaar immediately via uidai.gov.in or mAadhaar app.',
      ],
      howToObtainHindi: [
        'किसी भी आधार सेवा केंद्र, अधिकृत डाकघर या बैंक शाखा पर जाएं।',
        'पहचान का प्रमाण (POI) और पते का प्रमाण (POA) साथ ले जाएं।',
        'बायोमेट्रिक कैप्चर (उंगलियों के निशान, आईरिस स्कैन, फोटो) पूरा करें।',
        'uidai.gov.in या mAadhaar ऐप से तुरंत डिजिटल ई-आधार डाउनलोड करें।',
      ],
      importantChecks: [
        'Aadhaar number must be linked with active mobile number for OTP e-KYC.',
        'Name and spelling must match bank account passbook exactly.',
        'Address must match domicile state if applying for state-sponsored schemes.',
        'Masked Aadhaar is legally valid and protects your 12-digit number.',
      ],
      importantChecksHindi: [
        'ओटीपी ई-केवाईसी के लिए आधार सक्रिय मोबाइल नंबर से लिंक होना चाहिए।',
        'नाम और स्पेलिंग बैंक पासबुक से हूबहू मेल खानी चाहिए।',
        'राज्य योजनाओं के लिए पता अधिवास राज्य से मेल खाना चाहिए।',
        'मास्क्ड आधार कानूनी रूप से मान्य है और आपकी पहचान को सुरक्षित रखता है।',
      ],
      specimenTitle: 'SPECIMEN: Unique Identification Card',
      specimenDescription:
          'Government of India / भारत सरकार header, Ashoka Lion emblem, photograph on left, 12-digit masked/unmasked number at bottom, QR code on right.',
    ),
    const DocumentInfoModel(
      documentType: 'land_ownership_record',
      displayName: 'Land Ownership Record (Khatauni / RoR)',
      displayNameHindi: 'भूमि स्वामित्व अभिलेख (खतौनी / खसरा)',
      category: 'Land',
      categoryHindi: 'भूमि',
      description:
          'Official revenue record (Khatauni, Khasra, or Record of Rights - RoR) establishing cultivable landholding ownership.',
      descriptionHindi:
          'आधिकारिक राजस्व अभिलेख (खतौनी, खसरा या अधिकार अभिलेख - RoR) जो कृषि योग्य भूमि के स्वामित्व को प्रमाणित करता है।',
      purpose:
          'Mandatory for farmer welfare schemes like PM-KISAN to verify cultivable land ownership.',
      purposeHindi:
          'पीएम-किसान जैसी किसान योजनाओं में कृषि योग्य भूमि के स्वामित्व के सत्यापन हेतु अनिवार्य।',
      provesInfo: [
        'Cultivable Land Title & Ownership',
        'Khasra/Khatauni Parcel Numbers',
        'Village & Tehsil Jurisdiction',
        'Area in Hectares / Acres',
      ],
      provesInfoHindi: [
        'कृषि योग्य भूमि का स्वामित्व व अधिकार',
        'खसरा/खतौनी गाटा संख्या',
        'ग्राम एवं तहसील अधिकार क्षेत्र',
        'क्षेत्रफल (हेक्टेयर/एकड़)',
      ],
      issuingAuthority: 'State Revenue Department / Tehsildar / Patwari',
      issuingAuthorityHindi: 'राज्य राजस्व विभाग / तहसीलदार / पटवारी',
      howToObtain: [
        'Access your state Bhulekh web portal (e.g., UP Bhulekh, MP Bhulekh, Mahabhulekh).',
        'Enter District, Tehsil, Village name, and Khasra / Gata number.',
        'View and download digitally signed certified copy of Khatauni.',
        'Alternatively, visit Tehsil or CSC Jan Seva Kendra for certified physical copy.',
      ],
      howToObtainHindi: [
        'अपने राज्य के भूलेख वेब पोर्टल (जैसे यूपी भूलेख, एमपी भूलेख) पर जाएं।',
        'जिला, तहसील, गांव का नाम और खसरा/गाटा संख्या दर्ज करें।',
        'डिजिटल रूप से हस्ताक्षरित प्रमाणित खतौनी डाउनलोड करें।',
        'अथवा तहसील या सीएससी केंद्र से प्रमाणित प्रति प्राप्त करें।',
      ],
      importantChecks: [
        'Applicant farmer\'s name must appear as titleholder before cut-off date (01-02-2019 for PM-KISAN).',
        'Land must be cultivable agricultural land, not commercial or forest reserve.',
        'Ensure updated land record linking (e-KYC land seeding) is completed.',
      ],
      importantChecksHindi: [
        'कट-ऑफ तिथि (पीएम-किसान हेतु 01-02-2019) से पहले आवेदक का नाम दर्ज होना चाहिए।',
        'भूमि कृषि योग्य होनी चाहिए, वाणिज्यिक या वन भूमि नहीं।',
        'सुनिश्चित करें कि भूमि सीडिंग (Land Seeding) पोर्टल पर पूरी हो चुकी है।',
      ],
      specimenTitle: 'SPECIMEN: Revenue Record of Rights (RoR)',
      specimenDescription:
          'State Revenue Seal, Khata number, Khasra parcel numbers, Co-sharers list, Area in hectares, Patwari/Tehsildar digital signature.',
    ),
    const DocumentInfoModel(
      documentType: 'bank_passbook',
      displayName: 'Bank Account Passbook',
      displayNameHindi: 'बैंक पासबुक',
      category: 'Banking',
      categoryHindi: 'बैंकिंग',
      description:
          'First page of savings bank account passbook or cancelled cheque leaf showing IFSC and Account Number.',
      descriptionHindi:
          'बचत बैंक खाता पासबुक का प्रथम पृष्ठ या रद्द चेक जिसमें आईएफएससी और खाता संख्या स्पष्ट हो।',
      purpose:
          'Direct Benefit Transfer (DBT) disbursement into active NPCI-mapped bank account.',
      purposeHindi:
          'सक्रिय NPCI-मैप्ड बैंक खाते में प्रत्यक्ष लाभ अंतरण (DBT) भुगतान प्राप्त करने हेतु।',
      provesInfo: [
        'Bank Account Number & IFSC Code',
        'Account Holder Full Name',
        'Bank Branch & MICR Details',
      ],
      provesInfoHindi: [
        'बैंक खाता संख्या एवं IFSC कोड',
        'खाताधारक का पूरा नाम',
        'बैंक शाखा एवं एमआईसीआर विवरण',
      ],
      issuingAuthority: 'Scheduled Commercial Bank / Regional Rural Bank / Post Office Bank',
      issuingAuthorityHindi: 'अनुसूचित वाणिज्यिक बैंक / ग्रामीण बैंक / डाकघर बैंक',
      howToObtain: [
        'Open savings account at any bank branch or India Post Payments Bank (IPPB).',
        'Ensure Aadhaar seeding and NPCI DBT mapping is requested during account opening.',
        'Request updated physical passbook with bank stamp or download bank e-statement.',
      ],
      howToObtainHindi: [
        'किसी भी बैंक शाखा या इंडिया पोस्ट पेमेंट्स बैंक में बचत खाता खोलें।',
        'खाता खोलते समय आधार सीडिंग और एनपीसीआई डीबीटी मैपिंग का अनुरोध करें।',
        'बैंक मुहर सहित पासबुक प्राप्त करें या डिजिटल ई-स्टेटमेंट डाउनलोड करें।',
      ],
      importantChecks: [
        'Bank account MUST be seeded with Aadhaar and mapped with NPCI DBT gateway.',
        'Joint accounts where applicant is not primary holder are frequently rejected.',
        'Dormant or inoperative bank accounts cannot receive government subsidy funds.',
        'Branch IFSC must be current (verify after bank mergers).',
      ],
      importantChecksHindi: [
        'बैंक खाता अनिवार्य रूप से आधार से जुड़ा और NPCI DBT पर सक्रिय होना चाहिए।',
        'संयुक्त खाते जिनमें आवेदक मुख्य खाताधारक नहीं है, अस्वीकृत हो सकते हैं।',
        'निष्क्रिय (Dormant) बैंक खातों में सरकारी सब्सिडी जमा नहीं हो सकती।',
        'बैंक विलय के बाद नया IFSC कोड सत्यापित करें।',
      ],
      specimenTitle: 'SPECIMEN: Bank Account Passbook Front Page',
      specimenDescription:
          'Bank Logo, Branch Address, Account Holder Name, Account Number (11-16 digits), IFSC Code (11 alphanumeric characters), Official Bank Stamp.',
    ),
    const DocumentInfoModel(
      documentType: 'ration_card',
      displayName: 'Ration Card (NFSA / BPL / AAY)',
      displayNameHindi: 'राशन कार्ड (राष्ट्रीय खाद्य सुरक्षा / बीपीएल)',
      category: 'Income',
      categoryHindi: 'आय',
      description:
          'State Food & Civil Supplies Department document categorizing household under Antyodaya (AAY), Priority Household (PHH/BPL), or APL.',
      descriptionHindi:
          'खाद्य एवं नागरिक आपूर्ति विभाग द्वारा जारी कार्ड जो परिवार को अंत्योदय (AAY), प्राथमिकता परिवार (PHH/BPL) या APL में वर्गीकृत करता है।',
      purpose:
          'Proves economic deprivation, household roster, and eligibility for Ujjwala 2.0, PM-JAY, and subsidized foodgrains.',
      purposeHindi:
          'आर्थिक स्थिति, पारिवारिक सदस्यों की सूची तथा उज्ज्वला 2.0, पीएम-जय आदि के लिए पात्रता प्रमाणित करता है।',
      provesInfo: [
        'Family Roster & Head of Household',
        'Socio-Economic Category (BPL/AAY/PHH)',
        'Fair Price Shop (FPS) Allocation',
      ],
      provesInfoHindi: [
        'परिवार के सभी सदस्यों के नाम एवं मुखिया',
        'सामाजिक-आर्थिक श्रेणी (BPL/AAY/PHH)',
        'उचित मूल्य दुकान आवंटन',
      ],
      issuingAuthority: 'Department of Food, Civil Supplies & Consumer Affairs',
      issuingAuthorityHindi: 'खाद्य, नागरिक आपूर्ति एवं उपभोक्ता मामले विभाग',
      howToObtain: [
        'Apply online at state Food portal or via Common Service Centre (CSC).',
        'Submit family Aadhaar cards, income proof, and gas connection declaration.',
        'Local Food Inspector conducts verification before issuing digital Ration Card.',
      ],
      howToObtainHindi: [
        'राज्य खाद्य पोर्टल पर ऑनलाइन अथवा सीएससी केंद्र के माध्यम से आवेदन करें।',
        'परिवार के सभी आधार कार्ड, आय प्रमाण और गैस कनेक्शन घोषणा जमा करें।',
        'सत्यापन उपरांत डिजिटल राशन कार्ड जारी किया जाता है।',
      ],
      importantChecks: [
        'All adult members listed on Ration Card must have verified Aadhaar linked.',
        'For Ujjwala 2.0, adult woman applicant must be listed as family member/head.',
        'Migrant families can use 14-point declaration annexure if lacking local ration card.',
      ],
      importantChecksHindi: [
        'राशन कार्ड में दर्ज सभी वयस्क सदस्यों का आधार लिंक होना अनिवार्य है।',
        'उज्ज्वला 2.0 के लिए वयस्क महिला आवेदक का नाम परिवार में होना आवश्यक है।',
        'प्रवासी परिवार स्थानीय राशन कार्ड न होने पर 14-सूत्रीय स्व-घोषणा दे सकते हैं।',
      ],
      specimenTitle: 'SPECIMEN: National Food Security Card',
      specimenDescription:
          'State Emblem, Ration Card Number (10-12 digits), Head of Family Name, Category badge (AAY/PHH), Table of family members with age and relation.',
    ),
    const DocumentInfoModel(
      documentType: 'samagra_id',
      displayName: 'Samagra Family ID (MP SSSM ID)',
      displayNameHindi: 'समग्र परिवार आईडी (मध्य प्रदेश)',
      category: 'Identity',
      categoryHindi: 'पहचान',
      description:
          '8-digit Family ID and 9-digit Member ID issued by Madhya Pradesh Social Security Mission (SSSM).',
      descriptionHindi:
          'मध्य प्रदेश सामाजिक सुरक्षा मिशन (SSSM) द्वारा जारी 8-अंकीय परिवार आईडी और 9-अंकीय सदस्य आईडी।',
      purpose:
          'Mandatory prerequisite for all Madhya Pradesh state schemes including Ladli Behna Yojana.',
      purposeHindi:
          'लाडली बहना योजना सहित मध्य प्रदेश की सभी योजनाओं हेतु अनिवार्य प्राथमिक शर्त।',
      provesInfo: [
        'Madhya Pradesh State Domicile',
        'Family Composition & Member Relationship',
        'Samagra e-KYC Verification Status',
      ],
      provesInfoHindi: [
        'मध्य प्रदेश राज्य मूल निवास',
        'पारिवारिक संरचना एवं सदस्यों का संबंध',
        'समग्र ई-केवाईसी सत्यापन स्थिति',
      ],
      issuingAuthority: 'Madhya Pradesh Social Security Mission / Urban Local Body / Gram Panchayat',
      issuingAuthorityHindi: 'म.प्र. सामाजिक सुरक्षा मिशन / नगर पालिका / ग्राम पंचायत',
      howToObtain: [
        'Visit samagra.gov.in portal.',
        'Search by registered mobile number, Aadhaar number, or family head name.',
        'Download and print Samagra Family Card (परिवार समग्र पत्र).',
        'Complete biometric or OTP e-KYC on samagra portal to link Aadhaar.',
      ],
      howToObtainHindi: [
        'samagra.gov.in पोर्टल पर जाएं।',
        'पंजीकृत मोबाइल नंबर, आधार या मुखिया के नाम से खोजें।',
        'परिवार समग्र पत्र डाउनलोड एवं प्रिंट करें।',
        'आधार लिंक करने हेतु पोर्टल पर बायोमेट्रिक या ओटीपी ई-केवाईसी पूरा करें।',
      ],
      importantChecks: [
        'Samagra e-KYC MUST be completed before applying for Ladli Behna.',
        'Applicant\'s name, father/husband name, and DOB in Samagra must match Aadhaar exactly.',
        'Individual Samagra Member ID is 9 digits; Family ID is 8 digits.',
      ],
      importantChecksHindi: [
        'लाडली बहना आवेदन से पूर्व समग्र ई-केवाईसी पूर्ण होना अनिवार्य है।',
        'समग्र में नाम, पिता/पति का नाम और जन्मतिथि आधार से पूरी तरह मेल खानी चाहिए।',
        'व्यक्तिगत सदस्य आईडी 9 अंकों की और परिवार आईडी 8 अंकों की होती है।',
      ],
      specimenTitle: 'SPECIMEN: MP Samagra Social Security Card',
      specimenDescription:
          'Madhya Pradesh Shasan Logo, 8-Digit Family ID header, Table of family members with 9-digit Member IDs, Aadhaar Seeding checkmark column.',
    ),
    const DocumentInfoModel(
      documentType: 'income_certificate',
      displayName: 'Income Certificate',
      displayNameHindi: 'आय प्रमाण पत्र',
      category: 'Income',
      categoryHindi: 'आय',
      description:
          'Certificate issued by authorized Revenue Authority certifying annual gross family income.',
      descriptionHindi:
          'राजस्व अधिकारी (तहसीलदार/एसडीएम) द्वारा परिवार की वार्षिक सकल आय प्रमाणित करने वाला दस्तावेज।',
      purpose:
          'Establishes income ceiling criteria for scholarships, healthcare, housing, and social welfare schemes.',
      purposeHindi:
          'छात्रवृत्ति, स्वास्थ्य सेवा, आवास और कल्याणकारी योजनाओं में आय सीमा पात्रता स्थापित करता है।',
      provesInfo: [
        'Annual Family Income in Rupees',
        'Sources of Income (Agriculture/Labor/Trade)',
        'Certificate Validity Period',
      ],
      provesInfoHindi: [
        'रुपयों में वार्षिक पारिवारिक आय',
        'आय के स्रोत (कृषि/मजदूरी/व्यापार)',
        'प्रमाण पत्र की वैधता अवधि',
      ],
      issuingAuthority: 'Sub-Divisional Magistrate (SDM) / Tehsildar / Revenue Department',
      issuingAuthorityHindi: 'उप-विभागीय दंडाधिकारी (SDM) / तहसीलदार / राजस्व विभाग',
      howToObtain: [
        'Apply online at state e-District portal or local CSC Kendra.',
        'Submit self-declaration, salary slip or village patwari inquiry report.',
        'Obtain digitally signed certificate with QR code verification.',
      ],
      howToObtainHindi: [
        'राज्य ई-डिस्ट्रिक्ट पोर्टल या सीएससी केंद्र पर ऑनलाइन आवेदन करें।',
        'स्व-घोषणा पत्र, वेतन पर्ची या पटवारी रिपोर्ट संलग्न करें।',
        'क्यूआर कोड युक्त डिजिटल हस्ताक्षरित प्रमाण पत्र प्राप्त करें।',
      ],
      importantChecks: [
        'Must be within official validity period (typically 1 to 3 years depending on state).',
        'Ensure total income matches application declaration; contradictions trigger rejection.',
        'Must carry government digital barcode/QR code for instant verification.',
      ],
      importantChecksHindi: [
        'आधिकारिक वैधता अवधि (सामान्यतः 1 से 3 वर्ष) के भीतर होना चाहिए।',
        'घोषित आय आवेदन से मेल खानी चाहिए; विरोधाभास होने पर आवेदन निरस्त हो सकता है।',
        'डिजिटल बारकोड या क्यूआर कोड अवश्य होना चाहिए।',
      ],
      specimenTitle: 'SPECIMEN: Revenue Department Income Certificate',
      specimenDescription:
          'State Government Crest, Certificate Application Number, Certified Annual Income in words and figures, Digital Signature block with timestamp.',
    ),
    const DocumentInfoModel(
      documentType: 'domicile_certificate',
      displayName: 'Domicile / Residence Certificate',
      displayNameHindi: 'मूल निवास / अधिवास प्रमाण पत्र',
      category: 'Address',
      categoryHindi: 'पता',
      description:
          'Legal certificate issued by State Revenue Department proving permanent residency in that State.',
      descriptionHindi:
          'राज्य राजस्व विभाग द्वारा जारी कानूनी प्रमाण पत्र जो राज्य में स्थायी निवास प्रमाणित करता है।',
      purpose:
          'Mandatory for state-specific welfare benefits like MP Ladli Behna, state quota scholarships, and housing.',
      purposeHindi:
          'म.प्र. लाडली बहना, राज्य छात्रवृत्ति व आवास जैसी राज्य-विशिष्ट योजनाओं हेतु अनिवार्य।',
      provesInfo: [
        'Permanent State Residency',
        'Years of Continuous Residence',
        'District & Tehsil Jurisdiction',
      ],
      provesInfoHindi: [
        'राज्य में स्थायी निवास',
        'निरंतर निवास के वर्ष',
        'जिला एवं तहसील क्षेत्र',
      ],
      issuingAuthority: 'Tehsildar / Sub-Divisional Magistrate (SDM)',
      issuingAuthorityHindi: 'तहसीलदार / उप-विभागीय दंडाधिकारी (SDM)',
      howToObtain: [
        'Apply via state e-District / Lok Seva Kendra.',
        'Submit proof of residence (utility bills, voter ID, school records) proving multi-year domicile.',
        'Collect verified certificate from Tehsildar.',
      ],
      howToObtainHindi: [
        'राज्य ई-डिस्ट्रिक्ट अथवा लोक सेवा केंद्र से आवेदन करें।',
        'बिजली बिल, वोटर आईडी या स्कूल प्रमाण पत्र जैसे निवास प्रमाण संलग्न करें।',
        'सत्यापित प्रमाण पत्र प्राप्त करें।',
      ],
      importantChecks: [
        'Applicant must be a bonafide resident of the scheme-granting state.',
        'Ensure the certificate number matches state online verification records.',
      ],
      importantChecksHindi: [
        'आवेदक को संबंधित राज्य का वास्तविक मूल निवासी होना चाहिए।',
        'सुनिश्चित करें कि प्रमाण पत्र संख्या ऑनलाइन रिकॉर्ड से मेल खाती है।',
      ],
      specimenTitle: 'SPECIMEN: State Domicile Certificate',
      specimenDescription:
          'State Seal, Domicile Registration Number, Applicant photograph, Permanent Address, Tehsildar seal and digital signature.',
    ),
    const DocumentInfoModel(
      documentType: 'caste_certificate',
      displayName: 'Caste / Category Certificate (SC/ST/OBC)',
      displayNameHindi: 'जाति प्रमाण पत्र (अ.जा./अ.ज.जा./ओ.बी.सी.)',
      category: 'Identity',
      categoryHindi: 'पहचान',
      description:
          'Official certificate verifying membership in Scheduled Caste (SC), Scheduled Tribe (ST), or Other Backward Classes (OBC).',
      descriptionHindi:
          'अनुसूचित जाति (SC), अनुसूचित जनजाति (ST) या अन्य पिछड़ा वर्ग (OBC) की सदस्यता प्रमाणित करने वाला आधिकारिक प्रमाण पत्र।',
      purpose:
          'Availing reservation, fee waivers, scholarship quotas, and priority under affirmative welfare schemes.',
      purposeHindi:
          'आरक्षण, शुल्क माफी, छात्रवृत्ति कोटा और विशेष कल्याण योजनाओं में प्राथमिकता प्राप्त करने हेतु।',
      provesInfo: [
        'Constitutional Caste/Tribe Category',
        'Non-Creamy Layer Status (for OBC)',
        'State/Central List Registration',
      ],
      provesInfoHindi: [
        'संवैधानिक जाति/जनजाति वर्ग',
        'नॉन-क्रीमी लेयर स्थिति (ओबीसी हेतु)',
        'राज्य/केंद्रीय सूची में पंजीकरण',
      ],
      issuingAuthority: 'Sub-Divisional Officer (SDO) / Deputy Commissioner / Tehsildar',
      issuingAuthorityHindi: 'एसडीओ / उपायुक्त / तहसीलदार',
      howToObtain: [
        'Apply on e-District portal with father\'s caste certificate or revenue land records showing lineage.',
        'Provide school leaving certificate indicating caste.',
        'Download digitally signed certificate upon field verification.',
      ],
      howToObtainHindi: [
        'पिता के जाति प्रमाण पत्र या वंशावली राजस्व अभिलेख के साथ ई-डिस्ट्रिक्ट पर आवेदन करें।',
        'जाति दर्ज विद्यालय छोड़ने का प्रमाण पत्र (टीसी) संलग्न करें।',
        'क्षेत्रीय सत्यापन उपरांत डिजिटल प्रमाण पत्र डाउनलोड करें।',
      ],
      importantChecks: [
        'For Central schemes, certificate format must comply with Central Government guidelines.',
        'OBC Non-Creamy Layer (NCL) certificate must typically be issued in current financial year.',
      ],
      importantChecksHindi: [
        'केंद्रीय योजनाओं के लिए केंद्र सरकार के प्रारूप का पालन आवश्यक है।',
        'ओबीसी नॉन-क्रीमी लेयर प्रमाण पत्र चालू वित्तीय वर्ष में जारी होना चाहिए।',
      ],
      specimenTitle: 'SPECIMEN: Caste / Tribe Certificate',
      specimenDescription:
          'Government Emblem, Serial Number, Sub-caste name, Reference to Presidential Order/Act, Competent Magistrate Seal.',
    ),
    const DocumentInfoModel(
      documentType: 'ews_certificate',
      displayName: 'EWS Certificate (Economically Weaker Section)',
      displayNameHindi: 'ईडब्ल्यूएस प्रमाण पत्र (आर्थिक रूप से कमजोर वर्ग)',
      category: 'Income',
      categoryHindi: 'आय',
      description:
          'Income and Asset Certificate for candidates belonging to Economically Weaker Sections not covered under SC/ST/OBC.',
      descriptionHindi:
          'अनुसूचित जाति/जनजाति/अन्य पिछड़ा वर्ग से बाहर आर्थिक रूप से कमजोर वर्ग के परिवारों हेतु आय व परिसंपत्ति प्रमाण पत्र।',
      purpose:
          'Availing 10% EWS quota in education, scholarships, and special central assistance programs.',
      purposeHindi:
          'शिक्षा, छात्रवृत्ति और केंद्रीय सहायता कार्यक्रमों में 10% ईडब्ल्यूएस कोटे का लाभ लेने हेतु।',
      provesInfo: [
        'Gross Annual Family Income < ₹8 Lakhs',
        'Asset Verification (Agricultural land < 5 acres, residential flat < 1000 sq ft)',
      ],
      provesInfoHindi: [
        'सकल वार्षिक पारिवारिक आय ₹8 लाख से कम',
        'परिसंपत्ति सत्यापन (5 एकड़ से कम कृषि भूमि, 1000 वर्ग फुट से कम फ्लैट)',
      ],
      issuingAuthority: 'District Magistrate / Additional District Magistrate / Tehsildar',
      issuingAuthorityHindi: 'जिला मजिस्ट्रेट / अतिरिक्त जिला मजिस्ट्रेट / तहसीलदार',
      howToObtain: [
        'Apply through State Revenue or e-District Portal.',
        'Submit family income declarations, property ownership documents, and IT returns.',
      ],
      howToObtainHindi: [
        'राज्य राजस्व या ई-डिस्ट्रिक्ट पोर्टल के माध्यम से आवेदन करें।',
        'पारिवारिक आय घोषणा, संपत्ति दस्तावेज और आयकर रिटर्न संलग्न करें।',
      ],
      importantChecks: [
        'Valid strictly for one financial year (needs annual renewal).',
        'Family income encompasses all sources across applicant, parents, spouse, and minor children.',
      ],
      importantChecksHindi: [
        'केवल एक वित्तीय वर्ष के लिए मान्य (प्रतिवर्ष नवीनीकरण आवश्यक)।',
        'पारिवारिक आय में आवेदक, माता-पिता, पति/पत्नी और नाबालिग बच्चों के सभी स्रोत शामिल हैं।',
      ],
      specimenTitle: 'SPECIMEN: Income & Asset Certificate for EWS',
      specimenDescription:
          'Government Crest, Financial Year specification, Family Income declaration, Asset clearance declaration, Issuing Officer Signature.',
    ),
    const DocumentInfoModel(
      documentType: 'marksheet_12th',
      displayName: 'Class 12th Marksheet & Admission Proof',
      displayNameHindi: '12वीं कक्षा की अंकसूची एवं प्रवेश प्रमाण',
      category: 'Education',
      categoryHindi: 'शिक्षा',
      description:
          'Higher Secondary School Certificate (10+2) marksheet and verified admission letter for recognized professional course.',
      descriptionHindi:
          'उच्चतर माध्यमिक (10+2) अंकसूची तथा मान्यता प्राप्त व्यावसायिक पाठ्यक्रम में प्रवेश का सत्यापन प्रमाण।',
      purpose:
          'Mandatory for Prime Minister\'s Scholarship Scheme (PMSS) and higher education merit assistance.',
      purposeHindi:
          'प्रधानमंत्री छात्रवृत्ति योजना (PMSS) तथा उच्च शिक्षा योग्यता सहायता हेतु अनिवार्य।',
      provesInfo: [
        'Minimum 60% Marks in Minimum Entry Qualification (MEQ)',
        'Date of Birth and Passing Year',
        'Bonafide Enrollment in Recognized Professional Degree',
      ],
      provesInfoHindi: [
        'न्यूनतम प्रवेश योग्यता (MEQ) में न्यूनतम 60% अंक',
        'जन्मतिथि एवं उत्तीर्ण वर्ष',
        'मान्यता प्राप्त डिग्री में वास्तविक प्रवेश',
      ],
      issuingAuthority: 'Recognized Education Board (CBSE/ICSE/State Board) & University Registrar',
      issuingAuthorityHindi: 'मान्यता प्राप्त शिक्षा बोर्ड एवं विश्वविद्यालय रजिस्ट्रार',
      howToObtain: [
        'Obtain original marksheet from School / Board or fetch digital verified copy via DigiLocker.',
        'Obtain Bonafide Certificate and Annexure-1 from Head of Institute/College.',
      ],
      howToObtainHindi: [
        'स्कूल/बोर्ड से मूल अंकसूची प्राप्त करें या डिजिलॉकर से डिजिटल प्रति प्राप्त करें।',
        'कॉलेज प्राचार्य से बोनाफाइड सर्टिफिकेट और अनुलग्नक-1 प्राप्त करें।',
      ],
      importantChecks: [
        'PMSS strictly requires minimum 60% marks in MEQ (Class 12th / Diploma).',
        'Course must be recognized by regulatory bodies like AICTE, UGC, MCI, DCI.',
        'Distance learning or unapproved private diploma programs are ineligible.',
      ],
      importantChecksHindi: [
        'PMSS हेतु MEQ (12वीं/डिप्लोमा) में कम से कम 60% अंक अनिवार्य हैं।',
        'पाठ्यक्रम AICTE, UGC, MCI आदि विनियामक निकायों से मान्यता प्राप्त होना चाहिए।',
        'दूरस्थ शिक्षा या गैर-मान्यता प्राप्त डिप्लोमा अपात्र हैं।',
      ],
      specimenTitle: 'SPECIMEN: Senior School Certificate Examination Marksheet',
      specimenDescription:
          'Board Logo, Roll Number, Candidate Name, Subject-wise Marks & Grades, Overall Percentage, Controller of Examinations signature.',
    ),
    const DocumentInfoModel(
      documentType: 'marksheet_10th',
      displayName: 'Class 10th Certificate / Marksheet',
      displayNameHindi: '10वीं कक्षा का प्रमाण पत्र / अंकसूची',
      category: 'Education',
      categoryHindi: 'शिक्षा',
      description:
          'Secondary School Examination (Class 10) Certificate widely accepted as primary legal proof of Date of Birth.',
      descriptionHindi:
          'माध्यमिक विद्यालय परीक्षा (10वीं) प्रमाण पत्र जो जन्मतिथि के प्राथमिक कानूनी प्रमाण के रूप में मान्य है।',
      purpose:
          'Proof of date of birth, mother/father name spellings, and basic educational matriculation.',
      purposeHindi:
          'जन्मतिथि, माता/पिता के नाम की स्पेलिंग और बुनियादी मैट्रिक शिक्षा का प्रमाण।',
      provesInfo: [
        'Exact Date of Birth (Christian Era)',
        'Legal Full Name & Parents\' Names',
        'Matriculation Completion',
      ],
      provesInfoHindi: [
        'सटीक जन्मतिथि',
        'कानूनी पूरा नाम एवं माता-पिता का नाम',
        'मैट्रिक परीक्षा उत्तीर्ण प्रमाण',
      ],
      issuingAuthority: 'State Education Board / Central Board of Secondary Education (CBSE)',
      issuingAuthorityHindi: 'राज्य शिक्षा बोर्ड / सीबीएसई',
      howToObtain: [
        'Issued by school upon passing matriculation.',
        'Digital verified version available instantly via DigiLocker using Roll Number.',
      ],
      howToObtainHindi: [
        'मैट्रिक उत्तीर्ण करने पर स्कूल द्वारा जारी।',
        'रोल नंबर का उपयोग कर डिजिलॉकर पर तुरंत डिजिटल प्रति उपलब्ध।',
      ],
      importantChecks: [
        'Spelling of applicant and father\'s name must match Aadhaar card.',
        'DOB must match UIDAI record to avoid discrepancy in DBT registration.',
      ],
      importantChecksHindi: [
        'आवेदक और पिता के नाम की स्पेलिंग आधार कार्ड से मेल खानी चाहिए।',
        'जन्मतिथि आधार रिकॉर्ड से पूरी तरह मेल खानी चाहिए।',
      ],
      specimenTitle: 'SPECIMEN: Secondary School Certificate',
      specimenDescription:
          'Board Emblem, Registration Number, Student Name, Date of Birth in figures & words, Pass division, Board Seal.',
    ),
    const DocumentInfoModel(
      documentType: 'mgnrega_job_card',
      displayName: 'MGNREGA Job Card',
      displayNameHindi: 'मनरेगा जॉब कार्ड',
      category: 'Land',
      categoryHindi: 'भूमि',
      description:
          'Job card issued under Mahatma Gandhi National Rural Employment Guarantee Act for rural household wage employment.',
      descriptionHindi:
          'महात्मा गांधी राष्ट्रीय ग्रामीण रोजगार गारंटी अधिनियम के तहत ग्रामीण परिवारों को जारी रोजगार कार्ड।',
      purpose:
          'Proves rural residence, unorganized worker status, and economic deprivation for PMAY-G and social safety nets.',
      purposeHindi:
          'ग्रामीण आवास (PMAY-G) और सामाजिक सुरक्षा योजनाओं हेतु असंगठित श्रमिक और आर्थिक स्थिति प्रमाणित करता है।',
      provesInfo: [
        'Rural Household Registration Number',
        'Family Roster Registered for Manual Work',
        'Days of Employment Completed',
      ],
      provesInfoHindi: [
        'ग्रामीण परिवार पंजीकरण संख्या',
        'शारीरिक श्रम हेतु पंजीकृत सदस्यों के नाम',
        'पूर्ण किए गए रोजगार दिवस',
      ],
      issuingAuthority: 'Gram Panchayat / Block Development Officer (BDO)',
      issuingAuthorityHindi: 'ग्राम पंचायत / खंड विकास अधिकारी (BDO)',
      howToObtain: [
        'Apply in writing or orally to local Gram Panchayat.',
        'Gram Panchayat issues card within 15 days after door-to-door verification.',
      ],
      howToObtainHindi: [
        'स्थानीय ग्राम पंचायत में लिखित या मौखिक आवेदन करें।',
        'सत्यापन उपरांत ग्राम पंचायत 15 दिनों के भीतर कार्ड जारी करती है।',
      ],
      importantChecks: [
        'Must contain photograph of adult household members stamped by Gram Rozgar Sahayak / Pradhan.',
        'Ensure Job Card number is active and seeded with Aadhaar.',
      ],
      importantChecksHindi: [
        'ग्राम प्रधान/सहायक द्वारा मुद्रित परिवार के वयस्क सदस्यों की फोटो होनी चाहिए।',
        'जॉब कार्ड सक्रिय और आधार से जुड़ा होना चाहिए।',
      ],
      specimenTitle: 'SPECIMEN: MGNREGA Rural Employment Card',
      specimenDescription:
          'Ministry of Rural Development Crest, Job Card Number (State/District/Block/Panchayat code), Family member photos, Wage log table.',
    ),
    const DocumentInfoModel(
      documentType: 'disability_certificate',
      displayName: 'Disability Certificate / UDID Card',
      displayNameHindi: 'दिव्यांगता प्रमाण पत्र / यूडीआईडी कार्ड',
      category: 'Identity',
      categoryHindi: 'पहचान',
      description:
          'Unique Disability ID (UDID) card or Medical Board Certificate certifying permanent disability benchmark.',
      descriptionHindi:
          'विशिष्ट दिव्यांगता पहचान (UDID) कार्ड या मेडिकल बोर्ड प्रमाण पत्र जो स्थायी दिव्यांगता को प्रमाणित करता है।',
      purpose:
          'Mandatory for disability welfare schemes, pensions, assistive aids, and affirmative reservations.',
      purposeHindi:
          'दिव्यांग कल्याण योजनाओं, पेंशन, सहायक उपकरण और आरक्षण का लाभ लेने हेतु अनिवार्य।',
      provesInfo: [
        'Disability Percentage Benchmark (typically >= 40%)',
        'Nature and Type of Disability',
        'Permanent or Temporary Validity',
      ],
      provesInfoHindi: [
        'दिव्यांगता प्रतिशत (सामान्यतः 40% या अधिक)',
        'दिव्यांगता की प्रकृति एवं प्रकार',
        'स्थायी अथवा अस्थायी वैधता',
      ],
      issuingAuthority: 'District Medical Board / Chief Medical Officer (CMO)',
      issuingAuthorityHindi: 'जिला मेडिकल बोर्ड / मुख्य चिकित्सा अधिकारी (CMO)',
      howToObtain: [
        'Apply on swavlambancard.gov.in (UDID Portal).',
        'Appear before District Hospital Medical Board for physical evaluation.',
        'Download digital UDID card with QR verification.',
      ],
      howToObtainHindi: [
        'swavlambancard.gov.in (UDID पोर्टल) पर आवेदन करें।',
        'शारीरिक परीक्षण हेतु जिला अस्पताल मेडिकल बोर्ड के समक्ष उपस्थित हों।',
        'क्यूआर युक्त डिजिटल यूडीआईडी कार्ड डाउनलोड करें।',
      ],
      importantChecks: [
        'Most affirmative schemes require minimum 40% benchmark disability.',
        'Check whether disability is marked Permanent or requires re-assessment after stated years.',
      ],
      importantChecksHindi: [
        'अधिकांश योजनाओं में न्यूनतम 40% दिव्यांगता होना अनिवार्य है।',
        'जांचें कि प्रमाण पत्र स्थायी है या निश्चित वर्षों बाद पुनर्मूल्यांकन आवश्यक है।',
      ],
      specimenTitle: 'SPECIMEN: Department of Empowerment of PwDs UDID Card',
      specimenDescription:
          'National Emblem, UDID Card Number, Disability Type & Percentage badge, Medical Superintendent Signature, QR Verification Code.',
    ),
    const DocumentInfoModel(
      documentType: 'voter_id',
      displayName: 'Voter ID (EPIC Card)',
      displayNameHindi: 'मतदाता पहचान पत्र (वोटर आईडी)',
      category: 'Identity',
      categoryHindi: 'पहचान',
      description:
          'Electoral Photo Identity Card issued by the Election Commission of India.',
      descriptionHindi:
          'भारत निर्वाचन आयोग द्वारा जारी मतदाता फोटो पहचान पत्र (EPIC)।',
      purpose: 'Recognized proof of Indian citizenship, identity, and residential constituency.',
      purposeHindi: 'भारतीय नागरिकता, पहचान और विधानसभा/संसदीय क्षेत्र का मान्य प्रमाण।',
      provesInfo: [
        'Indian Citizenship & Voting Age (18+)',
        'Constituency & Residential Address',
      ],
      provesInfoHindi: [
        'भारतीय नागरिकता और मतदान आयु (18+)',
        'निर्वाचन क्षेत्र एवं निवास का पता',
      ],
      issuingAuthority: 'Election Commission of India (ECI)',
      issuingAuthorityHindi: 'भारत निर्वाचन आयोग (ECI)',
      howToObtain: [
        'Apply on voters.eci.gov.in using Form 6.',
        'Download e-EPIC card instantly with digital signature.',
      ],
      howToObtainHindi: [
        'voters.eci.gov.in पर फॉर्म 6 भरें।',
        'ई-एपिक कार्ड तुरंत डाउनलोड करें।',
      ],
      importantChecks: [
        'EPIC number must exist in active electoral roll.',
        'Name spelling must conform to official records.',
      ],
      importantChecksHindi: [
        'एपिक संख्या मतदाता सूची में सक्रिय होनी चाहिए।',
        'नाम की वर्तनी अन्य दस्तावेजों से मेल खानी चाहिए।',
      ],
      specimenTitle: 'SPECIMEN: Election Commission of India Voter ID',
      specimenDescription:
          'ECI Hologram, EPIC Number, Applicant Photo, Father/Husband Name, Assembly Constituency Name & Number.',
    ),
    const DocumentInfoModel(
      documentType: 'pan_card',
      displayName: 'PAN Card (Permanent Account Number)',
      displayNameHindi: 'पैन कार्ड (स्थायी खाता संख्या)',
      category: 'Identity',
      categoryHindi: 'पहचान',
      description:
          '10-character alphanumeric identifier issued by Income Tax Department of India.',
      descriptionHindi:
          'आयकर विभाग, भारत सरकार द्वारा जारी 10 अक्षरों का अल्फान्यूमेरिक पहचान पत्र।',
      purpose: 'Mandatory financial identifier for tax assessment and high-value government transactions.',
      purposeHindi: 'कर निर्धारण और वित्तीय लेन-देन हेतु अनिवार्य वित्तीय पहचान पत्र।',
      provesInfo: [
        'Financial Identity & Taxpayer Tracking',
        'Date of Birth & Father\'s Name',
      ],
      provesInfoHindi: [
        'वित्तीय पहचान एवं करदाता ट्रैकिंग',
        'जन्मतिथि एवं पिता का नाम',
      ],
      issuingAuthority: 'Income Tax Department (Protean / UTIITSL)',
      issuingAuthorityHindi: 'आयकर विभाग (प्रोटियन / यूटीआईआईटीएसएल)',
      howToObtain: [
        'Apply via onlineservices.nsdl.com or instant e-PAN via incometax.gov.in.',
      ],
      howToObtainHindi: [
        'एनएसडीएल या आयकर ई-फाइलिंग पोर्टल से तत्काल ई-पैन प्राप्त करें।',
      ],
      importantChecks: [
        'PAN must be mandatorily linked with Aadhaar.',
      ],
      importantChecksHindi: [
        'पैन का आधार से जुड़ा होना अनिवार्य है।',
      ],
      specimenTitle: 'SPECIMEN: Income Tax Department Permanent Account Card',
      specimenDescription:
          'Income Tax Department Crest, 10-character PAN number, Hologram, Photograph, QR code, Father\'s Name.',
    ),
    const DocumentInfoModel(
      documentType: 'residence_certificate',
      displayName: 'Proof of Residence (Electricity Bill / Water Bill)',
      displayNameHindi: 'निवास का प्रमाण (बिजली / पानी बिल)',
      category: 'Address',
      categoryHindi: 'पता',
      description:
          'Utility bill or local authority certificate validating active domestic residence at specified address.',
      descriptionHindi:
          'उपयोगिता बिल या स्थानीय निकाय प्रमाण पत्र जो निर्दिष्ट पते पर सक्रिय घरेलू निवास प्रमाणित करता है।',
      purpose: 'Address verification for gas connection (Ujjwala) and housing surveys.',
      purposeHindi: 'गैस कनेक्शन (उज्ज्वला) और आवास सर्वेक्षण हेतु पते का सत्यापन।',
      provesInfo: [
        'Physical Premise Address & Meter Connection',
      ],
      provesInfoHindi: [
        'भौतिक परिसर का पता एवं मीटर कनेक्शन',
      ],
      issuingAuthority: 'State Electricity Distribution Company / Municipal Water Board',
      issuingAuthorityHindi: 'विद्युत वितरण निगम / जल बोर्ड / नगर निगम',
      howToObtain: [
        'Download latest monthly utility bill from electricity discom or municipal portal.',
      ],
      howToObtainHindi: [
        'बिजली कंपनी या नगर निगम पोर्टल से नवीनतम मासिक बिल डाउनलोड करें।',
      ],
      importantChecks: [
        'Bill must not be older than 3 months for official address verification.',
      ],
      importantChecksHindi: [
        'आधिकारिक पते के सत्यापन हेतु बिल 3 महीने से अधिक पुराना नहीं होना चाहिए।',
      ],
      specimenTitle: 'SPECIMEN: Electricity / Water Utility Invoice',
      specimenDescription:
          'Discom Header, Consumer Account Number (CA), Billing Cycle, Meter Address, Payment receipt barcode.',
    ),
    const DocumentInfoModel(
      documentType: 'birth_certificate',
      displayName: 'Birth Certificate',
      displayNameHindi: 'जन्म प्रमाण पत्र',
      category: 'Identity',
      categoryHindi: 'पहचान',
      description:
          'Official record of a person\'s birth registered with municipal or local registrar under Registration of Births and Deaths Act.',
      descriptionHindi:
          'जन्म और मृत्यु पंजीकरण अधिनियम के तहत नगर पालिका या स्थानीय रजिस्ट्रार द्वारा जारी आधिकारिक जन्म प्रमाण पत्र।',
      purpose:
          'Conclusive legal proof of age, date of birth, and parentage for government schemes.',
      purposeHindi:
          'सरकारी योजनाओं के लिए आयु, जन्म तिथि और माता-पिता के नाम का निर्णायक कानूनी प्रमाण।',
      provesInfo: [
        'Date of Birth & Legal Age',
        'Place of Birth',
        'Mother and Father Names',
        'Registration Number & Issue Date',
      ],
      provesInfoHindi: [
        'जन्म तिथि एवं कानूनी आयु',
        'जन्म स्थान',
        'माता एवं पिता का नाम',
        'पंजीकरण संख्या एवं जारी तिथि',
      ],
      issuingAuthority: 'Municipal Corporation / Gram Panchayat / Registrar of Births and Deaths',
      issuingAuthorityHindi: 'नगर निगम / ग्राम पंचायत / जन्म एवं मृत्यु रजिस्ट्रार',
      howToObtain: [
        'Apply online via state Civil Registration System (CRS) portal or state portal.',
        'Submit hospital discharge slip / birth notification slip within 21 days.',
        'Download digitally verified birth certificate with QR code.',
        'Alternatively, visit the local Municipal Ward office or Gram Panchayat.',
      ],
      howToObtainHindi: [
        'नागरिक पंजीकरण प्रणाली (CRS) पोर्टल या राज्य पोर्टल के माध्यम से ऑनलाइन आवेदन करें।',
        '21 दिनों के भीतर अस्पताल की डिस्चार्ज पर्ची / जन्म सूचना जमा करें।',
        'क्यूआर कोड युक्त डिजिटल रूप से सत्यापित जन्म प्रमाण पत्र डाउनलोड करें।',
        'अथवा स्थानीय नगर निगम वार्ड कार्यालय या ग्राम पंचायत में संपर्क करें।',
      ],
      importantChecks: [
        'Spellings of child and parents\' names must match Aadhaar card and school records.',
        'Ensure the certificate contains a valid registration number and digital or official seal.',
      ],
      importantChecksHindi: [
        'बच्चे और माता-पिता के नाम की वर्तनी आधार और स्कूल रिकॉर्ड से मेल खानी चाहिए।',
        'सुनिश्चित करें कि प्रमाण पत्र पर वैध पंजीकरण संख्या और आधिकारिक मुहर मौजूद हो।',
      ],
      specimenTitle: 'SPECIMEN: Certificate of Birth',
      specimenDescription:
          'Government header with State/Registrar crest, Registration Number, Child\'s Full Name, Sex, Date of Birth, Place of Birth, Parents\' Names, and Registrar Seal.',
    ),
    const DocumentInfoModel(
      documentType: 'additional_document',
      displayName: 'Additional Document',
      displayNameHindi: 'अतिरिक्त दस्तावेज़',
      category: 'Other',
      categoryHindi: 'अन्य',
      description:
          'Any supplementary or specialized government certificate or document not listed above.',
      descriptionHindi:
          'उपरोक्त में सूचीबद्ध न किया गया कोई भी पूरक या विशिष्ट सरकारी प्रमाण पत्र अथवा दस्तावेज़।',
      purpose: 'Supplementary proof for specialized eligibility or exemption rules.',
      purposeHindi: 'विशिष्ट पात्रता या छूट नियमों हेतु पूरक प्रमाण।',
      provesInfo: [
        'Custom Scheme Requirement or Declaration',
      ],
      provesInfoHindi: [
        'कस्टम योजना आवश्यकता अथवा घोषणा',
      ],
      issuingAuthority: 'Competent Authority / Notary Public',
      issuingAuthorityHindi: 'सक्षम प्राधिकारी / नोटरी पब्लिक',
      howToObtain: [
        'Obtain from issuing department or competent office.',
      ],
      howToObtainHindi: [
        'जारीकर्ता विभाग अथवा सक्षम कार्यालय से प्राप्त करें।',
      ],
      importantChecks: [
        'Ensure the certificate name and details match your government application requirements.',
      ],
      importantChecksHindi: [
        'सुनिश्चित करें कि प्रमाण पत्र का नाम और विवरण आपके सरकारी आवेदन की आवश्यकताओं से मेल खाते हैं।',
      ],
      specimenTitle: 'SPECIMEN: Additional Document',
      specimenDescription:
          'Official Document Header, Certificate Title, Holder Details, Issuing Authority Seal and Signature.',
    ),
    const DocumentInfoModel(
      documentType: 'other_document',
      displayName: 'Other Supporting Document / Affidavit',
      displayNameHindi: 'अन्य समर्थक दस्तावेज / शपथ पत्र',
      category: 'Other',
      categoryHindi: 'अन्य',
      description:
          'Additional certificates, notarized affidavits, death certificates, or discharge books for specific scheme requirements.',
      descriptionHindi:
          'विशिष्ट योजनाओं के लिए अतिरिक्त प्रमाण पत्र, नोटरी शपथ पत्र, मृत्यु प्रमाण पत्र या डिस्चार्ज बुक।',
      purpose: 'Supplementary proof for specialized eligibility or exemption rules.',
      purposeHindi: 'विशिष्ट पात्रता या छूट नियमों हेतु पूरक प्रमाण।',
      provesInfo: [
        'Specific Scheme Claim or Exemption Declaration',
      ],
      provesInfoHindi: [
        'विशिष्ट योजना दावा अथवा छूट घोषणा',
      ],
      issuingAuthority: 'Notary Public / Competent Department / Armed Forces Records Office',
      issuingAuthorityHindi: 'नोटरी पब्लिक / सक्षम विभाग / सशस्त्र बल रिकॉर्ड कार्यालय',
      howToObtain: [
        'Obtain relevant stamp paper affidavit or department-certified extract.',
      ],
      howToObtainHindi: [
        'संबंधित स्टाम्प पेपर शपथ पत्र या विभाग द्वारा प्रमाणित उद्धरण प्राप्त करें।',
      ],
      importantChecks: [
        'Ensure proper notarization and non-judicial stamp paper value as prescribed.',
      ],
      importantChecksHindi: [
        'निर्धारित मूल्य के गैर-न्यायिक स्टाम्प पेपर पर विधिवत नोटरीकृत होना सुनिश्चित करें।',
      ],
      specimenTitle: 'SPECIMEN: Supporting Declaration / Certificate',
      specimenDescription:
          'Non-judicial Stamp Header, Notary Seal, Deponent Signature, Witness details, Verification clause.',
    ),
  ];

  /// Returns all 18 canonical document models
  static List<DocumentInfoModel> getAllDocuments() =>
      List.unmodifiable(_allDocuments);

  /// Find document by canonical document type ID
  static DocumentInfoModel? getDocumentByType(String documentType) {
    try {
      final clean = documentType.toLowerCase().trim();
      return _allDocuments.firstWhere(
        (d) => d.documentType.toLowerCase().trim() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Categorized map of documents
  static Map<String, List<DocumentInfoModel>> getDocumentsByCategory() {
    final Map<String, List<DocumentInfoModel>> map = {};
    for (final doc in _allDocuments) {
      map.putIfAbsent(doc.category, () => []).add(doc);
    }
    return map;
  }

  /// Normalizes and deduplicates a list of scheme required document strings.
  /// 
  /// 1. Strips leading/trailing whitespace and collapses internal multiple spaces.
  /// 2. Skips empty strings.
  /// 3. Matches each document string against supported canonical document types.
  /// 4. Documents sharing a canonical type (e.g. 'Aadhaar Card' and 'Aadhaar Card of applicant')
  ///    are deduplicated to a single canonical entry.
  /// 5. Non-canonical/custom documents (canonicalId == 'other_document') are preserved
  ///    as distinct requirements unless their normalized names are byte-for-byte identical
  ///    (case-insensitive, whitespace-normalized).
  static List<String> deduplicateDocuments(List<String> rawDocuments) {
    if (rawDocuments.isEmpty) return const [];

    final List<String> result = [];
    final Set<String> seenKeys = {};

    for (final raw in rawDocuments) {
      final clean = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (clean.isEmpty) continue;

      final canonicalId = matchCanonicalId(clean);

      // If mapped to a recognized canonical document type, deduplicate by canonicalId
      final dedupeKey = canonicalId != 'other_document'
          ? canonicalId
          : clean.toLowerCase();

      if (seenKeys.add(dedupeKey)) {
        result.add(clean);
      }
    }

    return List.unmodifiable(result);
  }

  /// Fuzzy and semantic matcher that maps scheme requirement strings to canonical document IDs
  static String matchCanonicalId(String documentName) {
    final s = documentName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    // 1. Direct canonical identifier check (e.g. 'aadhaar_card', 'birth_certificate')
    final normalizedId = s.replaceAll('-', '_').replaceAll(' ', '_');
    for (final d in _allDocuments) {
      if (d.documentType == normalizedId || d.documentType == s) {
        return d.documentType;
      }
    }

    // 2. High-precedence compound/context-sensitive checks:
    // If it's a bank account / passbook / statement / cheque (even if "Aadhaar-linked" or "Aadhaar-seeded"),
    // its primary document category is bank_passbook.
    if (s.contains('passbook') ||
        s.contains('cheque') ||
        s.contains('bank account') ||
        s.contains('bank statement') ||
        s.contains('पासबुक') ||
        s.contains('खाता विवरण') ||
        (s.contains('bank') && !s.contains('land'))) {
      return 'bank_passbook';
    }

    // If it's a mobile/phone number verification, it is contact verification, not an identity doc.
    if (s.contains('mobile') || s.contains('phone') || s.contains('मोबाइल')) {
      // 17. Additional Document
    if (s.contains('additional') || s == 'additional_document' || s.contains('अतिरिक्त')) {
      return 'additional_document';
    }

    return 'other_document';
    }

    // 3. Primary identity: Aadhaar
    if (s.contains('aadhaar') || s.contains('aadhar') || s.contains('आधार')) {
      return 'aadhaar_card';
    }

    // 4. Land ownership & revenue records
    if (s.contains('khatauni') ||
        s.contains('khasra') ||
        s.contains('land') ||
        s.contains('ror') ||
        s.contains('patta') ||
        s.contains('भूलेख') ||
        s.contains('खतौनी') ||
        s.contains('खसरा') ||
        s.contains('जमीन')) {
      return 'land_ownership_record';
    }

    // 5. Samagra ID
    if (s.contains('samagra') ||
        s.contains('sssm') ||
        s.contains('समग्र')) {
      return 'samagra_id';
    }

    // 6. Birth Certificate
    if (s.contains('birth certificate') ||
        s.contains('date of birth proof') ||
        s.contains('जन्म प्रमाण') ||
        (s.contains('birth') && !s.contains('death'))) {
      return 'birth_certificate';
    }

    // 7. Income Certificate (Checked before BPL to avoid misclassifying "Income Certificate or BPL Card")
    if (s.contains('income certificate') ||
        s.contains('income proof') ||
        s.contains('आय प्रमाण') ||
        (s.contains('income') && !s.contains('tax') && !s.contains('declaration'))) {
      return 'income_certificate';
    }

    // 8. Ration Card / BPL / NFSA / AAY
    // CRITICAL: Must NOT match 'declaration' or 'affidavit' (which contain 'ration' as substring)!
    final isDeclaration = s.contains('declaration') || s.contains('affidavit') || s.contains('शपथ पत्र');
    if (!isDeclaration &&
        (s.contains('ration') ||
         s.contains('bpl') ||
         s.contains('aay') ||
         s.contains('nfsa') ||
         s.contains('राशन'))) {
      return 'ration_card';
    }

    // 9. Domicile / Residence Certificate
    if (s.contains('domicile') ||
        s.contains('residence') ||
        s.contains('निवास') ||
        s.contains('अधिवास')) {
      return 'domicile_certificate';
    }

    // 10. Caste Certificate
    if (s.contains('caste') ||
        s.contains('जाति') ||
        s.contains('sc/st') ||
        s.contains('obc certificate')) {
      return 'caste_certificate';
    }

    // 11. EWS Certificate
    if (s.contains('ews') || s.contains('ईडब्ल्यूएस') || s.contains('economically weaker')) {
      return 'ews_certificate';
    }

    // 12. Educational Marksheets
    if (s.contains('12th') ||
        s.contains('intermediate') ||
        s.contains('10+2') ||
        s.contains('meq') ||
        s.contains('12वीं')) {
      return 'marksheet_12th';
    }
    if (s.contains('10th') ||
        s.contains('matric') ||
        s.contains('10वीं')) {
      return 'marksheet_10th';
    }

    // 13. MGNREGA Job Card
    if (s.contains('mgnrega') ||
        s.contains('nrega') ||
        s.contains('job card') ||
        s.contains('मनरेगा')) {
      return 'mgnrega_job_card';
    }

    // 14. Disability Certificate
    if (s.contains('disability') ||
        s.contains('udid') ||
        s.contains('handicapped') ||
        s.contains('दिव्यांग')) {
      return 'disability_certificate';
    }

    // 15. Voter ID
    if (s.contains('voter') ||
        s.contains('epic') ||
        s.contains('मतदाता')) {
      return 'voter_id';
    }

    // 16. PAN Card
    if (RegExp(r'\bpan\b|\bpan card\b|पैन').hasMatch(s)) {
      return 'pan_card';
    }

    // 17. Additional Document
    if (s.contains('additional') || s == 'additional_document' || s.contains('अतिरिक्त')) {
      return 'additional_document';
    }

    return 'other_document';
  }

  static const Map<String, Map<String, String>> _localizedDocNames = {
    'aadhaar_card': {
      'ta': 'ஆதார் அட்டை',
      'mr': 'आधार कार्ड',
      'bn': 'আধার কার্ড',
      'gu': 'આધાર કાર્ડ',
      'kn': 'ಆಧಾರ್ ಕಾರ್ಡ್',
      'or': 'ଆଧାର କାର୍ଡ',
    },
    'land_ownership_record': {
      'ta': 'நில உரிமை ஆவணம் (பட்டா / சிட்டா)',
      'mr': 'जमीन मालकी नोंद (खतावणी/सातबारा)',
      'bn': 'জমির খতিয়ান / পরচা',
      'gu': 'જમીન માલિકી રેકોર્ડ (સાત-બાર)',
      'kn': 'ಜಮೀನು ಮಾಲೀಕತ್ವದ ದಾಖಲೆ (ಪಹಣಿ/ಖಾತೆ)',
      'or': 'ଜମି ମାଲିକାନା ରେକର୍ଡ (ପଟ୍ଟା / ଖତିୟାନ)',
    },
    'bank_passbook': {
      'ta': 'வங்கி கணக்குப் புத்தகம் (DBT இணைக்கப்பட்டது)',
      'mr': 'बँक खाते पासबुक (DBT सक्रिय)',
      'bn': 'ব্যাঙ্ক অ্যাকাউন্ট পাসবুক (DBT সক্রিয়)',
      'gu': 'બેંક એકાઉન્ટ પાસબુક (DBT સક્રિય)',
      'kn': 'ಬ್ಯಾಂಕ್ ಖಾತೆ ಪಾಸ್‌ಬುಕ್ (DBT ಸಕ್ರಿಯ)',
      'or': 'ବ୍ୟାଙ୍କ ଖାତା ପାସବୁକ୍ (DBT ସକ୍ରିୟ)',
    },
    'ration_card': {
      'ta': 'ரேஷன் அட்டை (BPL / AAY)',
      'mr': 'रेशन कार्ड (BPL / अंत्योदय)',
      'bn': 'রেশন কার্ড (BPL / AAY)',
      'gu': 'રેશન કાર્ડ (BPL / AAY)',
      'kn': 'ರೇಷನ್ ಕಾರ್ಡ್ (BPL / AAY)',
      'or': 'ରାସନ କାର୍ଡ (BPL / AAY)',
    },
    'samagra_id': {
      'ta': 'சமக்ரா ஐடி (குடும்ப மற்றும் உறுப்பினர் ஐடி)',
      'mr': 'समग्र आयडी (कुटुंब व सदस्य)',
      'bn': 'সমগ্র আইডি (পরিবার ও সদস্য)',
      'gu': 'સમગ્ર આઈડી (પરિવાર અને સભ્ય)',
      'kn': 'ಸಮಗ್ರ ಐಡಿ (ಕುಟುಂಬ ಮತ್ತು ಸದಸ್ಯ)',
      'or': 'ସମଗ୍ର ଆଇଡି (ପରିବାର ଏବଂ ସଦସ୍ୟ)',
    },
    'income_certificate': {
      'ta': 'வருமானச் சான்றிதழ்',
      'mr': 'उत्पन्न दाखला',
      'bn': 'আয় সনদ',
      'gu': 'આવક પ્રમાણપત્ર',
      'kn': 'ಆದಾಯ ಪ್ರಮಾಣಪತ್ರ',
      'or': 'ଆୟ ପ୍ରମାଣପତ୍ର',
    },
    'domicile_certificate': {
      'ta': 'இருப்பிடச் சான்றிதழ்',
      'mr': 'अधिवास दाखला',
      'bn': 'আবাসিক সনদ',
      'gu': 'રહેઠાણ પ્રમાણપત્ર',
      'kn': 'ನಿವಾಸ ಪ್ರಮಾಣಪತ್ರ',
      'or': 'ସ୍ଥାୟୀ ବାସିନ୍ଦା ପ୍ରମାଣପତ୍ର',
    },
    'caste_certificate': {
      'ta': 'சாதிச் சான்றிதழ் (SC / ST / OBC)',
      'mr': 'जात प्रमाणपत्र (SC / ST / OBC)',
      'bn': 'জাতি সনদ (SC / ST / OBC)',
      'gu': 'જાતિ પ્રમાણપત્ર (SC / ST / OBC)',
      'kn': 'ಜಾತಿ ಪ್ರಮಾಣಪತ್ರ (SC / ST / OBC)',
      'or': 'ଜାତି ପ୍ରମାଣପତ୍ର (SC / ST / OBC)',
    },
    'ews_certificate': {
      'ta': 'பொருளாதாரத்தில் பின்தங்கியோர் சான்றிதழ் (EWS)',
      'mr': 'आर्थिकदृष्ट्या दुर्बल घटक प्रमाणपत्र (EWS)',
      'bn': 'অর্থনৈতিকভাবে দুর্বল বিভাগ সনদ (EWS)',
      'gu': 'આર્થિક રીતે નબળા વર્ગ પ્રમાણપત્ર (EWS)',
      'kn': 'ಆರ್ಥಿಕವಾಗಿ ದುರ್ಬಲ ವರ್ಗದ ಪ್ರಮಾಣಪತ್ರ (EWS)',
      'or': 'ଆର୍ଥିକ ଦୁର୍ବଳ ବର୍ଗ ପ୍ରମାଣପତ୍ର (EWS)',
    },
    'marksheet_12th': {
      'ta': '12 ஆம் வகுப்பு மதிப்பெண் பட்டியல்',
      'mr': '१२ वी गुणपत्रिका',
      'bn': 'দ্বাদশ শ্রেণীর মার্কশিট',
      'gu': 'ધોરણ 12 ની માર્કશીટ',
      'kn': '12 ನೇ ತರಗತಿ ಅಂಕಪಟ್ಟಿ',
      'or': 'ଦ୍ୱାଦଶ ଶ୍ରେଣୀ ମାର୍କସିଟ୍',
    },
    'marksheet_10th': {
      'ta': '10 ஆம் வகுப்பு மதிப்பெண் பட்டியல்',
      'mr': '१० वी गुणपत्रिका',
      'bn': 'দশম শ্রেণীর মার্কশিট',
      'gu': 'ધોરણ 10 ની માર્કશીટ',
      'kn': '10 ನೇ ತರಗತಿ ಅಂಕಪಟ್ಟಿ',
      'or': 'ଦଶମ ଶ୍ରେଣୀ ମାର୍କସିଟ୍',
    },
    'mgnrega_job_card': {
      'ta': 'மகாத்மா காந்தி ஊரக வேலைவாய்ப்பு அட்டை',
      'mr': 'मनरेगा जॉब कार्ड',
      'bn': 'মনরেগা জব কার্ড',
      'gu': 'મનરેગા જોબ કાર્ડ',
      'kn': 'ಮನರೇಗಾ ಜಾಬ್ ಕಾರ್ಡ್',
      'or': 'ମନରେଗା ଜବ୍ କାର୍ଡ',
    },
    'disability_certificate': {
      'ta': 'மாற்றுத்திறனாளி சான்றிதழ் (UDID)',
      'mr': 'दिव्यांग प्रमाणपत्र (UDID)',
      'bn': 'প্রতিবন্ধী সনদ (UDID)',
      'gu': 'દિવ્યાંગ પ્રમાણપત્ર (UDID)',
      'kn': 'ಅಂಗವೈಕಲ್ಯ ಪ್ರಮಾಣಪತ್ರ (UDID)',
      'or': 'ଦିବ୍ୟାଙ୍ଗ ପ୍ରମାଣପତ୍ର (UDID)',
    },
    'voter_id': {
      'ta': 'வாக்காளர் அடையாள அட்டை (EPIC)',
      'mr': 'मतदार ओळखपत्र (EPIC)',
      'bn': 'ভোটার আইডি কার্ড (EPIC)',
      'gu': 'મતદાર ઓળખકાર્ડ (EPIC)',
      'kn': 'ಮತದಾರರ ಗುರುತಿನ ಚೀಟಿ (EPIC)',
      'or': 'ଭୋଟର ପରିଚୟ ପତ୍ର (EPIC)',
    },
    'pan_card': {
      'ta': 'பான் அட்டை',
      'mr': 'पॅन कार्ड',
      'bn': 'প্যান কার্ড',
      'gu': 'પાન કાર્ડ',
      'kn': 'ಪ್ಯಾನ್ ಕಾರ್ಡ್',
      'or': 'ପାନ କାର୍ଡ',
    },
    'residence_certificate': {
      'ta': 'வசிப்பிடச் சான்றிதழ்',
      'mr': 'रहिवासी दाखला',
      'bn': 'বসবাসের সনদ',
      'gu': 'રહેઠાણનું પ્રમાણપત્ર',
      'kn': 'ವಾಸಸ್ಥಳ ಪ್ರಮಾಣಪತ್ರ',
      'or': 'ବାସସ୍ଥାନ ପ୍ରମାଣପତ୍ର',
    },
    'birth_certificate': {
      'ta': 'பிறப்புச் சான்றிதழ்',
      'mr': 'जन्म दाखला',
      'bn': 'জন্ম সনদ',
      'gu': 'જન્મ પ્રમાણપત્ર',
      'kn': 'ಜನನ ಪ್ರಮಾಣಪತ್ರ',
      'or': 'ଜନ୍ମ ପ୍ରମାଣପତ୍ର',
    },
    'additional_document': {
      'ta': 'கூடுதல் ஆவணம்',
      'mr': 'अतिरिक्त कागदपत्र',
      'bn': 'অতিরিক্ত নথি',
      'gu': 'વધારાનો દસ્તાવેજ',
      'kn': 'ಹೆಚ್ಚುವರಿ ದಾಖಲೆ',
      'or': 'ଅତିରିକ୍ତ ଦଲିଲ',
    },
    'other_document': {
      'ta': 'பிற ஆவணம்',
      'mr': 'इतर कागदपत्र',
      'bn': 'অন্যান্য নথি',
      'gu': 'અન્ય દસ્તાવેજ',
      'kn': 'ಇತರ ದಾಖಲೆ',
      'or': 'ଅନ୍ୟାନ୍ୟ ଦଲିଲ',
    },
  };

  /// Return user-facing name for a canonical ID across all 8 supported languages
  static String getDisplayName(String canonicalId, [String lang = 'en']) {
    final cleanId = canonicalId.trim().toLowerCase();
    final langKey = lang.toLowerCase();

    final localized = _localizedDocNames[cleanId]?[langKey];
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }

    final doc = getDocumentByType(canonicalId);
    if (doc == null) {
      return canonicalId
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    if (langKey == 'hi') {
      return doc.displayNameHindi;
    }
    return doc.displayName;
  }
}

