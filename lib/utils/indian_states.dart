// States
class IndianState {
  final String code;
  final String nameEnglish;
  final String nameHindi;

  const IndianState({
    required this.code,
    required this.nameEnglish,
    required this.nameHindi,
  });

  String getLocalizedName(String languageCode) {
    final lang = languageCode.toLowerCase();
    if (lang == 'hi') return nameHindi;
    if (lang == 'en') return nameEnglish;
    final localized = IndianStates.getLocalizedNameByLang(code, lang);
    if (localized != null && localized.isNotEmpty) return localized;
    return nameEnglish;
  }
}

// State repository
class IndianStates {
  IndianStates._();

  // All States & UTs matching catalogue codes
  static const List<IndianState> allStates = [
    IndianState(code: 'AN', nameEnglish: 'Andaman and Nicobar Islands', nameHindi: 'अंडमान और निकोबार द्वीप समूह'),
    IndianState(code: 'AP', nameEnglish: 'Andhra Pradesh', nameHindi: 'आंध्र प्रदेश'),
    IndianState(code: 'AR', nameEnglish: 'Arunachal Pradesh', nameHindi: 'अरुणाचल प्रदेश'),
    IndianState(code: 'AS', nameEnglish: 'Assam', nameHindi: 'असम'),
    IndianState(code: 'BR', nameEnglish: 'Bihar', nameHindi: 'बिहार'),
    IndianState(code: 'CH', nameEnglish: 'Chandigarh', nameHindi: 'चंडीगढ़'),
    IndianState(code: 'CG', nameEnglish: 'Chhattisgarh', nameHindi: 'छत्तीसगढ़'),
    IndianState(code: 'DN', nameEnglish: 'Dadra and Nagar Haveli', nameHindi: 'दादरा और नगर हवेली'),
    IndianState(code: 'DD', nameEnglish: 'Daman and Diu', nameHindi: 'दमन और दीव'),
    IndianState(code: 'DL', nameEnglish: 'Delhi (NCT)', nameHindi: 'दिल्ली (राष्ट्रीय राजधानी क्षेत्र)'),
    IndianState(code: 'GA', nameEnglish: 'Goa', nameHindi: 'गोवा'),
    IndianState(code: 'GJ', nameEnglish: 'Gujarat', nameHindi: 'गुजरात'),
    IndianState(code: 'HR', nameEnglish: 'Haryana', nameHindi: 'हरियाणा'),
    IndianState(code: 'HP', nameEnglish: 'Himachal Pradesh', nameHindi: 'हिमाचल प्रदेश'),
    IndianState(code: 'JK', nameEnglish: 'Jammu and Kashmir', nameHindi: 'जम्मू और कश्मीर'),
    IndianState(code: 'JH', nameEnglish: 'Jharkhand', nameHindi: 'झारखंड'),
    IndianState(code: 'KA', nameEnglish: 'Karnataka', nameHindi: 'कर्नाटक'),
    IndianState(code: 'KL', nameEnglish: 'Kerala', nameHindi: 'केरल'),
    IndianState(code: 'LA', nameEnglish: 'Ladakh', nameHindi: 'लद्दाख'),
    IndianState(code: 'LD', nameEnglish: 'Lakshadweep', nameHindi: 'लक्षद्वीप'),
    IndianState(code: 'MP', nameEnglish: 'Madhya Pradesh', nameHindi: 'मध्य प्रदेश'),
    IndianState(code: 'MH', nameEnglish: 'Maharashtra', nameHindi: 'महाराष्ट्र'),
    IndianState(code: 'MN', nameEnglish: 'Manipur', nameHindi: 'मणिपुर'),
    IndianState(code: 'ML', nameEnglish: 'Meghalaya', nameHindi: 'मेघालय'),
    IndianState(code: 'MZ', nameEnglish: 'Mizoram', nameHindi: 'मिज़ोरम'),
    IndianState(code: 'NL', nameEnglish: 'Nagaland', nameHindi: 'नागालैंड'),
    IndianState(code: 'OD', nameEnglish: 'Odisha', nameHindi: 'ओडिशा'),
    IndianState(code: 'PY', nameEnglish: 'Puducherry', nameHindi: 'पुडुचेरी'),
    IndianState(code: 'PB', nameEnglish: 'Punjab', nameHindi: 'पंजाब'),
    IndianState(code: 'RJ', nameEnglish: 'Rajasthan', nameHindi: 'राजस्थान'),
    IndianState(code: 'SK', nameEnglish: 'Sikkim', nameHindi: 'सिक्किम'),
    IndianState(code: 'TN', nameEnglish: 'Tamil Nadu', nameHindi: 'तमिलनाडु'),
    IndianState(code: 'TS', nameEnglish: 'Telangana', nameHindi: 'तेलंगाना'),
    IndianState(code: 'TR', nameEnglish: 'Tripura', nameHindi: 'त्रिपुरा'),
    IndianState(code: 'UP', nameEnglish: 'Uttar Pradesh', nameHindi: 'उत्तर प्रदेश'),
    IndianState(code: 'UK', nameEnglish: 'Uttarakhand', nameHindi: 'उत्तराखंड'),
    IndianState(code: 'WB', nameEnglish: 'West Bengal', nameHindi: 'पश्चिम बंगाल'),
  ];

