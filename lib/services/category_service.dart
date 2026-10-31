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

  /// Get localized display name for a category
  static String getCategoryName(String categoryId, [String languageCode = 'en']) {
    final cat = getCategoryById(categoryId);
    if (cat == null) return categoryId;
    if (languageCode.toLowerCase() == 'hi' && cat.nameHindi != null) {
      return cat.nameHindi!;
    }
    return cat.name;
  }

  /// Convenience alias for getCategoryName
  static String getCategoryTitle(String categoryId, {String lang = 'en'}) {
    return getCategoryName(categoryId, lang);
  }

  /// Get localized description for a category
  static String getCategoryDescription(String categoryId, {String lang = 'en'}) {
    final cat = getCategoryById(categoryId);
    if (cat == null) return '';
    if (lang.toLowerCase() == 'hi' && cat.descriptionHindi != null) {
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
