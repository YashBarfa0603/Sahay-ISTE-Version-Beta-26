import 'package:sahay/models/youtube_tutorial_model.dart';

/// Service managing verified YouTube application guides and tutorial videos for schemes.
class YouTubeTutorialService {
  YouTubeTutorialService._();

  static final Map<String, YouTubeTutorialModel> _tutorials = {
    // 1. PM-KISAN Samman Nidhi
    'pm_kisan': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_kisan',
      videoId: 'yeINeVgyg9k',
      customUrl: 'https://www.youtube.com/watch?v=yeINeVgyg9k',
      videoTitle: 'PM Kisan Samman Nidhi Yojana Online Registration & e-KYC Complete Process',
      videoTitleHindi: 'पीएम किसान सम्मान निधि योजना में ऑनलाइन आवेदन एवं ई-केवाईसी कैसे करें',
      channelName: 'Digital Seva & Government Schemes',
      language: 'Hindi',
      duration: '10:24',
      description: 'Step-by-step registration process on pmkisan.gov.in with Aadhaar, land records, and DBT bank account.',
      descriptionHindi: 'आधार, खतौनी और डीबीटी बैंक खाते के साथ pmkisan.gov.in पर चरणबद्ध ऑनलाइन पंजीकरण प्रक्रिया।',
    ),