  // Lookup
  static IndianState? findByCode(String code) {
    final upper = code.trim().toUpperCase();
    try {
      return allStates.firstWhere((s) => s.code == upper);
    } catch (_) {
      return null;
    }
  }

  // Localized name
  static String getName(String code, [String lang = 'en']) {
    final state = findByCode(code);
    if (state == null) return code;
    return state.getLocalizedName(lang);
  }

  // Aliases
  static List<IndianState> get states => allStates;
  static String getStateName(String code, [String lang = 'en']) => getName(code, lang);

  // Multilingual State Names across all 8 supported languages
  static const Map<String, Map<String, String>> _localizedStateNames = {
    'AN': {
      'ta': 'அந்தமான் நிக்கோபார் தீவுகள்',
      'mr': 'अंदमान आणि निकोबार बेटे',
      'bn': 'আন্দামান ও নিকোবর দ্বীপপুঞ্জ',
      'gu': 'અંદમાન અને નિકોબાર દ્વીપસમૂહ',
      'kn': 'ಅಂಡಮಾನ್ ಮತ್ತು ನಿಕೋಬಾರ್ ದ್ವೀಪಗಳು',
      'or': 'ଆଣ୍ଡାମାନ ଏବଂ ନିକୋବର ଦ୍ୱୀପପୁଞ୍ଜ',
    },
    'AP': {
      'ta': 'ஆந்திரப் பிரதேசம்',
      'mr': 'आंध्र प्रदेश',
      'bn': 'অন্ধ্রপ্রদেশ',
      'gu': 'આંધ્ર પ્રદેશ',
      'kn': 'ಆಂಧ್ರಪ್ರದೇಶ',
      'or': 'ଆନ୍ଧ୍ରପ୍ରଦେଶ',
    },
    'AR': {
      'ta': 'அருணாச்சலப் பிரதேசம்',
      'mr': 'अरुणाचल प्रदेश',
      'bn': 'অরুণাচল প্রদেশ',
      'gu': 'અરુણાચલ પ્રદેશ',
      'kn': 'ಅರುಣಾಚಲ ಪ್ರದೇಶ',
      'or': 'ଅରୁଣାଚଳ ପ୍ରଦେଶ',
    },
    'AS': {
      'ta': 'அசாம்',
      'mr': 'आसाम',
      'bn': 'আসাম',
      'gu': 'આસામ',
      'kn': 'ಅಸ್ಸಾಂ',
      'or': 'ଆସାମ',
    },
    'BR': {
      'ta': 'பீகார்',
      'mr': 'बिहार',
      'bn': 'বিহার',
      'gu': 'બિહાર',
      'kn': 'ಬಿಹಾರ',
      'or': 'ବିହାର',
    },
    'CH': {
      'ta': 'சண்டிகர்',
      'mr': 'चंदिगढ',
      'bn': 'চণ্ডীগড়',
      'gu': 'ચંદીગઢ',
      'kn': 'ಚಂಡೀಗಢ',
      'or': 'ଚଣ୍ଡିଗଡ଼',
    },
    'CG': {
      'ta': 'சத்தீஸ்கர்',
      'mr': 'छत्तीसगड',
      'bn': 'ছত্তিশগড়',
      'gu': 'છત્તીસગઢ',
      'kn': 'ಛತ್ತೀಸ್‌ಗಢ',
      'or': 'ଛତିଶଗଡ଼',
    },
    'DN': {
      'ta': 'தாத்ரா மற்றும் நகர் ஹவேலி',
      'mr': 'दादरा आणि नगर हवेली',
      'bn': 'দাদরা ও নগর হাভেলি',
      'gu': 'દાદરા અને નગર હવેલી',
      'kn': 'ದಾದ್ರಾ ಮತ್ತು ನಗರ ಹವೇಲಿ',
      'or': 'ଦାଦ୍ରା ଏବଂ ନଗର ହାବେଳି',
    },
    'DD': {
      'ta': 'டாமன் மற்றும் டையூ',
      'mr': 'दमन आणि दीव',
      'bn': 'দমন ও দিউ',
      'gu': 'દમણ અને દીવ',
      'kn': 'ದಮನ್ ಮತ್ತು ದಿಯು',
      'or': 'ଦମନ ଏବଂ ଦିଉ',
    },
    'DL': {
      'ta': 'தில்லி (தேசிய தலைநகர் பகுதி)',
      'mr': 'दिल्ली (राष्ट्रीय राजधानी क्षेत्र)',
      'bn': 'দিল্লি (জাতীয় রাজধানী অঞ্চল)',
      'gu': 'દિલ્હી (રાષ્ટ્રીય રાજધાની પ્રદેશ)',
      'kn': 'ದೆಹಲಿ (ರಾಷ್ಟ್ರೀಯ ರಾಜಧಾನಿ ಪ್ರದೇಶ)',
      'or': 'ଦିଲ୍ଲୀ (ଜାତୀୟ ରାଜଧାନୀ ଅଞ୍ଚଳ)',
    },
    'GA': {
      'ta': 'கோவா',
      'mr': 'गोवा',
      'bn': 'গোয়া',
      'gu': 'ગોવા',
      'kn': 'ಗೋವಾ',
      'or': 'ଗୋଆ',
    },
    'GJ': {
      'ta': 'குஜராத்',
      'mr': 'गुजरात',
      'bn': 'গুজরাট',
      'gu': 'ગુજરાત',
      'kn': 'ಗುಜರಾತ್',
      'or': 'ଗୁଜରାଟ',
    },
    'HR': {
      'ta': 'ஹரியானா',
      'mr': 'हरियाणा',
      'bn': 'হরিয়ানা',
      'gu': 'હરિયાણા',
      'kn': 'ಹರಿಯಾಣ',
      'or': 'ହରିୟାଣା',
    },
    'HP': {
      'ta': 'இமாச்சலப் பிரதேசம்',
      'mr': 'हिमाचल प्रदेश',
      'bn': 'হিমাচল প্রদেশ',
      'gu': 'હિમાચલ પ્રદેશ',
      'kn': 'ಹಿಮಾಚಲ ಪ್ರದೇಶ',
      'or': 'ହିମାଚଳ ପ୍ରଦେଶ',
    },
    'JK': {
      'ta': 'ஜம்மு காஷ்மீர்',
      'mr': 'जम्मू आणि काश्मीर',
      'bn': 'জম্মু ও কাশ্মীর',
      'gu': 'જમ્મુ અને કાશ્મીર',
      'kn': 'ಜಮ್ಮು ಮತ್ತು ಕಾಶ್ಮೀರ',
      'or': 'ଜମ୍ମୁ ଏବଂ କାଶ୍ମୀର',
    },
    'JH': {
      'ta': 'ஜார்க்கண்ட்',
      'mr': 'झारखंड',
      'bn': 'ঝাড়খণ্ড',
      'gu': 'ઝારખંડ',
      'kn': 'ಜಾರ್ಖಂಡ್',
      'or': 'ଝାଡ଼ଖଣ୍ଡ',
    },
    'KA': {
      'ta': 'கர்நாடகா',
      'mr': 'कर्नाटक',
      'bn': 'কর্ণাটক',
      'gu': 'કર્ણાટક',
      'kn': 'ಕರ್ನಾಟಕ',
      'or': 'କର୍ଣ୍ଣାଟକ',
    },
    'KL': {
      'ta': 'கேரளா',
      'mr': 'केरळ',
      'bn': 'কেরল',
      'gu': 'કેરળ',
      'kn': 'ಕೇರಳ',
      'or': 'କେରଳ',
    },
    'LA': {
      'ta': 'லடாக்',
      'mr': 'लडाख',
      'bn': 'লাদাখ',
      'gu': 'લદ્દાખ',
      'kn': 'ಲಡಾಖ್',
      'or': 'ଲଦାଖ',
    },
    'LD': {
      'ta': 'லட்சத்தீவு',
      'mr': 'लक्षद्वीप',
      'bn': 'লক্ষদ্বীপ',
      'gu': 'લક્ષદ્વીપ',
      'kn': 'ಲಕ್ಷದ್ವೀಪ',
      'or': 'ଲାକ୍ଷାଦ୍ୱୀପ',
    },
    'MP': {
      'ta': 'மத்தியப் பிரதேசம்',
      'mr': 'मध्य प्रदेश',
      'bn': 'মধ্যপ্রদেশ',
      'gu': 'મધ્ય પ્રદેશ',
      'kn': 'ಮಧ್ಯಪ್ರದೇಶ',
      'or': 'ମଧ୍ୟପ୍ରଦେଶ',
    },
    'MH': {
      'ta': 'மகாராஷ்டிரா',
      'mr': 'महाराष्ट्र',
      'bn': 'মহারাষ্ট্র',
      'gu': 'મહારાષ્ટ્ર',
      'kn': 'ಮಹಾರಾಷ್ಟ್ರ',
      'or': 'ମହାରାଷ୍ଟ୍ର',
    },
    'MN': {
      'ta': 'மணிப்பூர்',
      'mr': 'मणिपूर',
      'bn': 'মণিপুর',
      'gu': 'મણિપુર',
      'kn': 'ಮಣಿಪುರ',
      'or': 'ମଣିପୁର',
    },
    'ML': {
      'ta': 'மேகாலயா',
      'mr': 'मेघालय',
      'bn': 'মেঘালয়',
      'gu': 'મેઘાલય',
      'kn': 'ಮೇಘಾಲಯ',
      'or': 'ମେଘାଳୟ',
    },
    'MZ': {
      'ta': 'மிசோரம்',
      'mr': 'मिझोराम',
      'bn': 'মিজোরাম',
      'gu': 'મિઝોરમ',
      'kn': 'ಮಿಜೋರಾಂ',
      'or': 'ମିଜୋରାମ',
    },
    'NL': {
      'ta': 'நாகாலாந்து',
      'mr': 'नागालँड',
      'bn': 'নাগাল্যান্ড',
      'gu': 'નાગાલેન્ડ',
      'kn': 'ನಾಗಾಲ್ಯಾಂಡ್',
      'or': 'ନାଗାଲାଣ୍ଡ',
    },
    'OD': {
      'ta': 'ஒடிசா',
      'mr': 'ओडिशा',
      'bn': 'ওড়িশা',
      'gu': 'ઓડિશા',
      'kn': 'ಒಡಿಶಾ',
      'or': 'ଓଡ଼ିଶା',
    },
    'PY': {
      'ta': 'புதுச்சேரி',
      'mr': 'पुडुचेरी',
      'bn': 'পুদুচেরি',
      'gu': 'પુડુચેરી',
      'kn': 'ಪುದುಚೇರಿ',
      'or': 'ପୁଡୁଚେରୀ',
    },
    'PB': {
      'ta': 'பஞ்சாப்',
      'mr': 'पंजाब',
      'bn': 'পাঞ্জাব',
      'gu': 'પંજાબ',
      'kn': 'ಪಂಜಾಬ್',
      'or': 'ପଞ୍ଜାବ',
    },
    'RJ': {
      'ta': 'ராஜஸ்தான்',
      'mr': 'राजस्थान',
      'bn': 'রাজস্থান',
      'gu': 'રાજસ્થાન',
      'kn': 'ರಾಜಸ್ಥಾನ',
      'or': 'ରାଜସ୍ଥାନ',
    },
    'SK': {
      'ta': 'சிக்கிம்',
      'mr': 'सिक्कीम',
      'bn': 'সিকিম',
      'gu': 'સિક્કિમ',
      'kn': 'ಸಿಕ್ಕಿಂ',
      'or': 'ସିକିମ୍',
    },
    'TN': {
      'ta': 'தமிழ்நாடு',
      'mr': 'तमिळनाडू',
      'bn': 'তামিলনাড়ু',
      'gu': 'તમિલનાડુ',
      'kn': 'ತಮಿಳುನಾಡು',
      'or': 'ତାମିଲନାଡୁ',
    },
    'TS': {
      'ta': 'தெலங்கானா',
      'mr': 'तेलंगणा',
      'bn': 'তেলেঙ্গানা',
      'gu': 'તેલંગાણા',
      'kn': 'ತೆಲಂಗಾಣ',
      'or': 'ତେଲେଙ୍ଗାନା',
    },
    'TR': {
      'ta': 'திரிபுரா',
      'mr': 'त्रिपुरा',
      'bn': 'ত্রিপুরা',
      'gu': 'ત્રિપુરા',
      'kn': 'ತ್ರಿಪುರ',
      'or': 'ତ୍ରିପୁରା',
    },
    'UP': {
      'ta': 'உத்தரப் பிரதேசம்',
      'mr': 'उत्तर प्रदेश',
      'bn': 'উত্তরপ্রদেশ',
      'gu': 'ઉત્તર પ્રદેશ',
      'kn': 'ಉತ್ತರ ಪ್ರದೇಶ',
      'or': 'ଉତ୍ତର ପ୍ରଦେଶ',
    },
    'UK': {
      'ta': 'உத்தரகண்ட்',
      'mr': 'उत्तराखंड',
      'bn': 'উত্তরাখণ্ড',
      'gu': 'ઉત્તરાખંડ',
      'kn': 'ಉತ್ತರಾಖಂಡ',
      'or': 'ଉତ୍ତରାଖଣ୍ଡ',
    },
    'WB': {
      'ta': 'மேற்கு வங்காளம்',
      'mr': 'पश्चिम बंगाल',
      'bn': 'পশ্চিমবঙ্গ',
      'gu': 'પશ્ચિમ બંગાળ',
      'kn': 'ಪಶ್ಚಿಮ ಬಂಗಾಳ',
      'or': 'ପଶ୍ଚିମ ବଙ୍ଗ',
    },
  };

  /// Lookup localized name by language code
  static String? getLocalizedNameByLang(String code, String lang) {
    final upper = code.trim().toUpperCase();
    return _localizedStateNames[upper]?[lang.toLowerCase()];
  }

  // Validity
  static bool isValidCode(String code) {
    final upper = code.trim().toUpperCase();
    return allStates.any((s) => s.code == upper);
  }
}

