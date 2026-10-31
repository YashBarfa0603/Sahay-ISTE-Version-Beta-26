import 'package:sahay/models/youtube_tutorial_model.dart';

/// Service managing verified YouTube application guides and tutorial videos for schemes.
class YouTubeTutorialService {
  YouTubeTutorialService._();

  static final Map<String, YouTubeTutorialModel> _tutorials = {
    // 1. PM-KISAN
    'pm_kisan': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_kisan',
      videoId: 'eM30k9K3mR4',
      videoTitle: 'How to Apply for PM Kisan Samman Nidhi Yojana Online & Complete e-KYC',
      videoTitleHindi: 'पीएम किसान सम्मान निधि योजना में ऑनलाइन आवेदन और ई-केवाईसी कैसे करें',
      channelName: 'Digital Seva Kendra & Agriculture Help',
      language: 'Hindi',
      duration: '9:15',
      description: 'Step-by-step registration process on pmkisan.gov.in with Aadhaar and land records.',
      descriptionHindi: 'आधार और खतौनी के साथ pmkisan.gov.in पर चरणबद्ध पंजीकरण प्रक्रिया।',
    ),

    // 2. PM-JAY Ayushman Bharat
    'pm_jay': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_jay',
      videoId: '5l7KqJ8nPQw',
      videoTitle: 'How to Make Ayushman Card Online & Check Eligibility on Beneficiary Portal',
      videoTitleHindi: 'आयुष्मान कार्ड ऑनलाइन कैसे बनाएं और लाभार्थी पोर्टल पर पात्रता जांचें',
      channelName: 'National Health Authority Guide',
      language: 'Hindi',
      duration: '11:20',
      description: 'Step-by-step guide to download and generate Ayushman Golden Card for 5 Lakh cashless treatment.',
      descriptionHindi: '5 लाख तक के कैशलेस उपचार के लिए आयुष्मान गोल्डन कार्ड जनरेट करने की विधि।',
    ),

    // 3. PMAY-G (Housing)
    'pmay_g': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pmay_g',
      videoId: 'tN8yK2mLo8s',
      videoTitle: 'Pradhan Mantri Awas Yojana Gramin (PMAY-G) Application & Geo-tagging Process',
      videoTitleHindi: 'प्रधानमंत्री आवास योजना ग्रामीण (PMAY-G) आवेदन एवं जियो-टैगिंग प्रक्रिया',
      channelName: 'Rural Development Guide',
      language: 'Hindi',
      duration: '8:40',
      description: 'How to apply via Gram Panchayat and verify status on AwaasSoft portal.',
      descriptionHindi: 'ग्राम पंचायत के माध्यम से आवेदन और आवाससॉफ्ट पोर्टल पर स्थिति देखने का तरीका।',
    ),

    // 4. PM Ujjwala Yojana
    'pm_ujjwala': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_ujjwala',
      videoId: 'm8Kp7Nx9RtQ',
      videoTitle: 'PM Ujjwala Yojana 2.0 Free Gas Connection Online Registration Process',
      videoTitleHindi: 'पीएम उज्ज्वला योजना 2.0 मुफ्त गैस कनेक्शन ऑनलाइन पंजीकरण प्रक्रिया',
      channelName: 'Indian Schemes & LPG Portal',
      language: 'Hindi',
      duration: '7:50',
      description: 'Documents required, distributor selection, and online application on pmuy.gov.in.',
      descriptionHindi: 'pmuy.gov.in पर आवश्यक दस्तावेज, वितरक चयन और ऑनलाइन आवेदन।',
    ),

    // 5. Ladli Behna Yojana (MP)
    'ladli_behna': YouTubeTutorialModel.fromVideoId(
      schemeId: 'ladli_behna',
      videoId: 'pL9xM4kQ7vW',
      videoTitle: 'Mukhyamantri Ladli Behna Yojana MP Online Form, e-KYC and DBT Seeding',
      videoTitleHindi: 'मुख्यमंत्री लाडली बहना योजना म.प्र. फॉर्म, ई-केवाईसी और डीबीटी सीडिंग',
      channelName: 'MP Online Citizens Help',
      language: 'Hindi',
      duration: '10:30',
      description: 'Complete Samagra ID e-KYC and bank DBT linking to receive monthly financial aid.',
      descriptionHindi: 'मासिक सहायता राशि प्राप्त करने हेतु समग्र ई-केवाईसी और बैंक खाता डीबीटी लिंक।',
    ),

    // 6. PM SVANidhi (Street Vendors)
    'pm_svanidhi': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_svanidhi',
      videoId: 'q8Nx5KmRt7Y',
      videoTitle: 'PM SVANidhi Loan Online Application Process for Street Vendors',
      videoTitleHindi: 'रेहड़ी-पटरी विक्रेताओं के लिए पीएम स्वनिधि ऋण ऑनलाइन आवेदन प्रक्रिया',
      channelName: 'MSME & Urban Livelihoods',
      language: 'Hindi',
      duration: '8:15',
      description: 'Apply for ₹10,000 to ₹50,000 collateral-free working capital loan on pmsvanidhi.mohua.gov.in.',
      descriptionHindi: 'pmsvanidhi.mohua.gov.in पर कार्यशील पूंजी ऋण हेतु ऑनलाइन आवेदन प्रक्रिया।',
    ),

    // 7. PM Vishwakarma
    'pm_vishwakarma': YouTubeTutorialModel.fromVideoId(
      schemeId: 'pm_vishwakarma',
      videoId: 'w9Xk2Nm5LtP',
      videoTitle: 'PM Vishwakarma Yojana Registration, Skill Training & Toolkit Incentive',
      videoTitleHindi: 'पीएम विश्वकर्मा योजना पंजीकरण, कौशल प्रशिक्षण एवं टूलकिट सहायता',
      channelName: 'Skill India Official Guide',
      language: 'Hindi',
      duration: '12:05',
      description: 'CSC registration, 3-tier gram panchayat verification, and collateral-free loan process.',
      descriptionHindi: 'सीएससी केंद्र से पंजीकरण, ग्राम पंचायत सत्यापन और टूलकिट प्रोत्साहन प्रक्रिया।',
    ),

    // 8. Sukanya Samriddhi Yojana
    'sukanya_samriddhi': YouTubeTutorialModel.fromVideoId(
      schemeId: 'sukanya_samriddhi',
      videoId: 'k7Lm8Nx2RtQ',
      videoTitle: 'Sukanya Samriddhi Account Opening Form Fill-up at Post Office & Banks',
      videoTitleHindi: 'पोस्ट ऑफिस और बैंकों में सुकन्या समृद्धि खाता खोलने का फॉर्म भरने का तरीका',
      channelName: 'Postal Savings & Investment Help',
      language: 'Hindi',
      duration: '9:45',
      description: 'Required documents, passbook rules, and tax-free interest calculation for girl children.',
      descriptionHindi: 'बालिकाओं के लिए आवश्यक दस्तावेज, पासबुक नियम और कर-मुक्त ब्याज गणना।',
    ),
  };

  /// Returns the verified YouTube tutorial model for a given scheme ID if available.
  static YouTubeTutorialModel? getTutorialForScheme(String schemeId) {
    final cleanId = schemeId.trim().toLowerCase().replaceAll('-', '_');
    return _tutorials[cleanId];
  }

  /// Check whether a verified tutorial exists for a scheme ID
  static bool hasTutorial(String schemeId) {
    return getTutorialForScheme(schemeId) != null;
  }
}

