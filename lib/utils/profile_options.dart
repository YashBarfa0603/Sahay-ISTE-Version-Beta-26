// Options
class OptionItem {
  final String key;
  final Map<String, String> labels;

  const OptionItem({
    required this.key,
    required this.labels,
  });

  String getLabel(String languageCode) {
    return labels[languageCode.toLowerCase()] ?? labels['en'] ?? key;
  }
}

// Profile options
class ProfileOptions {
  ProfileOptions._();

  // 13 Canonical Occupations matching catalogue seed
  static const List<OptionItem> occupations = [
    OptionItem(
      key: 'farmer',
      labels: {
        'en': 'Farmer / Cultivator',
        'hi': 'किसान / काश्तकार',
        'ta': 'விவசாயி / பயிரிடுபவர்',
        'mr': 'शेतकरी / कास्तकार',
        'bn': 'কৃষক / চাষী',
        'gu': 'ખેડૂત / કૃષિકાર',
        'kn': 'ರೈತ / ಕೃಷಿಕ',
        'or': 'କୃଷକ / ଚାଷୀ',
      },
    ),
    OptionItem(
      key: 'agricultural_worker',
      labels: {
        'en': 'Agricultural Worker / Laborer',
        'hi': 'कृषि मजदूर / खेत श्रमिक',
        'ta': 'விவசாய கூலித் தொழிலாளி',
        'mr': 'शेतमजूर / कृषी कामगार',
        'bn': 'কৃষি শ্রমিক / দিনমজুর',
        'gu': 'ખેતમજૂર / કૃષિ શ્રમિક',
        'kn': 'ಕೃಷಿ ಕಾರ್ಮಿಕ',
        'or': 'କୃଷି ଶ୍ରମିକ',
      },
    ),
    OptionItem(
      key: 'unorganized_worker',
      labels: {
        'en': 'Unorganized / Informal Worker',
        'hi': 'असंगठित क्षेत्र का कामगार',
        'ta': 'அமைப்புசாரா தொழிலாளி',
        'mr': 'असंघटित कामगार',
        'bn': 'অসংগঠিত শ্রমিক',
        'gu': 'અસંગઠિત ક્ષેત્રના શ્રમિક',
        'kn': 'ಅಸಂಘಟಿತ ಕಾರ್ಮಿಕ',
        'or': 'ଅଣସଂଗଠିତ ଶ୍ରମିକ',
      },
    ),
    OptionItem(
      key: 'construction_worker',
      labels: {
        'en': 'Construction Worker',
        'hi': 'भवन एवं निर्माण श्रमिक',
        'ta': 'கட்டுமானத் தொழிலாளி',
        'mr': 'बांधकाम कामगार',
        'bn': 'নির্মাণ শ্রমিক',
        'gu': 'બાંધકામ શ્રમિક',
        'kn': 'ಕಟ್ಟಡ ನಿರ್ಮಾಣ ಕಾರ್ಮಿಕ',
        'or': 'ନିର୍ମାଣ ଶ୍ରମିକ',
      },
    ),
    OptionItem(
      key: 'street_vendor',
      labels: {
        'en': 'Street Vendor / Hawker',
        'hi': 'स्ट्रीट वेंडर / फेरीवाला',
        'ta': 'தெருவோர வியாபாரி',
        'mr': 'फेरीवाला / पथविक्रेता',
        'bn': 'হকার / পথবিক্রেতা',
        'gu': 'શેરી ફેરિયો / લારીવાળા',
        'kn': 'ಬೀದಿ ಬದಿ ವ್ಯಾಪಾರಿ',
        'or': 'ଉଠାଦୋକାନୀ / ଫେରିବାଲା',
      },
    ),
    OptionItem(
      key: 'artisan_craftsperson',
      labels: {
        'en': 'Artisan / Craftsperson',
        'hi': 'कारीगर / शिल्पकार',
        'ta': 'கைவினைஞர் / கலைஞர்',
        'mr': 'कारागीर / शिल्पकार',
        'bn': 'কারিগর / শিল্পী',
        'gu': 'કારીગર / શિલ્પકાર',
        'kn': 'ಕುಶಲಕರ್ಮಿ',
        'or': 'କାରିଗର / ଶିଳ୍ପୀ',
      },
    ),
    OptionItem(
      key: 'student',
      labels: {
        'en': 'Student',
        'hi': 'विद्यार्थी / छात्र',
        'ta': 'மாணவர்',
        'mr': 'विद्यार्थी',
        'bn': 'ছাত্র / ছাত্রী',
        'gu': 'વિદ્યાર્થી',
        'kn': 'ವಿದ್ಯಾರ್ಥಿ',
        'or': 'ଛାତ୍ର / ଛାତ୍ରୀ',
      },
    ),
    OptionItem(
      key: 'salaried_private',
      labels: {
        'en': 'Salaried (Private Sector)',
        'hi': 'वेतनभोगी (निजी क्षेत्र)',
        'ta': 'தனியார் துறை ஊழியர்',
        'mr': 'वेतनधारक (खाजगी क्षेत्र)',
        'bn': 'বেসরকারি চাকুরিজীবী',
        'gu': 'પગારદાર (ખાનગી ક્ષેત્ર)',
        'kn': 'ಖಾಸಗಿ ನೌಕರ',
        'or': 'ବେସରକାରୀ ଚାକିରିଆ',
      },
    ),
    OptionItem(
      key: 'government_employee',
      labels: {
        'en': 'Government Employee / PSU',
        'hi': 'सरकारी कर्मचारी / उपक्रम',
        'ta': 'அரசு ஊழியர்',
        'mr': 'शासकीय कर्मचारी',
        'bn': 'সরকারি চাকুরিজীবী',
        'gu': 'સરકારી કર્મચારી',
        'kn': 'ಸರ್ಕಾರಿ ನೌಕರ',
        'or': 'ସରକାରୀ କର୍ମଚାରୀ',
      },
    ),
    OptionItem(
      key: 'self_employed_business',
      labels: {
        'en': 'Self-Employed / Business',
        'hi': 'स्वरोजगार / व्यापारी',
        'ta': 'சுயதொழில் / வணிகர்',
        'mr': 'स्वयंरोजगार / व्यापारी',
        'bn': 'স্বনির্ভর / ব্যবসায়ী',
        'gu': 'સ્વરોજગાર / વેપારી',
        'kn': 'ಸ್ವಯಂ ಉದ್ಯೋಗಿ / ವ್ಯಾಪಾರಿ',
        'or': 'ସ୍ୱନିୟୋଜିତ / ବ୍ୟବସାୟୀ',
      },
    ),
    OptionItem(
      key: 'homemaker',
      labels: {
        'en': 'Homemaker',
        'hi': 'गृहिणी',
        'ta': 'குடும்பத்தலைவி',
        'mr': 'गृहिणी',
        'bn': 'গৃহিনী',
        'gu': 'ગૃહિણી',
        'kn': 'ಗೃಹಿಣಿ',
        'or': 'ଗୃହିଣୀ',
      },
    ),
    OptionItem(
      key: 'unemployed',
      labels: {
        'en': 'Unemployed / Job Seeker',
        'hi': 'बेरोजगार / कार्य तलाशकर्ता',
        'ta': 'வேலையற்றோர்',
        'mr': 'बेरोजगार / नोकरी शोधक',
        'bn': 'কর্মহীন / বেকার',
        'gu': 'બેરોજગાર',
        'kn': 'ನಿರುದ್ಯೋಗಿ',
        'or': 'ବେକାର / କାର୍ଯ୍ୟାଭିଳାଷୀ',
      },
    ),
    OptionItem(
      key: 'retired',
      labels: {
        'en': 'Retired / Senior Citizen',
        'hi': 'सेवानिवृत्त / वरिष्ठ नागरिक',
        'ta': 'ஓய்வு பெற்றவர் / மூத்த குடிமகன்',
        'mr': 'सेवानिवृत्त / ज्येष्ठ नागरिक',
        'bn': 'অবসরপ্রাপ্ত / প্রবীণ নাগরিক',
        'gu': 'નિવૃત્ત / વરિષ્ઠ નાગરિક',
        'kn': 'ನಿವೃತ್ತ / ಹಿರಿಯ ನಾಗರಿಕ',
        'or': 'ଅବସରପ୍ରାପ୍ତ / ବରିଷ୍ଠ ନାଗରିକ',
      },
    ),
  ];

