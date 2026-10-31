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
    if (languageCode.toLowerCase() == 'hi') {
      return nameHindi;
    }
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

  // Validity
  static bool isValidCode(String code) {
    final upper = code.trim().toUpperCase();
    return allStates.any((s) => s.code == upper);
  }
}

