/// Represents structured official guidance and cautionary rules for a scheme.
class SchemeNotesData {
  final String schemeId;
  final List<String> criticalConditions;
  final List<String> criticalConditionsHindi;
  final List<String> disqualificationReasons;
  final List<String> disqualificationReasonsHindi;
  final List<String> documentRequirements;
  final List<String> documentRequirementsHindi;
  final List<String> applicationPrecautions;
  final List<String> applicationPrecautionsHindi;

  const SchemeNotesData({
    required this.schemeId,
    required this.criticalConditions,
    required this.criticalConditionsHindi,
    required this.disqualificationReasons,
    required this.disqualificationReasonsHindi,
    required this.documentRequirements,
    required this.documentRequirementsHindi,
    required this.applicationPrecautions,
    required this.applicationPrecautionsHindi,
  });
}

/// Authoritative provider of grounded official rules, disqualifications,
/// document checks, and precautions for all SAHAY schemes.
class SchemeNotesService {
  static final Map<String, SchemeNotesData> _notesMap = {
    // 1. PM-KISAN
    'pm_kisan': const SchemeNotesData(
      schemeId: 'pm_kisan',
      criticalConditions: [
        'Small and marginal farmer families owning cultivable landholding in state revenue records before the cutoff date (01-02-2019).',
        'Defined farmer family comprises Husband, Wife, and minor children (single beneficiary entitlement per family unit).',
        'Mandatory Aadhaar linkage with active bank account and NPCI DBT mapper enabled.',
        'Mandatory periodic e-KYC (via biometric at CSC or facial/OTP on pmkisan.gov.in).',
      ],
      criticalConditionsHindi: [
        'कट-ऑफ तिथि (01-02-2019) से पहले राज्य राजस्व अभिलेखों में कृषि योग्य भूमि के स्वामित्व वाले लघु व सीमांत किसान परिवार।',
        'किसान परिवार इकाई में पति, पत्नी और नाबालिग बच्चे शामिल हैं (प्रति परिवार केवल एक सदस्य को लाभ)।',
        'सक्रिय बैंक खाते और NPCI DBT मैपर के साथ अनिवार्य आधार लिंकेज।',
        'अनिवार्य ई-केवाईसी (सीएससी पर बायोमेट्रिक अथवा पोर्टल पर ओटीपी/चेहरा प्रमाणीकरण)।',
      ],
      disqualificationReasons: [
        'Institutional landholders (temples, trusts, societies, or commercial farms).',
        'Former or present holders of constitutional posts (Ministers, MPs, MLAs, Mayors, Zila Panchayat Presidents).',
        'Serving or retired officers and employees of Central/State Govts, Ministries, PSUs, and Local Bodies (excluding Class IV / Group D / MTS).',
        'All superannuated / retired pensioners whose monthly pension is ₹10,000 or more (excluding Class IV / Group D).',
        'Any individual or family member who paid Income Tax in the last assessment year.',
        'Registered practicing professionals: Doctors, Engineers, Lawyers, Chartered Accountants, and Architects.',
        'Agricultural land converted for non-agricultural, residential, or commercial activities.',
      ],
      disqualificationReasonsHindi: [
        'संस्थागत भूमि धारक (मंदिर, ट्रस्ट, सोसायटियां या कॉर्पोरेट कृषि फार्म)।',
        'संवैधानिक पदों के वर्तमान या पूर्व धारक (मंत्री, सांसद, विधायक, महापौर, जिला पंचायत अध्यक्ष)।',
        'केंद्र/राज्य सरकार, मंत्रालयों, सार्वजनिक उपक्रमों और स्थानीय निकायों के सेवारत या सेवानिवृत्त कर्मचारी (चतुर्थ श्रेणी/ग्रुप डी को छोड़कर)।',
        '₹10,000 या अधिक मासिक पेंशन प्राप्त करने वाले सेवानिवृत्त पेंशनभोगी (ग्रुप डी को छोड़कर)।',
        'गत निर्धारण वर्ष में आयकर का भुगतान करने वाले व्यक्ति या परिवार के सदस्य।',
        'पंजीकृत पेशेवर: डॉक्टर, इंजीनियर, वकील, चार्टर्ड अकाउंटेंट और आर्किटेक्ट।',
        'गैर-कृषि, आवासीय या व्यावसायिक उपयोग में परिवर्तित कृषि भूमि।',
      ],
      documentRequirements: [
        'Updated Land Ownership Record (Khatauni / Khasra / RoR) in applicant farmer\'s name registered before 01-02-2019.',
        'Aadhaar Card of the applicant farmer.',
        'Active Bank Passbook with IFSC Code linked to NPCI Aadhaar payment gateway.',
        'Self-declaration undertaking affirming non-exclusion under PM-KISAN operational guidelines.',
      ],
      documentRequirementsHindi: [
        'कट-ऑफ तिथि (01-02-2019) से पूर्व पंजीकृत आवेदक किसान के नाम अद्यतन भूमि अभिलेख (खतौनी/खसरा/RoR)।',
        'आवेदक किसान का आधार कार्ड।',
        'NPCI आधार भुगतान गेटवे से जुड़ा IFSC कोड सहित सक्रिय बैंक पासबुक।',
        'पीएम-किसान परिचालन दिशानिर्देशों के तहत अपवर्जित न होने का स्व-घोषणा पत्र।',
      ],
      applicationPrecautions: [
        'Verify that Land Seeding is marked "YES" on the PM-KISAN portal; missing land seeding halts installment disbursement.',
        'Applicant\'s name on Aadhaar MUST match the spelling on the land title and bank passbook exactly.',
        'Only one ₹2,000 payment per four-month period per farmer family is lawful; duplicate claims trigger recovery notices.',
      ],
      applicationPrecautionsHindi: [
        'सत्यापित करें कि पोर्टल पर Land Seeding "YES" है; भूमि सीडिंग न होने पर किस्तें रुक जाती हैं।',
        'आधार, भूमि रिकॉर्ड और बैंक खाते में नाम की वर्तनी (Spelling) हूबहू एक समान होनी चाहिए।',
        'प्रति परिवार प्रति चौमासे केवल एक ₹2,000 का भुगतान वैध है; दोहरे दावों पर कानूनी वसूली की जा सकती है।',
      ],
    ),

    // 2. PM-JAY
    'pmjay': const SchemeNotesData(
      schemeId: 'pmjay',
      criticalConditions: [
        'Family entitlement established automatically from Socio-Economic Caste Census (SECC 2011) deprivation criteria (D1 to D7 rural, 11 occupational groups urban).',
        'Also covers NFSA Ration Card holders, active RSBY beneficiary cardholders, and Senior Citizens aged 70+ under Ayushman Vaya Vandana.',
        'Cashless secondary and tertiary hospitalization cover up to ₹5,00,000 per family per financial year.',
        'No restriction on family size, gender, or age; pre-existing health conditions covered from day one.',
      ],
      criticalConditionsHindi: [
        'सामाजिक-आर्थिक जाति जनगणना (SECC 2011) वंचन श्रेणियों (ग्रामीण D1-D7, शहरी 11 कार्य श्रेणियां) के आधार पर स्वतः पात्रता।',
        'राष्ट्रीय खाद्य सुरक्षा राशन कार्ड धारक तथा 70 वर्ष से अधिक आयु के वरिष्ठ नागरिक (आयुष्मान वय वंदना) भी पात्र हैं।',
        'प्रति परिवार प्रति वर्ष ₹5,00,000 तक का कैशलेस द्वितीयक एवं तृतीयक अस्पताल उपचार।',
        'परिवार के आकार या आयु पर कोई सीमा नहीं; सभी पूर्व-विद्यमान बीमारियां प्रथम दिवस से आच्छादित।',
      ],
      disqualificationReasons: [
        'Households owning motorized two/three/four wheelers, mechanized fishing boats, or heavy agricultural machinery.',
        'Holders of Kisan Credit Card with credit limit of ₹50,000 or higher.',
        'Household with any member employed as a regular government servant.',
        'Household running non-agricultural enterprise registered with the government.',
        'Any household member paying income tax or professional tax.',
        'Households with pucca house having three or more rooms with pucca roof and pucca walls.',
        'Owning 5 acres or more of irrigated land or 10 acres of unirrigated land.',
      ],
      disqualificationReasonsHindi: [
        'मोटर चालित दो/तीन/चार पहिया वाहन, मशीनीकृत नाव या भारी कृषि उपकरण वाले परिवार।',
        '₹50,000 या अधिक क्रेडिट सीमा वाला किसान क्रेडिट कार्ड (KCC) धारक परिवार।',
        'परिवार का कोई सदस्य नियमित सरकारी सेवा में कार्यरत हो।',
        'सरकार में पंजीकृत गैर-कृषि उद्यम चलाने वाले परिवार।',
        'परिवार का कोई सदस्य आयकर अथवा व्यावसायिक कर का भुगतान करता हो।',
        'पक्की छत और पक्की दीवारों वाले 3 या अधिक कमरों के पक्के मकान वाले परिवार।',
        '5 एकड़ या अधिक सिंचित भूमि अथवा 10 एकड़ असिंचित भूमि वाले परिवार।',
      ],
      documentRequirements: [
        'Aadhaar Card of each beneficiary family member.',
        'Ration Card (NFSA / BPL / AAY) or SECC 2011 Household Identification Letter (HH ID).',
        'Active mobile number for OTP e-KYC authentication.',
        'Ayushman Card (digital or PVC) generated via beneficiary.nha.gov.in or BIS portal.',
      ],
      documentRequirementsHindi: [
        'परिवार के प्रत्येक सदस्य का आधार कार्ड।',
        'राशन कार्ड (NFSA/BPL/AAY) अथवा SECC परिवार पहचान पत्र (HH ID)।',
        'ओटीपी प्रमाणीकरण हेतु सक्रिय मोबाइल नंबर।',
        'beneficiary.nha.gov.in अथवा BIS पोर्टल से जारी डिजिटल/पीवीसी आयुष्मान कार्ड।',
      ],
      applicationPrecautions: [
        'Hospital treatment MUST be taken in empaneled public or private network hospitals; treatment in un-empaneled hospitals is non-reimbursable.',
        'Admission must be for at least 24 hours (except specified daycare packages like dialysis, cataract, chemotherapy).',
        'Present your Ayushman Card at the hospital\'s Ayushman Mitra desk immediately upon admission.',
      ],
      applicationPrecautionsHindi: [
        'उपचार केवल सूचीबद्ध (Empaneled) सरकारी या निजी अस्पतालों में ही कैशलेस मान्य है; गैर-सूचीबद्ध में प्रतिपूर्ति नहीं मिलती।',
        'अस्पताल में न्यूनतम 24 घंटे की भर्ती अनिवार्य है (विशिष्ट डे-केयर प्रक्रियाओं जैसे डायलिसिस को छोड़कर)।',
        'भर्ती होते ही अस्पताल के "आयुष्मान मित्र" हेल्पडेस्क पर अपना आयुष्मान कार्ड प्रस्तुत करें।',
      ],
    ),

    // 3. PMAY-G
    'pmay_g': const SchemeNotesData(
      schemeId: 'pmay_g',
      criticalConditions: [
        'Rural homeless families or those living in zero, one, or two-room houses with kutcha walls and kutcha roof as per SECC 2011 / Awaas+ list.',
        'Financial assistance: ₹1,20,000 in plain areas, ₹1,30,000 in hilly/difficult/IAP areas disbursed directly in construction-linked tranches.',
        'Additional entitlement of 90/95 person-days of unskilled labor wages under MGNREGA (~₹20,000+).',
        'Additional ₹12,000 assistance for toilet construction under Swachh Bharat Mission - Gramin (SBM-G).',
      ],
      criticalConditionsHindi: [
        'SECC 2011 / आवास+ सूची के अनुसार बेघर अथवा शून्य, एक या दो कच्चे कमरों वाले ग्रामीण परिवार।',
        'आर्थिक सहायता: मैदानी क्षेत्रों में ₹1,20,000 तथा पहाड़ी/दुर्गम क्षेत्रों में ₹1,30,000 निर्माण चरणों से जुड़ी किस्तों में।',
        'मनरेगा के तहत 90/95 मानव दिवस की अकुशल मजदूरी का अतिरिक्त लाभ (~₹20,000+)।',
        'स्वच्छ भारत मिशन (ग्रामीण) के तहत शौचालय निर्माण हेतु ₹12,000 की अतिरिक्त सहायता।',
      ],
      disqualificationReasons: [
        'Ownership of motorized two/three/four wheelers, mechanized fishing boats, or tractors.',
        'Holding a Kisan Credit Card (KCC) with credit limit of ₹50,000 or higher.',
        'Household having at least one member as a government employee.',
        'Household with non-agricultural enterprises registered with the government.',
        'Any family member paying income tax or professional tax.',
        'Household owning a refrigerator or landline telephone.',
        'Owning 2.5 acres or more of irrigated land with irrigation equipment, or 5 acres unirrigated land.',
        'Family already owning a pucca house anywhere in India.',
      ],
      disqualificationReasonsHindi: [
        'मोटर चालित दो/तीन/चार पहिया वाहन, नाव या ट्रैक्टर का स्वामित्व।',
        '₹50,000 या अधिक क्रेडिट सीमा वाला किसान क्रेडिट कार्ड (KCC)।',
        'परिवार का कम से कम एक सदस्य सरकारी कर्मचारी हो।',
        'सरकार में पंजीकृत गैर-कृषि उद्यम।',
        'परिवार का कोई सदस्य आयकर या व्यावसायिक कर का भुगतान करता हो।',
        'रेफ्रिजरेटर या लैंडलाइन फोन का स्वामित्व।',
        'सिंचाई साधन सहित 2.5 एकड़ सिंचित अथवा 5 एकड़ असिंचित भूमि।',
        'भारत में कहीं भी पक्के मकान का पूर्व स्वामित्व।',
      ],
      documentRequirements: [
        'Aadhaar Card of the applicant and spouse.',
        'Active MGNREGA Job Card for crediting 90/95 days labor assistance.',
        'Bank Passbook of Aadhaar-seeded savings account.',
        'Land possession certificate / revenue ownership record or Gram Panchayat patta.',
        'Geo-tagged photographs of existing kutcha structure before commencement.',
      ],
      documentRequirementsHindi: [
        'आवेदक एवं पति/पत्नी का आधार कार्ड।',
        'मजदूरी सहायता प्राप्त करने हेतु सक्रिय मनरेगा जॉब कार्ड।',
        'आधार से जुड़े बचत बैंक खाते की पासबुक।',
        'भूमि स्वामित्व अभिलेख अथवा ग्राम पंचायत पट्टा।',
        'निर्माण कार्य प्रारंभ करने से पूर्व मौजूदा कच्चे घर की जियो-टैग्ड फोटो।',
      ],
      applicationPrecautions: [
        'Installment funds are released strictly after geo-tagged inspection (via AwaasApp) at plinth, lintel, and roof levels.',
        'House construction must be completed within 12 months with minimum carpet area of 25 sq. meters including a hygienic cooking space.',
        'Never pay cash commission or middleman fees; all DBT funds are transferred directly through PFMS.',
      ],
      applicationPrecautionsHindi: [
        'किस्तें आवास-ऐप द्वारा प्लिंथ, लिंटेल और छत स्तर पर जियो-टैग्ड सत्यापन के बाद ही जारी होती हैं।',
        'रसोई क्षेत्र सहित न्यूनतम 25 वर्ग मीटर क्षेत्रफल में 12 माह के भीतर निर्माण पूर्ण करना अनिवार्य है।',
        'किसी बिचौलिए को नकद राशि न दें; सभी भुगतान पीएफएमएस के जरिए सीधे खाते में आते हैं।',
      ],
    ),

    // 4. PMUY 2.0 (Ujjwala 2.0)
    'ujjwala': const SchemeNotesData(
      schemeId: 'ujjwala',
      criticalConditions: [
        'Applicant MUST be an adult woman aged 18 years or above.',
        'NO existing domestic LPG connection in the same household from any Oil Marketing Company (IOCL, BPCL, HPCL).',
        'Must belong to eligible categories: SC/ST, PMAY-G beneficiary, Antyodaya Anna Yojana (AAY), Most Backward Classes (MBC), Forest dwellers, or 14-Point Poor Household Declaration.',
        'Free first refill cylinder and ISI-certified hotplate (gas stove) provided with deposit-free connection.',
      ],
      criticalConditionsHindi: [
        'आवेदक अनिवार्य रूप से 18 वर्ष या उससे अधिक आयु की वयस्क महिला होनी चाहिए।',
        'उसी परिवार में किसी भी तेल कंपनी (IOCL, BPCL, HPCL) का कोई पूर्व घरेलू गैस कनेक्शन नहीं होना चाहिए।',
        'अनुसूचित जाति/जनजाति, पीएमएवाई-जी, अंत्योदय, वनवासी अथवा 14-सूत्रीय गरीब परिवार घोषणा के अंतर्गत होना चाहिए।',
        'जमानत-मुक्त कनेक्शन के साथ पहला सिलेंडर रीफिल तथा गैस चूल्हा निःशुल्क दिया जाता है।',
      ],
      disqualificationReasons: [
        'Male applicants (scheme is strictly reserved for adult women).',
        'Applicant age below 18 years on date of application.',
        'Any existing domestic LPG connection already active in the applicant\'s household.',
        'Applicant family not fitting any of the prescribed deprivation or affirmative categories.',
      ],
      disqualificationReasonsHindi: [
        'पुरुष आवेदक (यह योजना केवल वयस्क महिलाओं हेतु आरक्षित है)।',
        'आवेदन की तिथि पर आवेदक की आयु 18 वर्ष से कम होना।',
        'परिवार में किसी भी सदस्य के नाम पर पहले से घरेलू एलपीजी कनेक्शन होना।',
        'निर्धारित सामाजिक-आर्थिक वंचन श्रेणियों में न आना।',
      ],
      documentRequirements: [
        'Aadhaar Card of the adult woman applicant (e-KYC mandatory).',
        'Aadhaar Cards of all adult family members residing in the household.',
        'Ration Card or State Government Family Roster (or Annexure-I 14-point declaration for migrant workers without local proof).',
        'Active Bank Account Passbook with IFSC Code.',
        'Proof of Address (utility bill, voter ID, or migrant self-declaration).',
      ],
      documentRequirementsHindi: [
        'वयस्क महिला आवेदक का आधार कार्ड (ई-केवाईसी अनिवार्य)।',
        'परिवार में रहने वाले सभी वयस्क सदस्यों के आधार कार्ड।',
        'राशन कार्ड अथवा परिवार रजिस्टर नकल (प्रवासी परिवारों हेतु 14-सूत्रीय स्व-घोषणा अनुलग्नक-1)।',
        'आईएफएससी कोड सहित सक्रिय बैंक खाता पासबुक।',
        'पते का प्रमाण (बिजली/पानी बिल, वोटर आईडी अथवा प्रवासी घोषणा)।',
      ],
      applicationPrecautions: [
        'Migrant families do NOT need local state ration cards; Annexure-I self-declaration is officially permitted under Ujjwala 2.0.',
        'Ensure bank account is Aadhaar seeded for receiving continuous government LPG cylinder subsidies (PAHAL DBT).',
        'Submit application only through official distributors (Indane, Bharat Gas, HP Gas) or via pmuy.gov.in portal.',
      ],
      applicationPrecautionsHindi: [
        'प्रवासी परिवारों को स्थानीय राशन कार्ड की आवश्यकता नहीं है; 14-सूत्रीय घोषणा पत्र कानूनी रूप से मान्य है।',
        'निरंतर एलपीजी सब्सिडी (पहल डीबीटी) प्राप्त करने हेतु बैंक खाता आधार से लिंक होना आवश्यक है।',
        'केवल अधिकृत वितरकों या आधिकारिक pmuy.gov.in पोर्टल के माध्यम से ही आवेदन करें।',
      ],
    ),

    // 5. PMSS
    'pmss': const SchemeNotesData(
      schemeId: 'pmss',
      criticalConditions: [
        'Dependent wards and widows of Ex-Servicemen (ESM) / Ex-Coast Guard / CAPF personnel.',
        'Prioritized under defined priority categories (killed in action, disabled in action, died in harness, Gallantry awardees, ESM wards).',
        'Minimum 60% aggregate marks in the Minimum Entry Qualification (MEQ) (Class 12th / Diploma / Graduation as applicable).',
        'Admitted in the FIRST year of recognized professional degree course (BE/BTech, MBBS, BDS, B.Pharm, B.Sc Nursing, BCA, BBA, LLB).',
        'Scholarship amount: ₹3,000/month for girl students (₹36,000/year) and ₹2,500/month for boy students (₹30,000/year).',
      ],
      criticalConditionsHindi: [
        'पूर्व सैनिकों (ESM), पूर्व तटरक्षक और केंद्रीय सशस्त्र पुलिस बलों (CAPF) के आश्रित बच्चे एवं विधवाएं।',
        'निर्धारित प्राथमिकता श्रेणियों (शहीद, सेवा में दिव्यांग, वीरता पुरस्कार विजेता, पूर्व सैनिक आश्रित) में वर्गीकृत।',
        'न्यूनतम प्रवेश योग्यता (MEQ) (12वीं/डिप्लोमा/स्नातक) में न्यूनतम 60% कुल प्राप्तांक अनिवार्य।',
        'मान्यता प्राप्त व्यावसायिक डिग्री पाठ्यक्रम (BE/BTech, MBBS, BDS, B.Pharm, B.Sc Nursing आदि) के प्रथम वर्ष में प्रवेश।',
        'छात्रवृत्ति राशि: छात्राओं हेतु ₹3,000/माह (₹36,000/वर्ष) तथा छात्रों हेतु ₹2,500/माह (₹30,000/वर्ष)।',
      ],
      disqualificationReasons: [
        'Distance learning, correspondence, or part-time degree courses.',
        'Non-professional degree courses (plain BA, B.Sc, B.Com, MA, M.Com, M.Sc are ineligible).',
        'Scoring less than 60% marks in Class 12th / MEQ examination.',
        'Civilian students without bonafide defense/CAPF ESM parental service record.',
        'Availing another state or central government scholarship for the same educational course.',
        'Failing to score minimum 50% marks in annual exams for scholarship renewal.',
      ],
      disqualificationReasonsHindi: [
        'दूरस्थ शिक्षा, पत्राचार अथवा अंशकालिक डिग्री पाठ्यक्रम।',
        'गैर-व्यावसायिक डिग्री पाठ्यक्रम (सामान्य बीए, बीएससी, बीकॉम, एमए, एमकॉम अपात्र हैं)।',
        '12वीं अथवा न्यूनतम प्रवेश परीक्षा (MEQ) में 60% से कम अंक।',
        'बिना रक्षा/सीएपीएफ पूर्व सैनिक पारिवारिक पृष्ठभूमि वाले सामान्य नागरिक छात्र।',
        'उसी पाठ्यक्रम हेतु किसी अन्य केंद्रीय अथवा राज्य छात्रवृत्ति का लाभ लेना।',
        'नवीनीकरण हेतु विश्वविद्यालय वार्षिक परीक्षा में न्यूनतम 50% अंक प्राप्त न करना।',
      ],
      documentRequirements: [
        'Class 10th and 12th / MEQ Marksheet with official verification.',
        'ESM Discharge Book / PPO / CAPF Service & Identity Certificate.',
        'Bonafide Student Certificate issued by Registrar / Dean / Principal (Annexure-1).',
        'Certificate of MEQ Percentage issued by College (Annexure-2).',
        'Student\'s OWN single bank account passbook with IFSC code (joint accounts prohibited).',
      ],
      documentRequirementsHindi: [
        '10वीं एवं 12वीं / MEQ की सत्यापित अंकसूची।',
        'पूर्व सैनिक डिस्चार्ज बुक / पीपीओ / सीएपीएफ सेवा पहचान प्रमाण पत्र।',
        'कॉलेज रजिस्ट्रार/प्राचार्य द्वारा जारी बोनाफाइड प्रमाण पत्र (अनुलग्नक-1)।',
        'कॉलेज द्वारा प्रमाणित न्यूनतम प्रवेश योग्यता प्रतिशत प्रमाण पत्र (अनुलग्नक-2)।',
        'छात्र का अपना एकल (सिंगल) बैंक खाता पासबुक (संयुक्त खाता अमान्य है)।',
      ],
      applicationPrecautions: [
        'Application must be submitted exclusively on National Scholarship Portal (scholarships.gov.in).',
        'Bank account MUST be in the student\'s name alone; parents\' bank account causes permanent DBT rejection.',
        'Track institute verification and State Nodal Officer approval before NSP deadlines to prevent application lapse.',
      ],
      applicationPrecautionsHindi: [
        'आवेदन केवल राष्ट्रीय छात्रवृत्ति पोर्टल (scholarships.gov.in) पर ही स्वीकार्य है।',
        'बैंक खाता अनिवार्य रूप से केवल छात्र के नाम होना चाहिए; माता-पिता का खाता होने पर भुगतान निरस्त हो जाता है।',
        'अंतिम तिथि से पूर्व कॉलेज सत्यापन तथा राज्य नोडल अधिकारी सत्यापन की स्थिति पोर्टल पर ट्रैक करें।',
      ],
    ),

    // 6. MP Ladli Behna Yojana
    'ladli_behna': const SchemeNotesData(
      schemeId: 'ladli_behna',
      criticalConditions: [
        'Woman must be a permanent domicile/resident of Madhya Pradesh.',
        'Age criteria: Married women (including widows, divorced, and abandoned women) aged between 21 and 60 years.',
        'Financial assistance: ₹1,250 deposited monthly directly into beneficiary\'s bank account.',
        'Must possess active Samagra Family ID (8 digits) and Samagra Member ID (9 digits).',
        'Samagra e-KYC (Aadhaar linkage with biometrics or OTP) must be completed prior to application.',
      ],
      criticalConditionsHindi: [
        'महिला अनिवार्य रूप से मध्य प्रदेश की स्थायी मूल निवासी होनी चाहिए।',
        'आयु सीमा: 21 से 60 वर्ष की विवाहित महिलाएं (विधवा, तलाकशुदा एवं परित्यक्ता महिलाएं भी सम्मिलित)।',
        'वित्तीय सहायता: ₹1,250 प्रति माह सीधे लाभार्थी के बैंक खाते में जमा।',
        'सक्रिय 8-अंकीय समग्र परिवार आईडी और 9-अंकीय सदस्य आईडी होना अनिवार्य है।',
        'आवेदन से पूर्व समग्र पोर्टल पर आधार ई-केवाईसी (बायोमेट्रिक या ओटीपी) पूर्ण होना अनिवार्य।',
      ],
      disqualificationReasons: [
        'Combined annual family income exceeds ₹2,50,000 (₹2.5 Lakhs).',
        'Any family member is an active Income Tax payer.',
        'Any family member is employed as a regular/contractual employee in Central/State Government, Local Body, or PSU (Anganwadi, ASHA, Sahayika are exempted).',
        'Any family member receives monthly pension of ₹1,250 or more from any other government pension scheme.',
        'Any family member is a current or former MP, MLA, Mayor, or Zila Panchayat President.',
        'Family jointly or individually owns more than 5 acres (approx 2 hectares) of agricultural land.',
        'Family owns a four-wheeler motor vehicle (excluding agricultural tractors).',
      ],
      disqualificationReasonsHindi: [
        'परिवार की संयुक्त वार्षिक आय ₹2,50,000 (₹2.5 लाख) से अधिक होना।',
        'परिवार का कोई भी सदस्य आयकरदाता हो।',
        'परिवार का कोई सदस्य केंद्र/राज्य सरकार, निगम या उपक्रम में नियमित/संविदा कर्मचारी हो (आंगनवाड़ी, आशा, सहायिका को छूट)।',
        'परिवार का कोई सदस्य किसी अन्य सरकारी योजना से ₹1,250 या अधिक मासिक पेंशन प्राप्त कर रहा हो।',
        'परिवार का कोई सदस्य वर्तमान या पूर्व सांसद, विधायक, महापौर या जिला पंचायत अध्यक्ष हो।',
        'परिवार के पास संयुक्त या पृथक रूप से 5 एकड़ (लगभग 2 हेक्टेयर) से अधिक कृषि भूमि हो।',
        'परिवार के पास चार पहिया मोटर वाहन (कृषि ट्रैक्टर को छोड़कर) होना।',
      ],
      documentRequirements: [
        'Samagra Family ID (8 digits) and Samagra Member ID (9 digits).',
        'Applicant woman\'s Aadhaar Card.',
        'Single (individual) bank account passbook with active Aadhaar DBT link (Joint accounts prohibited).',
        'Mobile number registered with both Aadhaar and Samagra.',
        'Madhya Pradesh Domicile Certificate / proof of permanent residence.',
      ],
      documentRequirementsHindi: [
        'समग्र परिवार आईडी (8 अंक) और समग्र सदस्य आईडी (9 अंक)।',
        'आवेदक महिला का आधार कार्ड।',
        'सक्रिय आधार डीबीटी लिंक सहित महिला का स्वयं का एकल बैंक खाता (संयुक्त खाता अमान्य)।',
        'आधार और समग्र दोनों में पंजीकृत मोबाइल नंबर।',
        'मध्य प्रदेश मूल निवास प्रमाण पत्र।',
      ],
      applicationPrecautions: [
        'Bank account MUST be an individual account in the woman\'s name; joint accounts or husband\'s accounts are strictly rejected.',
        'Ensure Aadhaar-based NPCI DBT mapping is active at your bank branch before submitting application.',
        'Gram Panchayat and Ward level application camps are completely free; no agent fees are payable.',
      ],
      applicationPrecautionsHindi: [
        'बैंक खाता अनिवार्य रूप से महिला का व्यक्तिगत एकल खाता होना चाहिए; पति का या संयुक्त खाता पूरी तरह अमान्य है।',
        'आवेदन जमा करने से पहले बैंक शाखा में जाकर आधार एनपीसीआई डीबीटी सक्रियता सुनिश्चित करें।',
        'ग्राम पंचायत अथवा वार्ड स्तर पर आवेदन पूरी तरह निःशुल्क भरे जाते हैं; किसी बिचौलिए को शुल्क न दें।',
      ],
    ),
  };

  /// Fetch notes data for a scheme by ID
  static SchemeNotesData? getNotesForScheme(String schemeId) {
    final cleanId = schemeId.toLowerCase().trim();
    if (_notesMap.containsKey(cleanId)) {
      return _notesMap[cleanId];
    }
    for (final entry in _notesMap.entries) {
      if (cleanId.contains(entry.key) || entry.key.contains(cleanId)) {
        return entry.value;
      }
    }
    return null;
  }
}

