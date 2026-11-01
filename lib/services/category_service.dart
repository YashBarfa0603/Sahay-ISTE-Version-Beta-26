import 'package:flutter/material.dart';
import 'package:sahay/core/theme/app_colors.dart';
import 'package:sahay/models/category_model.dart';

/// Central authority for government scheme categories, canonical normalization,
/// localized titles, icons, and category-to-scheme relational matching.
class CategoryService {
  CategoryService._();

  static final List<CategoryModel> allCategories = [
    CategoryModel(
      categoryId: 'women-child',
      name: 'Women & Child Development',
      nameHindi: 'महिला एवं बाल विकास',
      description: 'Welfare schemes, maternal support, nutrition, and financial independence for women and girls.',
      descriptionHindi: 'महिलाओं और बालिकाओं के कल्याण, मातृत्व सहायता, पोषण और आर्थिक स्वावलंबन हेतु योजनाएं।',
      iconName: '👩',
      displayOrder: 1,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'agriculture',
      name: 'Agriculture & Farming',
      nameHindi: 'कृषि एवं किसान कल्याण',
      description: 'Crop insurance, income support, irrigation, farm credit, and input subsidies for farmers.',
      descriptionHindi: 'फसल बीमा, आय सहायता, सिंचाई, कृषि ऋण और किसानों के लिए आदान सब्सिडी।',
      iconName: '🌾',
      displayOrder: 2,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'education',
      name: 'Education & Scholarships',
      nameHindi: 'शिक्षा एवं छात्रवृत्ति',
      description: 'Pre-matric and post-matric scholarships, fee concessions, technical grants, and student assistance.',
      descriptionHindi: 'प्री-मैट्रिक एवं पोस्ट-मैट्रिक छात्रवृत्तियां, शुल्क प्रतिपूर्ति, तकनीकी अनुदान और छात्र सहायता।',
      iconName: '📚',
      displayOrder: 3,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'employment-skills',
      name: 'Employment & Skills',
      nameHindi: 'रोजगार एवं कौशल',
      description: 'Vocational skill development, apprentice schemes, self-employment assistance, and job support.',
      descriptionHindi: 'व्यावसायिक कौशल विकास, शिक्षुता योजनाएं, स्वरोजगार सहायता और रोजगार मार्गदर्शन।',
      iconName: '💼',
      displayOrder: 4,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'health',
      name: 'Health & Wellness',
      nameHindi: 'स्वास्थ्य एवं परिवार कल्याण',
      description: 'Cashless hospitalisation, critical illness coverage, health insurance, and maternal healthcare.',
      descriptionHindi: 'कैशलेस अस्पताल उपचार, गंभीर बीमारी सुरक्षा, स्वास्थ्य बीमा और मातृ स्वास्थ्य सुरक्षा।',
      iconName: '🏥',
      displayOrder: 5,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'housing',
      name: 'Housing & Shelter',
      nameHindi: 'आवास एवं पुनर्वास',
      description: 'Financial assistance for pucca house construction in rural and urban areas for homeless citizens.',
      descriptionHindi: 'ग्रामीण और शहरी क्षेत्रों में बेघर नागरिकों के लिए पक्का मकान निर्माण हेतु वित्तीय अनुदान।',
      iconName: '🏠',
      displayOrder: 6,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'social-security',
      name: 'Social Security & Pensions',
      nameHindi: 'सामाजिक सुरक्षा एवं पेंशन',
      description: 'Old-age pensions, widow pensions, disability support, and social welfare security nets.',
      descriptionHindi: 'वृद्धावस्था पेंशन, विधवा पेंशन, दिव्यांग सहायता और समग्र सामाजिक सुरक्षा छत्र।',
      iconName: '🤝',
      displayOrder: 7,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'finance',
      name: 'Financial Inclusion & Insurance',
      nameHindi: 'वित्तीय समावेशन एवं ऋण',
      description: 'Subsidized micro-credit, collateral-free business loans, pension insurance, and DBT benefits.',
      descriptionHindi: 'रियायती सूक्ष्म ऋण, संपार्श्विक-मुक्त व्यापार ऋण, पेंशन बीमा और डीबीटी लाभ।',
      iconName: '💰',
      displayOrder: 8,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'business',
      name: 'Business & MSME',
      nameHindi: 'व्यापार एवं उद्योग',
      description: 'Credit guarantees, technology upgrades, and working capital loans for small entrepreneurs.',
      descriptionHindi: 'छोटे उद्यमियों और व्यापारियों के लिए ऋण गारंटी, प्रौद्योगिकी उन्नयन और कार्यशील पूंजी।',
      iconName: '🏭',
      displayOrder: 9,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'rural-development',
      name: 'Rural Development',
      nameHindi: 'ग्रामीण विकास',
      description: 'Livelihood enhancement, rural roads, community assets, and self-help group programs.',
      descriptionHindi: 'आजीविका संवर्धन, ग्रामीण संपर्क, सामुदायिक परिसंपत्तियां और स्वयं सहायता समूह कार्यक्रम।',
      iconName: '🌱',
      displayOrder: 10,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'utilities',
      name: 'Utilities & Energy',
      nameHindi: 'जन सुविधाएं एवं ऊर्जा',
      description: 'Clean cooking gas connections, solar pump subsidies, electricity, and clean drinking water.',
      descriptionHindi: 'स्वच्छ रसोई गैस कनेक्शन, सोलर पंप सब्सिडी, ग्रामीण विद्युतीकरण और स्वच्छ पेयजल।',
      iconName: '⚡',
      displayOrder: 11,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'food-security',
      name: 'Food & Nutrition',
      nameHindi: 'खाद्य सुरक्षा एवं पोषण',
      description: 'Subsidized food grains, Antyodaya Anna distribution, and supplementary nutritional programs.',
      descriptionHindi: 'रियायती खाद्यान्न, अंत्योदय अन्न वितरण और आंगनवाड़ी पूरक पोषण कार्यक्रम।',
      iconName: '🍲',
      displayOrder: 12,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    CategoryModel(
      categoryId: 'tribal-welfare',
      name: 'Tribal Affairs',
      nameHindi: 'जनजातीय कल्याण',
      description: 'Forest rights, specialized educational residential complexes, and tribal development funds.',
      descriptionHindi: 'वनाधिकार पट्टे, एकलव्य आदर्श आवासीय विद्यालय और जनजातीय विकास निधि।',
      iconName: '🏹',
      displayOrder: 13,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  /// Normalize any incoming alias, legacy key, or display text to the canonical category ID
  static String normalizeCategory(String input) {
    final clean = input.trim().toLowerCase().replaceAll('_', '-').replaceAll(' ', '-');

    switch (clean) {
      case 'women':
      case 'women-child':
      case 'women-welfare':
      case 'womenwelfare':
      case 'woman':
      case 'child':
        return 'women-child';

      case 'agriculture':
      case 'farmer':
      case 'farming':
      case 'kisan':
        return 'agriculture';

      case 'education':
      case 'scholarship':
      case 'scholarships':
      case 'student':
        return 'education';

      case 'employment':
      case 'employment-skills':
      case 'employmentskills':
      case 'skill':
      case 'skills':
      case 'job':
        return 'employment-skills';

      case 'health':
      case 'healthcare':
      case 'medical':
      case 'hospital':
        return 'health';

      case 'housing':
      case 'shelter':
      case 'awas':
      case 'awaas':
        return 'housing';

      case 'socialwelfare':
      case 'social-welfare':
      case 'social-security':
      case 'socialsecurity':
      case 'pension':
      case 'pensions':
        return 'social-security';

      case 'financial':
      case 'finance':
      case 'banking':
      case 'credit':
      case 'loan':
        return 'finance';

      case 'business':
      case 'msme':
      case 'enterprise':
      case 'entrepreneur':
        return 'business';

      case 'rural':
      case 'rural-development':
      case 'ruraldevelopment':
      case 'gramin':
        return 'rural-development';

      case 'utilities':
      case 'utility':
      case 'energy':
      case 'power':
      case 'gas':
        return 'utilities';

      case 'food':
      case 'food-security':
      case 'foodsecurity':
      case 'ration':
        return 'food-security';

      case 'tribal':
      case 'tribal-welfare':
      case 'tribalwelfare':
      case 'adivasi':
        return 'tribal-welfare';

      default:
        // Check if input directly matches any canonical category
        for (final cat in allCategories) {
          if (cat.categoryId == clean || cat.name.toLowerCase() == clean) {
            return cat.categoryId;
          }
        }
        return clean;
    }
  }

  /// Relational check between a scheme's raw category string and a filter target
  static bool matchesCategory(String schemeCategory, String targetFilter) {
    if (targetFilter.trim().isEmpty || targetFilter.toLowerCase() == 'all') {
      return true;
    }
    final normScheme = normalizeCategory(schemeCategory);
    final normTarget = normalizeCategory(targetFilter);
    return normScheme == normTarget;
  }

  /// Fetch category metadata by ID
  static CategoryModel? getCategoryById(String categoryId) {
    final canonicalId = normalizeCategory(categoryId);
    try {
      return allCategories.firstWhere((c) => c.categoryId == canonicalId);
    } catch (_) {
      return null;
    }
  }

  /// Complete multilingual category display names for all 8 supported languages
  static const Map<String, Map<String, String>> _localizedCategoryNames = {
    'women-child': {
      'en': 'Women & Child Development',
      'hi': 'महिला एवं बाल विकास',
      'ta': 'பெண்கள் மற்றும் குழந்தைகள் மேம்பாடு',
      'mr': 'महिला व बाल विकास',
      'bn': 'মহিলা ও শিশু বিকাশ',
      'gu': 'મહિલા અને બાળ વિકાસ',
      'kn': 'ಮಹಿಳಾ ಮತ್ತು ಮಕ್ಕಳ ಅಭಿವೃದ್ಧಿ',
      'or': 'ମହିଳା ଓ ଶିଶୁ ବିକାଶ',
    },
    'agriculture': {
      'en': 'Agriculture & Farming',
      'hi': 'कृषि एवं किसान कल्याण',
      'ta': 'வேளாண்மை மற்றும் விவசாயிகள் நலன்',
      'mr': 'शेती आणि शेतकरी कल्याण',
      'bn': 'কৃষি ও কৃষক কল্যাণ',
      'gu': 'કૃષિ અને ખેડૂત કલ્યાણ',
      'kn': 'ಕೃಷಿ ಮತ್ತು ರೈತರ ಕಲ್ಯಾಣ',
      'or': 'କୃଷି ଏବଂ କୃଷକ କଲ୍ୟାଣ',
    },
    'education': {
      'en': 'Education & Scholarships',
      'hi': 'शिक्षा एवं छात्रवृत्ति',
      'ta': 'கல்வி மற்றும் உதவித்தொகை',
      'mr': 'शिक्षण आणि शिष्यवृत्ती',
      'bn': 'শিক্ষা ও বৃত্তি',
      'gu': 'શિક્ષણ અને શિષ્યવૃત્તિ',
      'kn': 'ಶಿಕ್ಷಣ ಮತ್ತು ವಿದ್ಯಾರ್ಥಿವೇತನ',
      'or': 'ଶିକ୍ଷା ଏବଂ ଛାତ୍ରବୃତ୍ତି',
    },
    'employment-skills': {
      'en': 'Employment & Skills',
      'hi': 'रोजगार एवं कौशल',
      'ta': 'வேலைவாய்ப்பு மற்றும் திறன் மேம்பாடு',
      'mr': 'रोजगार आणि कौशल्ये',
      'bn': 'কর্মসংস্থান ও দক্ষতা',
      'gu': 'રોજગાર અને કૌશલ્ય',
      'kn': 'ಉದ್ಯೋಗ ಮತ್ತು ಕೌಶಲ್ಯಗಳು',
      'or': 'ନିଯୁକ୍ତି ଏବଂ ଦକ୍ଷତା',
    },
    'health': {
      'en': 'Health & Wellness',
      'hi': 'स्वास्थ्य एवं परिवार कल्याण',
      'ta': 'சுகாதாரம் மற்றும் நல்வாழ்வு',
      'mr': 'आरोग्य आणि कुटुंब कल्याण',
      'bn': 'স্বাস্থ্য ও পরিবার কল্যাণ',
      'gu': 'આરોગ્ય અને પરિવાર કલ્યાણ',
      'kn': 'ಆರೋಗ್ಯ ಮತ್ತು ಕ್ಷೇಮ',
      'or': 'ସ୍ୱାସ୍ଥ୍ୟ ଏବଂ ପରିବାର କଲ୍ୟାଣ',
    },
    'housing': {
      'en': 'Housing & Shelter',
      'hi': 'आवास एवं पुनर्वास',
      'ta': 'வீட்டு வசதி மற்றும் தங்குமிடம்',
      'mr': 'गृहनिर्माण आणि निवारा',
      'bn': 'গৃহনির্মাণ ও আশ্রয়',
      'gu': 'આવાસ અને આશ્રય',
      'kn': 'ವಸತಿ ಮತ್ತು ಆಶ್ರಯ',
      'or': 'ଆବାସ ଏବଂ ଆଶ୍ରୟ',
    },
    'social-security': {
      'en': 'Social Security & Pensions',
      'hi': 'सामाजिक सुरक्षा एवं पेंशन',
      'ta': 'சமூகப் பாதுகாப்பு மற்றும் ஓய்வூதியம்',
      'mr': 'सामाजिक सुरक्षा आणि पेन्शन',
      'bn': 'সামাজিক নিরাপত্তা ও পেনশন',
      'gu': 'સામાજિક સુરક્ષા અને પેન્શન',
      'kn': 'ಸಾಮಾಜಿಕ ಭದ್ರತೆ ಮತ್ತು ಪಿಂಚಣಿ',
      'or': 'ସାମାଜିକ ସୁରକ୍ଷା ଏବଂ ପେନସନ',
    },
    'finance': {
      'en': 'Financial Inclusion & Insurance',
      'hi': 'वित्तीय समावेशन एवं ऋण',
      'ta': 'நிதிச் சேர்க்கை மற்றும் காப்பீடு',
      'mr': 'वित्तीय समावेशन आणि कर्ज',
      'bn': 'আর্থিক অন্তর্ভুক্তি ও বীমা',
      'gu': 'નાણાકીય સમાવેશ અને વીમો',
      'kn': 'ಹಣಕಾಸು ಸೇರ್ಪಡೆ ಮತ್ತು ವಿಮೆ',
      'or': 'ଆର୍ଥିକ ଅନ୍ତର୍ଭୁକ୍ତି ଏବଂ ବୀମା',
    },
    'business': {
      'en': 'Business & MSME',
      'hi': 'व्यापार एवं उद्योग',
      'ta': 'வணிகம் மற்றும் சிறுதொழில்',
      'mr': 'व्यापार आणि उद्योग',
      'bn': 'ব্যবসা ও এমএসএমই',
      'gu': 'વેપાર અને ઉદ્યોગ',
      'kn': 'ವ್ಯಾಪಾರ ಮತ್ತು ಸಣ್ಣ ಉದ್ಯಮ',
      'or': 'ବ୍ୟବସାୟ ଏବଂ ଏମଏସଏମଇ',
    },
    'rural-development': {
      'en': 'Rural Development',
      'hi': 'ग्रामीण विकास',
      'ta': 'ஊரக வளர்ச்சி',
      'mr': 'ग्रामीण विकास',
      'bn': 'গ্রামীণ উন্নয়ন',
      'gu': 'ગ્રામીણ વિકાસ',
      'kn': 'ಗ್ರಾಮೀಣಾಭಿವೃದ್ಧಿ',
      'or': 'ଗ୍ରାମ୍ୟ ଉନ୍ନୟନ',
    },
    'utilities': {
      'en': 'Utilities & Energy',
      'hi': 'जन सुविधाएं एवं ऊर्जा',
      'ta': 'பொதுப் பயன்பாடுகள் மற்றும் ஆற்றல்',
      'mr': 'नागरी सुविधा आणि ऊर्जा',
      'bn': 'ইউটিলিটি ও শক্তি',
      'gu': 'જન સુવિધાઓ અને ઊર્જા',
      'kn': 'ಸಾರ್ವಜನಿಕ ಸೌಲಭ್ಯಗಳು ಮತ್ತು ಶಕ್ತಿ',
      'or': 'ଜନ ସୁବିଧା ଏବଂ ଶକ୍ତି',
    },
    'food-security': {
      'en': 'Food & Nutrition',
      'hi': 'खाद्य सुरक्षा एवं पोषण',
      'ta': 'உணவு மற்றும் ஊட்டச்சத்து',
      'mr': 'अन्न सुरक्षा आणि पोषण',
      'bn': 'খাদ্য নিরাপত্তা ও পুষ্টি',
      'gu': 'ખાદ્ય સુરક્ષા અને પોષણ',
      'kn': 'ಆಹಾರ ಮತ್ತು ಪೋಷಣೆ',
      'or': 'ଖାଦ୍ୟ ସୁରକ୍ଷା ଏବଂ ପୋଷଣ',
    },
    'tribal-welfare': {
      'en': 'Tribal Affairs',
      'hi': 'जनजातीय कल्याण',
      'ta': 'பழங்குடியினர் நலன்',
      'mr': 'आदिवासी कल्याण',
      'bn': 'উপজাতি কল্যাণ',
      'gu': 'આદિજાતિ કલ્યાણ',
      'kn': 'ಬುಡಕಟ್ಟು ಕಲ್ಯಾಣ',
      'or': 'ଆଦିବାସୀ କଲ୍ୟାଣ',
    },
  };

  /// Complete multilingual category descriptions for all 8 supported languages
  static const Map<String, Map<String, String>> _localizedCategoryDescriptions = {
    'women-child': {
      'en': 'Maternity benefits, girl child welfare, nutritional support, and safety programs.',
      'hi': 'मातृत्व लाभ, बालिका सुरक्षा, पोषण आहार और महिला सशक्तिकरण कार्यक्रम।',
      'ta': 'மகப்பேறு நன்மைகள், பெண் குழந்தைகள் நலம், ஊட்டச்சத்து ஆதரவு மற்றும் பாதுகாப்பு திட்டங்கள்.',
      'mr': 'मातृत्व लाभ, बालिका सुरक्षा, पोषण आहार आणि महिला सक्षमीकरण कार्यक्रम.',
      'bn': 'মাতৃত্ব সুবিধা, কন্যাশিশু কল্যাণ, পুষ্টি সহায়তা এবং সুরক্ষা কর্মসূচি।',
      'gu': 'માતૃત્વ લાભ, બાળકી કલ્યાણ, પોષક સહાય અને મહિલા સશક્તિકરણ કાર્યક્રમો.',
      'kn': 'ತಾಯ್ತನದ ಪ್ರಯೋಜನಗಳು, ಹೆಣ್ಣು ಮಕ್ಕಳ ಕಲ್ಯಾಣ, ಪೌಷ್ಟಿಕಾಂಶ ಬೆಂಬಲ ಮತ್ತು ಸುರಕ್ಷತಾ ಕಾರ್ಯಕ್ರಮಗಳು.',
      'or': 'ମାତୃତ୍ୱ ଲାଭ, କନ୍ୟା ସନ୍ତାନ କଲ୍ୟାଣ, ପୋଷଣ ସହାୟତା ଏବଂ ସୁରକ୍ଷା କାର୍ଯ୍ୟକ୍ରମ।',
    },
    'agriculture': {
      'en': 'Crop insurance, income support, irrigation, farm credit, and input subsidies for farmers.',
      'hi': 'फसल बीमा, आय सहायता, सिंचाई, कृषि ऋण और किसानों के लिए आदान सब्सिडी।',
      'ta': 'பயிர் காப்பீடு, வருமான ஆதரவு, நீர்ப்பாசனம், பண்ணைக் கடன் மற்றும் விவசாயிகளுக்கான மானியங்கள்.',
      'mr': 'पीक विमा, उत्पन्न आधार, सिंचन, शेती कर्ज आणि शेतकऱ्यांसाठी अनुदाने.',
      'bn': 'ফসল বীমা, আয় সহায়তা, সেচ, কৃষি ঋণ এবং কৃষকদের জন্য উপকরণ ভর্তুকি।',
      'gu': 'પાક વીમો, આવક સહાય, સિંચાઈ, કૃષિ લોન અને ખેડૂતો માટે સબસિડી.',
      'kn': 'ಬೆಳೆ ವಿಮೆ, ಆದಾಯ ಬೆಂಬಲ, ನೀರಾವರಿ, ಕೃಷಿ ಸಾಲ ಮತ್ತು ರೈತರಿಗೆ ಸಬ್ಸಿಡಿಗಳು.',
      'or': 'ଫସଲ ବୀମା, ଆୟ ସହାୟତା, ଜଳସେଚନ, କୃଷି ଋଣ ଏବଂ କୃଷକମାନଙ୍କ ପାଇଁ ସବସିଡି।',
    },
    'education': {
      'en': 'Pre-matric and post-matric scholarships, fee concessions, technical grants, and student assistance.',
      'hi': 'प्री-मैट्रिक एवं पोस्ट-मैट्रिक छात्रवृत्तियां, शुल्क प्रतिपूर्ति, तकनीकी अनुदान और छात्र सहायता।',
      'ta': 'பள்ளி மற்றும் உயர் கல்வி உதவித்தொகை, கட்டணச் சலுகைகள் மற்றும் மாணவர் ஆதரவு.',
      'mr': 'मॅट्रिकपूर्व आणि मॅट्रिकोत्तर शिष्यवृत्ती, फी सवलत, तांत्रिक अनुदान आणि विद्यार्थी मदत.',
      'bn': 'প্রাক-ম্যাট্রিক ও পোস্ট-ম্যাট্রিক বৃত্তি, ফি মকুব এবং ছাত্র সহায়তা।',
      'gu': 'પ્રી-મેટ્રિક અને પોસ્ટ-મેટ્રિક શિષ્યવૃત્તિ, ફી માફી અને વિદ્યાર્થી સહાય.',
      'kn': 'ಮೆಟ್ರಿಕ್ ಪೂರ್ವ ಮತ್ತು ಮೆಟ್ರಿಕ್ ನಂತರದ ವಿದ್ಯಾರ್ಥಿವೇತನ, ಶುಲ್ಕ ರಿಯಾಯಿತಿ ಮತ್ತು ವಿದ್ಯಾರ್ಥಿ ನೆರವು.',
      'or': 'ପ୍ରାକ୍-ମେଟ୍ରିକ ଏବଂ ପୋଷ୍ଟ-ମେଟ୍ରିକ ଛାତ୍ରବୃତ୍ତି, ଫି ରିହାତି ଏବଂ ଛାତ୍ର ସହାୟତା।',
    },
    'employment-skills': {
      'en': 'Vocational skill development, apprentice schemes, self-employment assistance, and job support.',
      'hi': 'व्यावसायिक कौशल विकास, शिक्षुता योजनाएं, स्वरोजगार सहायता और रोजगार मार्गदर्शन।',
      'ta': 'தொழில் திறன் மேம்பாடு, பயிற்சித் திட்டங்கள், சுயதொழில் உதவி மற்றும் வேலைவாய்ப்பு ஆதரவு.',
      'mr': 'व्यावसायिक कौशल्य विकास, प्रशिक्षण योजना, स्वयंरोजगार मदत आणि नोकरी मार्गदर्शन.',
      'bn': 'বৃত্তিমূলক দক্ষতা বিকাশ, শিক্ষানবিশি প্রকল্প, স্ব-কর্মসংস্থান সহায়তা এবং চাকরি সহায়তা।',
      'gu': 'વ્યવસાયિક કૌશલ્ય વિકાસ, એપ્રેન્ટિસ યોજનાઓ, સ્વરોજગાર સહાય અને નોકરી માર્ગદર્શન.',
      'kn': 'ವೃತ್ತಿಪರ ಕೌಶಲ್ಯ ಅಭಿವೃದ್ಧಿ, ತರಬೇತಿ ಯೋಜನೆಗಳು, ಸ್ವಯಂ ಉದ್ಯೋಗ ನೆರವು ಮತ್ತು ಉದ್ಯೋಗ ಬೆಂಬಲ.',
      'or': 'ବୃତ୍ତିଗତ ଦକ୍ଷତା ବିକାଶ, ପ୍ରଶିକ୍ଷଣ ଯୋଜନା, ସ୍ୱ-ନିଯୁକ୍ତି ସହାୟତା ଏବଂ ନିଯୁକ୍ତି ମାର୍ଗଦର୍ଶନ।',
    },
    'health': {
      'en': 'Cashless hospitalisation, critical illness coverage, health insurance, and maternal healthcare.',
      'hi': 'कैशलेस अस्पताल उपचार, गंभीर बीमारी सुरक्षा, स्वास्थ्य बीमा और मातृ स्वास्थ्य सुरक्षा।',
      'ta': 'பணமில்லா மருத்துவமனை சிகிச்சை, தீவிர நோய் பாதுகாப்பு, மருத்துவக் காப்பீடு மற்றும் மகப்பேறு சுகாதாரம்.',
      'mr': 'कॅशलेस रुग्णालय उपचार, गंभीर आजार संरक्षण, आरोग्य विमा आणि मातृ आरोग्य सुरक्षा.',
      'bn': 'নগদহীন হাসপাতাল চিকিৎসা, জটিল রোগ কভারেজ, স্বাস্থ্য বীমা এবং মাতৃ স্বাস্থ্যসেবা।',
      'gu': 'કેશલેસ હોસ્પિટલ સારવાર, ગંભીર બીમારી કવરેજ, આરોગ્ય વીમો અને માતૃ આરોગ્ય સુરક્ષા.',
      'kn': 'ನಗದು ರಹಿತ ಆಸ್ಪತ್ರೆ ಚಿಕಿತ್ಸೆ, ಗಂಭೀರ ಅನಾರೋಗ್ಯ ರಕ್ಷಣೆ, ಆರೋಗ್ಯ ವಿಮೆ ಮತ್ತು ಮಾತೃ ಆರೋಗ್ಯ ರಕ್ಷಣೆ.',
      'or': 'ନଗଦବିହୀନ ଡାକ୍ତରଖାନା ଚିକିତ୍ସା, ଗୁରୁତର ରୋଗ ସୁରକ୍ଷା, ସ୍ୱାସ୍ଥ୍ୟ ବୀମା ଏବଂ ମାତୃ ସ୍ୱାସ୍ଥ୍ୟ ସୁରକ୍ଷା।',
    },
    'housing': {
      'en': 'Financial assistance for pucca house construction in rural and urban areas for homeless citizens.',
      'hi': 'ग्रामीण और शहरी क्षेत्रों में बेघर नागरिकों के लिए पक्का मकान निर्माण हेतु वित्तीय अनुदान।',
      'ta': 'வீடற்ற குடிமக்களுக்கு கிராமப்புற மற்றும் நகர்ப்புறங்களில் பக்கா வீடு கட்ட நிதி உதவி.',
      'mr': 'ग्रामीण आणि शहरी भागातील बेघर नागरिकांसाठी पक्के घर बांधण्यासाठी आर्थिक अनुदान.',
      'bn': 'গৃহহীন নাগরিকদের জন্য গ্রামীণ ও শহরাঞ্চলে পাকা বাড়ি তৈরির আর্থিক সহায়তা।',
      'gu': 'ગામડા અને શહેરી વિસ્તારોમાં બેઘર નાગરિકો માટે પાકું મકાન બનાવવા આર્થિક સહાય.',
      'kn': 'ಗ್ರಾಮೀಣ ಮತ್ತು ನಗರ ಪ್ರದೇಶಗಳಲ್ಲಿ ಮನೆ ರಹಿತ ನಾಗರಿಕರಿಗೆ ಪಕ್ಕಾ ಮನೆ ನಿರ್ಮಾಣಕ್ಕೆ ಆರ್ಥಿಕ ನೆರವು.',
      'or': 'ଗ୍ରାମୀଣ ଏବଂ ସହରାଞ୍ଚଳରେ ଗୃହହୀନ ନାଗରିକଙ୍କ ପାଇଁ ପକ୍କା ଘର ନିର୍ମାଣ ନିମନ୍ତେ ଆର୍ଥିକ ଅନୁଦାନ।',
    },
    'social-security': {
      'en': 'Old-age pensions, widow pensions, disability support, and social welfare security nets.',
      'hi': 'वृद्धावस्था पेंशन, विधवा पेंशन, दिव्यांग सहायता और समग्र सामाजिक सुरक्षा छत्र।',
      'ta': 'முதியோர் ஓய்வூதியம், விதவை ஓய்வூதியம், மாற்றுத்திறனாளிகள் உதவி மற்றும் சமூகப் பாதுகாப்பு வலைகள்.',
      'mr': 'वृद्धापकाळ पेन्शन, विधवा पेन्शन, दिव्यांग मदत आणि सर्वसमावेशक सामाजिक सुरक्षा.',
      'bn': 'বার্ধক্য পেনশন, বিধবা পেনশন, প্রতিবন্ধী সহায়তা এবং সামগ্রিক সামাজিক নিরাপত্তা ব্যবস্থা।',
      'gu': 'વૃદ્ધ પેન્શન, વિધવા પેન્શન, દિવ્યાંગ સહાય અને સામાજિક સુરક્ષા કવચ.',
      'kn': 'ವೃದ್ಧಾಪ್ಯ ಪಿಂಚಣಿ, ವಿಧವಾ ಪಿಂಚಣಿ, ಅಂಗವಿಕಲ ನೆರವು ಮತ್ತು ಸಾಮಾಜಿಕ ಭದ್ರತಾ ವ್ಯವಸ್ಥೆ.',
      'or': 'ବାର୍ଦ୍ଧକ୍ୟ ପେନସନ, ବିଧବା ପେନସନ, ଦିବ୍ୟାଙ୍ଗ ସହାୟତା ଏବଂ ସାମାଜିକ ସୁରକ୍ଷା ବ୍ୟବସ୍ଥା।',
    },
    'finance': {
      'en': 'Subsidized micro-credit, collateral-free business loans, pension insurance, and DBT benefits.',
      'hi': 'रियायती सूक्ष्म ऋण, संपार्श्विक-मुक्त व्यापार ऋण, पेंशन बीमा और डीबीटी लाभ।',
      'ta': 'மானியம் பெற்ற குறுங்கடன், பிணையில்லா வணிகக் கடன்கள் மற்றும் நேரடிப் பணப் பலன்கள்.',
      'mr': 'सवलतीचे सूक्ष्म कर्ज, तारणमुक्त व्यवसाय कर्ज, पेन्शन विमा आणि डीबीटी लाभ.',
      'bn': 'ভর্তুকিযুক্ত ক্ষুদ্র ঋণ, জামানতবিহীন ব্যবসায়িক ঋণ, পেনশন বীমা এবং ডিবিটি সুবিধা।',
      'gu': 'સબસિડીવાળી માઇક્રો-લોન, જામીનમુક્ત વ્યાપાર લોન, પેન્શન વીમો અને ડીબીટી લાભ.',
      'kn': 'ಸಬ್ಸಿಡಿ ಮೈಕ್ರೋ ಕ್ರೆಡಿಟ್, ಭದ್ರತೆಯಿಲ್ಲದ ವ್ಯಾಪಾರ ಸಾಲಗಳು, ಪಿಂಚಣಿ ವಿಮೆ ಮತ್ತು ಡಿಬಿಟಿ ಪ್ರಯೋಜನಗಳು.',
      'or': 'ରିହାତିଯୁକ୍ତ କ୍ଷୁଦ୍ର ଋଣ, ଜାମିନବିହୀନ ବ୍ୟବସାୟ ଋଣ, ପେନସନ ବୀମା ଏବଂ ଡିବିଟି ଲାଭ।',
    },
    'business': {
      'en': 'Credit guarantees, technology upgrades, and working capital loans for small entrepreneurs.',
      'hi': 'छोटे उद्यमियों और व्यापारियों के लिए ऋण गारंटी, प्रौद्योगिकी उन्नयन और कार्यशील पूंजी।',
      'ta': 'சிறு தொழில்முனைவோருக்கான கடன் உத்தரவாதங்கள், தொழில்நுட்ப மேம்பாடு மற்றும் மூலதனக் கடன்கள்.',
      'mr': 'लघु उद्योजकांसाठी कर्ज हमी, तंत्रज्ञान सुधारणा आणि खेळते भांडवल कर्ज.',
      'bn': 'ক্ষুদ্র উদ্যোক্তাদের জন্য ক্রেডিট গ্যারান্টি, প্রযুক্তি আপগ্রেড এবং চলতি মূলধন ঋণ।',
      'gu': 'નાના ઉદ્યોગસાહસિકો માટે લોન ગેરંટી, ટેકનોલોજી અપગ્રેડ અને કાર્યકારી મૂડી લોન.',
      'kn': 'ಸಣ್ಣ ಉದ್ಯಮಿಗಳಿಗೆ ಸಾಲ ಖಾತರಿ, ತಂತ್ರಜ್ಞಾನ ನವೀಕರಣ ಮತ್ತು ಕಾರ್ಯನಿರತ ಬಂಡವಾಳ ಸಾಲಗಳು.',
      'or': 'କ୍ଷୁଦ୍ର ଉଦ୍ୟୋଗୀମାନଙ୍କ ପାଇଁ ଋଣ ଗ୍ୟାରେଣ୍ଟି, ପ୍ରଯୁକ୍ତିବିଦ୍ୟା ଉନ୍ନୟନ ଏବଂ କାର୍ଯ୍ୟକାରୀ ପୁଞ୍ଜି ଋଣ।',
    },
    'rural-development': {
      'en': 'Livelihood enhancement, rural roads, community assets, and self-help group programs.',
      'hi': 'आजीविका संवर्धन, ग्रामीण संपर्क, सामुदायिक परिसंपत्तियां और स्वयं सहायता समूह कार्यक्रम।',
      'ta': 'வாழ்வாதார மேம்பாடு, கிராமப்புற சாலைகள், சமூக சொத்துக்கள் மற்றும் சுயஉதவி குழு திட்டங்கள்.',
      'mr': 'उपजीविका संवर्धन, ग्रामीण रस्ते, समुदाय मालमत्ता आणि बचत गट कार्यक्रम.',
      'bn': 'জীবিকা বৃদ্ধি, গ্রামীণ রাস্তা, সম্প্রদায়ের সম্পদ এবং স্বনির্ভর গোষ্ঠী কর্মসূচি।',
      'gu': 'આજીવિકા સંવર્ધન, ગ્રામીણ રસ્તાઓ, સામુદાયિક સંપત્તિ અને સ્વસહાય જૂથ કાર્યક્રમો.',
      'kn': 'ಜೀವನೋಪಾಯ ಸುಧಾರಣೆ, ಗ್ರಾಮೀಣ ರಸ್ತೆಗಳು, ಸಮುದಾಯ ಆಸ್ತಿಗಳು ಮತ್ತು ಸ್ವಸಹಾಯ ಗುಂಪು ಕಾರ್ಯಕ್ರಮಗಳು.',
      'or': 'ଜୀବିକା ସମ୍ବର୍ଦ୍ଧନ, ଗ୍ରାମ୍ୟ ରାସ୍ତା, ସାମୁଦାୟିକ ସମ୍ପତ୍ତି ଏବଂ ସ୍ୱୟଂ ସହାୟକ ଗୋଷ୍ଠୀ କାର୍ଯ୍ୟକ୍ରମ।',
    },
    'utilities': {
      'en': 'Clean cooking gas connections, solar pump subsidies, electricity, and clean drinking water.',
      'hi': 'स्वच्छ रसोई गैस कनेक्शन, सोलर पंप सब्सिडी, ग्रामीण विद्युतीकरण और स्वच्छ पेयजल।',
      'ta': 'தூய சமையல் எரிவாயு இணைப்பு, சூரிய பம்ப் மானியம், மின்சாரம் மற்றும் குடிநீர்.',
      'mr': 'स्वच्छ स्वयंपाकाचा गॅस कनेक्शन, सौर पंप अनुदान, वीज आणि स्वच्छ पिण्याचे पाणी.',
      'bn': 'পরিচ্ছন্ন রান্নার গ্যাস সংযোগ, সোলার পাম্প ভর্তুকি, বিদ্যুৎ এবং বিশুদ্ধ পানীয় জল।',
      'gu': 'સ્વચ્છ રાંધણ ગેસ કનેક્શન, સોલાર પંપ સબસિડી, વીજળી અને શુદ્ધ પીવાનું પાણી.',
      'kn': 'ಸ್ವಚ್ಛ ಅಡುಗೆ ಅನಿಲ ಸಂಪರ್ಕ, ಸೌರ ಪಂಪ್ ಸಬ್ಸಿಡಿ, ವಿದ್ಯುತ್ ಮತ್ತು ಶುದ್ಧ ಕುಡಿಯುವ ನೀರು.',
      'or': 'ସ୍ୱଚ୍ଛ ରନ୍ଧନ ଗ୍ୟାସ୍ ସଂଯୋଗ, ସୌର ପମ୍ପ ସବସିଡି, ବିଦ୍ୟୁତ୍ ଏବଂ ବିଶୁଦ୍ଧ ପାନୀୟ ଜଳ।',
    },
    'food-security': {
      'en': 'Subsidized food grains, Antyodaya Anna distribution, and supplementary nutritional programs.',
      'hi': 'रियायती खाद्यान्न, अंत्योदय अन्न वितरण और आंगनवाड़ी पूरक पोषण कार्यक्रम।',
      'ta': 'மானிய விலையில் உணவு தானியங்கள், அந்தியோதயா உணவு விநியோகம் மற்றும் சத்துணவு திட்டங்கள்.',
      'mr': 'सवलतीच्या दरात अन्नधान्य, अंत्योदय अन्न वितरण आणि पूरक पोषण कार्यक्रम.',
      'bn': 'ভর্তুকিযুক্ত খাদ্যশস্য, অন্ত্যোদয় অন্ন বিতরণ এবং পরিপূরক পুষ্টি কর্মসূচি।',
      'gu': 'સબસિડીવાળું અનાજ, અંત્યોદય અન્ન વિતરણ અને પૂરક પોષણ કાર્યક્રમો.',
      'kn': 'ಸಬ್ಸಿಡಿ ಆಹಾರ ಧಾನ್ಯಗಳು, ಅಂತ್ಯೋದಯ ಅನ್ನ ವಿತರಣೆ ಮತ್ತು ಪೂರಕ ಪೌಷ್ಟಿಕಾಂಶ ಕಾರ್ಯಕ್ರಮಗಳು.',
      'or': 'ରିହାତି ଖାଦ୍ୟଶସ୍ୟ, ଅନ୍ତ୍ୟୋଦୟ ଅନ୍ନ ବଣ୍ଟନ ଏବଂ ପୂରକ ପୋଷଣ କାର୍ଯ୍ୟକ୍ରମ।',
    },
    'tribal-welfare': {
      'en': 'Forest rights, specialized educational residential complexes, and tribal development funds.',
      'hi': 'वनाधिकार पट्टे, एकलव्य आदर्श आवासीय विद्यालय और जनजातीय विकास निधि।',
      'ta': 'வன உரிமைகள், பிரத்யேக உண்டு உறைவிடப் பள்ளிகள் மற்றும் பழங்குடியினர் மேம்பாட்டு நிதிகள்.',
      'mr': 'वनहक्क पट्टे, एकलव्य निवासी शाळा आणि आदिवासी विकास निधी.',
      'bn': 'বন অধিকার, বিশেষ আবাসিক বিদ্যালয় এবং উপজাতি উন্নয়ন তহবিল।',
      'gu': 'વન અધિકાર, વિશિષ્ટ શૈક્ષણિક રહેણાંક સંકુલ અને આદિજાતિ વિકાસ ભંડોળ.',
      'kn': 'ಅರಣ್ಯ ಹಕ್ಕುಗಳು, ಏಕಲವ್ಯ ವಸತಿ ಶಾಲೆಗಳು ಮತ್ತು ಬುಡಕಟ್ಟು ಅಭಿವೃದ್ಧಿ ನಿಧಿಗಳು.',
      'or': 'ଜଙ୍ଗଲ ଅଧିକାର, ଏକଲବ୍ୟ ଆଦର୍ଶ ଆବାସିକ ବିଦ୍ୟାଳୟ ଏବଂ ଜନଜାତି ବିକାଶ ପାଣ୍ଠି।',
    },
  };

  /// Get localized display name for a category across all 8 supported languages
  static String getCategoryName(String categoryId, [String languageCode = 'en']) {
    final canonicalId = normalizeCategory(categoryId);
    final lang = languageCode.toLowerCase();
    final localized = _localizedCategoryNames[canonicalId]?[lang];
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }
    final cat = getCategoryById(categoryId);
    if (cat == null) return categoryId;
    if (lang == 'hi' && cat.nameHindi != null) {
      return cat.nameHindi!;
    }
    return cat.name;
  }

  /// Convenience alias for getCategoryName
  static String getCategoryTitle(String categoryId, {String lang = 'en'}) {
    return getCategoryName(categoryId, lang);
  }

  /// Get localized description for a category across all 8 supported languages
  static String getCategoryDescription(String categoryId, {String lang = 'en'}) {
    final canonicalId = normalizeCategory(categoryId);
    final langCode = lang.toLowerCase();
    final localized = _localizedCategoryDescriptions[canonicalId]?[langCode];
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }
    final cat = getCategoryById(categoryId);
    if (cat == null) return '';
    if (langCode == 'hi' && cat.descriptionHindi != null) {
      return cat.descriptionHindi!;
    }
    return cat.description;
  }

  /// Visual theme accent color for each canonical category
  static Color getCategoryColor(String categoryId) {
    final canonical = normalizeCategory(categoryId);
    switch (canonical) {
      case 'agriculture':
        return AppColors.forestGreen;
      case 'health':
        return AppColors.mutedCoral;
      case 'housing':
        return AppColors.mutedAmber;
      case 'education':
        return AppColors.steelBlue;
      case 'women-child':
        return AppColors.mutedPurple;
      case 'employment-skills':
        return AppColors.deepNavy;
      case 'social-security':
        return AppColors.indianTeal;
      case 'finance':
        return AppColors.softSaffron;
      case 'business':
        return const Color(0xFF2C3E50);
      case 'rural-development':
        return const Color(0xFF27AE60);
      case 'utilities':
        return const Color(0xFFF39C12);
      case 'food-security':
        return const Color(0xFFE67E22);
      case 'tribal-welfare':
        return const Color(0xFF8E44AD);
      default:
        return AppColors.indianTeal;
    }
  }
}