  // Gender
  static const List<OptionItem> genders = [
    OptionItem(
      key: 'female',
      labels: {
        'en': 'Female',
        'hi': 'महिला',
        'ta': 'பெண்',
        'mr': 'स्त्री',
        'bn': 'মহিলা',
        'gu': 'મહિલા',
        'kn': 'ಮಹಿಳೆ',
        'or': 'ମହିଳା',
      },
    ),
    OptionItem(
      key: 'male',
      labels: {
        'en': 'Male',
        'hi': 'पुरुष',
        'ta': 'ஆண்',
        'mr': 'पुरुष',
        'bn': 'পুরুষ',
        'gu': 'પુરુષ',
        'kn': 'ಪುರುಷ',
        'or': 'ପୁରୁଷ',
      },
    ),
    OptionItem(
      key: 'other',
      labels: {
        'en': 'Transgender / Other',
        'hi': 'किन्नर / अन्य',
        'ta': 'திருநங்கை / இதர',
        'mr': 'तृतीयपंथी / इतर',
        'bn': 'রূপান্তরকামী / অন্যান্য',
        'gu': 'ટ્રાન્સજેન્ડર / અન્ય',
        'kn': 'ತೃತೀಯಲಿಂಗಿ / ಇತರೆ',
        'or': 'ତୃତୀୟଲିଙ୍ଗୀ / ଅନ୍ୟାନ୍ୟ',
      },
    ),
    OptionItem(
      key: 'preferNotToSay',
      labels: {
        'en': 'Prefer not to say',
        'hi': 'बताना नहीं चाहते',
        'ta': 'கூற விரும்பவில்லை',
        'mr': 'सांगू इच्छित नाही',
        'bn': 'বলতে ইচ্ছুক নই',
        'gu': 'જણાવવા માંગતા નથી',
        'kn': 'ಹೇಳಲು ಇಷ್ಟವಿಲ್ಲ',
        'or': 'କହିବାକୁ ଚାହୁଁନାହାଁନ୍ତି',
      },
    ),
  ];