    // 2. Ayushman Bharat (PM-JAY)
    'pm_jay': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_jay',
      videoId: 'seOr_0myl2k',
      customUrl: 'https://youtu.be/seOr_0myl2k?si=yS6r5TuisKAAmjz5',
      videoTitle: 'How to Apply for Ayushman Card Online & Download Golden Card (PM-JAY)',
      videoTitleHindi: 'आयुष्मान कार्ड ऑनलाइन कैसे बनाएं और डाउनलोड करें (PM-JAY आयुष्मान भारत)',
      channelName: 'National Health Authority & Online Help',
      language: 'Hindi',
      duration: '11:15',
      description: 'Complete guide to create and download Ayushman Bharat card on beneficiary.nha.gov.in portal.',
      descriptionHindi: 'beneficiary.nha.gov.in पोर्टल पर आयुष्मान भारत गोल्डन कार्ड बनाने एवं डाउनलोड करने की पूरी प्रक्रिया।',
    ),

    // 3. Pradhan Mantri Awas Yojana (PMAY)
    'pmay_g': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pmay_g',
      videoId: 'iCtKY2qTUQ8',
      customUrl: 'https://youtu.be/iCtKY2qTUQ8?si=LLPlhkcUToPZJMBJ',
      videoTitle: 'Pradhan Mantri Awas Yojana (PMAY) Online Apply, Eligibility & Beneficiary List',
      videoTitleHindi: 'प्रधानमंत्री आवास योजना (PMAY) ऑनलाइन आवेदन, पात्रता और नई सूची देखें',
      channelName: 'Awas Yojana Official Portal Help',
      language: 'Hindi',
      duration: '9:40',
      description: 'Complete application guide for PMAY Gramin & Urban housing subsidy and status check.',
      descriptionHindi: 'पीएम आवास योजना ग्रामीण एवं शहरी आवास अनुदान के लिए ऑनलाइन आवेदन और सूची जांच।',
    ),

    // 4. PM Ujjwala Yojana
    'pm_ujjwala': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_ujjwala',
      videoId: 'gUTd57fTW6U',
      customUrl: 'https://youtu.be/gUTd57fTW6U?si=tzAgt6vfG08-j0uZ',
      videoTitle: 'Pradhan Mantri Ujjwala Yojana 2.0 Free Gas Connection Online Apply Process',
      videoTitleHindi: 'प्रधानमंत्री उज्ज्वला योजना 2.0 फ्री गैस कनेक्शन ऑनलाइन आवेदन प्रक्रिया',
      channelName: 'LPG Portal & Citizens Guidance',
      language: 'Hindi',
      duration: '8:30',
      description: 'How to apply for PM Ujjwala 2.0 free LPG connection, required documents and KYC form.',
      descriptionHindi: 'पीएम उज्ज्वला 2.0 के तहत मुफ्त एलपीजी गैस कनेक्शन के लिए ऑनलाइन आवेदन और आवश्यक दस्तावेज।',
    ),

    // 5. Mukhyamantri Ladli Behna Yojana (MP)
    'ladli_behna': YouTubeTutorialModel.fromVideoId(
      schemeId: 'ladli_behna',
      videoId: 'tOZ2VLMuiLY',
      customUrl: 'https://youtu.be/tOZ2VLMuiLY?si=ly_vYHufTiF0nyxW',
      videoTitle: 'Mukhyamantri Ladli Behna Yojana MP Online Form, e-KYC & Status Check',
      videoTitleHindi: 'मुख्यमंत्री लाडली बहना योजना ऑनलाइन फॉर्म, ई-केवाईसी और स्थिति जांचें',
      channelName: 'MP Online Official Help',
      language: 'Hindi',
      duration: '12:10',
      description: 'Complete Samagra e-KYC, Aadhaar DBT linking and online application guide for Ladli Behna.',
      descriptionHindi: 'लाडली बहना योजना के तहत समग्र ई-केवाईसी, आधार डीबीटी सीडिंग और आवेदन की पूरी जानकारी।',
    ),

    // 6. PM SVANidhi (Street Vendors)
    'pm_svanidhi': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_svanidhi',
      videoId: 'iO7Y-bCgon0',
      customUrl: 'https://youtu.be/iO7Y-bCgon0?si=C_0lXvFMx2m-7tpb',
      videoTitle: 'PM SVANidhi Loan Online Application Process for Street Vendors (Step-by-Step)',
      videoTitleHindi: 'पीएम स्वनिधि योजना ऋण ऑनलाइन आवेदन प्रक्रिया (रेहड़ी-पटरी विक्रेताओं के लिए)',
      channelName: 'MSME & Urban Livelihoods Hub',
      language: 'Hindi',
      duration: '8:45',
      description: 'Apply for ₹10,000, ₹20,000 and ₹50,000 collateral-free working capital loan on pmsvanidhi.mohua.gov.in.',
      descriptionHindi: 'pmsvanidhi.mohua.gov.in पर ₹10,000 से ₹50,000 तक बिना गारंटी कार्यशील पूंजी ऋण आवेदन प्रक्रिया।',
    ),

    // 7. Sukanya Samriddhi Yojana
    'sukanya_samriddhi': YouTubeTutorialModel.fromVideoId(
      schemeId: 'sukanya_samriddhi',
      videoId: 'bXwcnF-nn_M',
      customUrl: 'https://youtu.be/bXwcnF-nn_M?si=Y0hgEqzVl5-2vxEk',
      videoTitle: 'Sukanya Samriddhi Yojana Account Opening Process, Form Fill-up & Benefits',
      videoTitleHindi: 'सुकन्या समृद्धि योजना खाता कैसे खोलें, फॉर्म भरने का तरीका और नियम',
      channelName: 'India Post & Financial Awareness',
      language: 'Hindi',
      duration: '10:50',
      description: 'Step-by-step Sukanya Samriddhi account opening form filling at Post Office or Bank for girl child.',
      descriptionHindi: 'पोस्ट ऑफिस या बैंक में बालिकाओं के लिए सुकन्या समृद्धि खाता खोलने का फॉर्म भरने और ब्याज की पूरी जानकारी।',
    ),

    // 8. PM Vishwakarma Yojana
    'pm_vishwakarma': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_vishwakarma',
      videoId: 'S5uwhpLisXQ',
      customUrl: 'https://youtu.be/S5uwhpLisXQ?si=Arw2VirQijl_kH3m',
      videoTitle: 'PM Vishwakarma Yojana Online Registration, Free Tool Kit & Loan Process',
      videoTitleHindi: 'पीएम विश्वकर्मा योजना ऑनलाइन रजिस्ट्रेशन, फ्री टूलकिट ₹15,000 और लोन प्रक्रिया',
      channelName: 'Skill India & MSME Guidance',
      language: 'Hindi',
      duration: '13:25',
      description: 'CSC center registration, 18 traditional trades eligibility, ₹15,000 toolkit voucher and loan steps.',
      descriptionHindi: 'सीएससी के माध्यम से पीएम विश्वकर्मा रजिस्ट्रेशन, ₹15,000 टूलकिट सहायता और ₹3 लाख तक ऋण प्रक्रिया।',
    ),
  };

  /// Mapping table supporting all database canonical scheme IDs, prefixes, and variations
  static const Map<String, String> _idAliases = {
    // 1. PM-KISAN
    'pm_kisan_001': 'pm_kisan',
    'pmkisan_001': 'pm_kisan',
    'pmkisan': 'pm_kisan',
    'pm_kisan': 'pm_kisan',
    'kisan': 'pm_kisan',

    // 2. Ayushman Bharat / PM-JAY
    'ayushman_001': 'pm_jay',
    'ayushman': 'pm_jay',
    'ayushman_bharat': 'pm_jay',
    'pmjay_002': 'pm_jay',
    'pm_jay_002': 'pm_jay',
    'pm_jay': 'pm_jay',
    'pmjay': 'pm_jay',

    // 3. Pradhan Mantri Awas Yojana
    'pmay_001': 'pmay_g',
    'pmay_002': 'pmay_g',
    'pmay_g_003': 'pmay_g',
    'pmay_g': 'pmay_g',
    'pmay': 'pmay_g',
    'awas': 'pmay_g',
    'pm_awas': 'pmay_g',

    // 4. PM Ujjwala Yojana
    'pm_ujjwala_001': 'pm_ujjwala',
    'pmuy_004': 'pm_ujjwala',
    'pm_ujjwala': 'pm_ujjwala',
    'pm_ujwala': 'pm_ujjwala',
    'ujjwala': 'pm_ujjwala',
    'ujwala': 'pm_ujjwala',

    // 5. Ladli Behna Yojana (MP)
    'mp_ladli_behna_001': 'ladli_behna',
    'ladli_behna_001': 'ladli_behna',
    'ladli_behna': 'ladli_behna',
    'ladli_bahna': 'ladli_behna',
    'ladli': 'ladli_behna',

    // 6. PM SVANidhi
    'pm_svanidhi_001': 'pm_svanidhi',
    'pm_svanidhi': 'pm_svanidhi',
    'svanidhi': 'pm_svanidhi',
    'svanidhi_001': 'pm_svanidhi',

    // 7. Sukanya Samriddhi
    'sukanya_samriddhi_001': 'sukanya_samriddhi',
    'sukanya_samriddhi': 'sukanya_samriddhi',
    'sukanya': 'sukanya_samriddhi',
    'ssy': 'sukanya_samriddhi',

    // 8. PM Vishwakarma
    'pm_vishwakarma_001': 'pm_vishwakarma',
    'pm_vishwakarma': 'pm_vishwakarma',
    'vishwakarma': 'pm_vishwakarma',
    'vishwakarma_001': 'pm_vishwakarma',
  };

  /// Returns the verified YouTube tutorial model for a given scheme ID if available.
  /// Resolves both internal IDs ('pm_kisan') and catalogue IDs ('PM_KISAN_001', 'AYUSHMAN_001', etc.).
  static YouTubeTutorialModel? getTutorialForScheme(String schemeId) {
    if (schemeId.trim().isEmpty) return null;

    final cleanId = schemeId.trim().toLowerCase().replaceAll('-', '_');

    // 1. Direct match in _tutorials
    if (_tutorials.containsKey(cleanId)) {
      return _tutorials[cleanId];
    }

    // 2. Exact alias match in _idAliases
    final aliasTarget = _idAliases[cleanId];
    if (aliasTarget != null && _tutorials.containsKey(aliasTarget)) {
      return _tutorials[aliasTarget];
    }

    // 3. Substring / Token fallback matching (e.g., 'PM_KISAN_001' containing 'pm_kisan')
    for (final entry in _idAliases.entries) {
      if (cleanId.contains(entry.key) || entry.key.contains(cleanId)) {
        final target = entry.value;
        if (_tutorials.containsKey(target)) {
          return _tutorials[target];
        }
      }
    }

    return null;
  }

  /// Check whether a verified tutorial exists for a scheme ID
  static bool hasTutorial(String schemeId) {
    return getTutorialForScheme(schemeId) != null;
  }

  /// Get all available tutorials
  static List<YouTubeTutorialModel> getAllTutorials() {
    return List.unmodifiable(_tutorials.values);
  }
}