  // Residence
  static const List<OptionItem> residenceTypes = [
    OptionItem(
      key: 'rural',
      labels: {
        'en': 'Rural (Village / Gram Panchayat)',
        'hi': 'ग्रामीण (गाँव / ग्राम पंचायत)',
        'ta': 'கிராமப்புறம்',
        'mr': 'ग्रामीण',
        'bn': 'গ্রামীণ',
        'gu': 'ગ્રામીણ',
        'kn': 'ಗ್ರಾಮೀಣ',
        'or': 'ଗ୍ରାମାଞ୍ଚଳ',
      },
    ),
    OptionItem(
      key: 'urban',
      labels: {
        'en': 'Urban (City / Municipality)',
        'hi': 'शहरी (शहर / नगरपालिका)',
        'ta': 'நகர்ப்புறம்',
        'mr': 'शहरी',
        'bn': 'শহুরে',
        'gu': 'શહેરી',
        'kn': 'ನಗರ',
        'or': 'ସହରାଞ୍ଚଳ',
      },
    ),
  ];

  // Lookups
  static String getOccupationLabel(String key, [String lang = 'en']) {
    try {
      final item = occupations.firstWhere((o) => o.key == key);
      return item.getLabel(lang);
    } catch (_) {
      return key;
    }
  }

  static String getGenderLabel(String key, [String lang = 'en']) {
    try {
      final item = genders.firstWhere((g) => g.key == key);
      return item.getLabel(lang);
    } catch (_) {
      return key;
    }
  }

  static String getResidenceLabel(String key, [String lang = 'en']) {
    try {
      final item = residenceTypes.firstWhere((r) => r.key == key);
      return item.getLabel(lang);
    } catch (_) {
      return key;
    }
  }
}

