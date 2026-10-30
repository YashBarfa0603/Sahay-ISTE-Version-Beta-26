// ta
const Map<String, String> stringsTa = {
  // App & Onboarding
  'appName': 'SAHAY',
  'appNameNative': 'சஹாய்',
  'appTagline': 'குடிமக்கள் மேம்பாடு, திட்டங்களின் பயன்',
  'welcomeTitle': 'சஹாய் (SAHAY) க்கு வரவேற்கிறோம்',
  'welcomeSubtitle':
      'மத்திய மற்றும் மாநில அரசு நலத்திட்டங்களுக்கான உங்கள் தகுதியை எளிய முறையிலும் ரகசியமாகவும் கண்டறியுங்கள்.',
  'getStarted': 'தொடங்குங்கள்',

  // Navigation & Sections
  'home': 'முகப்பு',
  'search': 'தேடல்',
  'profile': 'சுயவிவரம்',
  'settings': 'அமைப்புகள்',
  'schemes': 'திட்டங்கள்',
  'eligibility': 'தகுதி',

  // Search & Actions
  'searchSchemes': 'திட்டங்களைத் தேடுங்கள்',
  'searchHint': 'திட்டத்தின் பெயர், துறை அல்லது குறிச்சொல் கொண்டு தேடுங்கள்...',
  'noResults': 'திட்டங்கள் எதுவும் கிடைக்கவில்லை',
  'noResultsDescription': 'உங்கள் தேடல் அளவுகோல்களை மாற்றவும் அல்லது வடிப்பான்களை அழிக்கவும்.',
  'loading': 'ஏற்றுகிறது...',
  'error': 'பிழை',
  'retry': 'மீண்டும் முயற்சிக்கவும்',
  'filter': 'வடிகட்டல்',
  'clearFilter': 'வடிப்பான்களை நீக்கு',
  'filterByCategory': 'பிரிவு வாரியாக வடிகட்டு',
  'allSchemes': 'அனைத்து திட்டங்கள்',
  'seeAll': 'அனைத்தும் காண்க',
  'yes': 'ஆம்',
  'no': 'இல்லை',
  'close': 'மூடு',
  'save': 'சேமி',
  'done': 'முடிந்தது',
  'selectOption': 'ஒரு விருப்பத்தைத் தேர்ந்தெடுக்கவும்',

  // Categories
  'agriculture': 'விவசாயம் மற்றும் உழவர் நலம்',
  'health': 'சுகாதாரம் மற்றும் குடும்ப நலம்',
  'housing': 'வீட்டு வசதி மற்றும் உறைவிடம்',
  'education': 'கல்வி மற்றும் கற்றல்',
  'women': 'மகளிர் மற்றும் குழந்தைகள் மேம்பாடு',
  'employment': 'வேலைவாய்ப்பு மற்றும் திறன் மேம்பாடு',
  'socialWelfare': 'சமூக நலம் மற்றும் அதிகாரமளித்தல்',
  'financial': 'நிதி உள்ளடக்கம் மற்றும் வங்கிச் சேவைகள்',

  // Question Labels
  'gender': 'பாலினம்',
  'age': 'வயது',
  'state': 'மாநிலம்',
  'stateUnionTerritory': 'மாநிலம் / யூனியன் பிரதேசம்',
  'district': 'மாவட்டம்',
  'occupation': 'தொழில் / பணி',
  'annualIncome': 'ஆண்டு குடும்ப வருமானம் (₹)',
  'residenceType': 'வசிப்பிடம்',
  'landOwnership': 'விவசாய நில உரிமை',
  'casteCategory': 'சமூகப் பிரிவு / சாதி',
  'disability': 'மாற்றுத்திறனாளி நிலை (PwD)',
  'maritalStatus': 'திருமண நிலை',
  'numberOfChildren': 'குழந்தைகளின் எண்ணிக்கை',
  'existingLPG': 'எல்பிஜி (LPG) எரிவாயு இணைப்பு',
  'isExServiceman': 'முன்னாள் படைவீரர் / பாதுகாப்பு',
  'educationLevel': 'உயர்கல்வித் தகுதி',

  // Question Options - Gender
  'male': 'ஆண்',
  'female': 'பெண்',
  'other': 'மற்றவை',

  // Question Options - Residence
  'rural': 'கிராமப்புறம்',
  'urban': 'நகர்ப்புறம்',
  'semiUrban': 'அரை நகர்ப்புறம்',

  // Question Options - Land Ownership
  'landless': 'நிலமற்றவர்',
  'marginalFarmer': 'குறு விவசாயி (1 ஹெக்டேருக்கும் குறைவு)',
  'smallFarmer': 'சிறு விவசாயி (1 - 2 ஹெக்டேர்)',
  'largeFarmer': 'பெரிய விவசாயி (2 ஹெக்டேருக்கு மேல்)',

  // Question Options - Caste Category
  'general': 'பொதுப் பிரிவு (General)',
  'obc': 'இதர பிற்படுத்தப்பட்ட வகுப்பினர் (OBC/BC/MBC)',
  'sc': 'பட்டியலினத்தவர் (SC)',
  'st': 'பழங்குடியினர் (ST)',
  'ews': 'பொருளாதாரத்தில் பின்தங்கிய பிரிவினர் (EWS)',

  // Question Options - Disability
  'disabilityYes': 'ஆம், மாற்றுத்திறனாளி',
  'disabilityNo': 'இல்லை (இயல்பானவர்)',
  'disabilityLocomotor': 'உடலியக்க இயலாமை',
  'disabilityVisual': 'பார்வைத்திறன் குறைபாடு',
  'disabilityHearing': 'கேள்திறன் குறைபாடு',

  // Question Options - Marital Status
  'single': 'திருமணமாகாதவர்',
  'married': 'திருமணமானவர்',
  'widowed': 'விதவை / விதவை கணவர்',
  'divorced': 'விவாகரத்து பெற்றவர்',
  'separated': 'பிரிந்து வாழ்பவர்',

  // Question Options - LPG Connection
  'hasLPGConnection': 'ஏற்கனவே சமையல் எரிவாயு இணைப்பு உள்ளது',
  'noLPGConnection': 'சமையல் எரிவாயு இணைப்பு இல்லை',

  // Question Options - Ex-Serviceman
  'exServicemanYes': 'ஆம், முன்னாள் படைவீரர் அல்லது சார்ந்தவர்',
  'exServicemanNo': 'இல்லை',

  // Question Options - Education
  'illiterate': 'முறையான பள்ளிக் கல்வி இல்லை',
  'primaryEducation': 'தொடக்கக் கல்வி (5-ஆம் வகுப்பு வரை)',
  'secondaryEducation': 'உயர்நிலைக் கல்வி (10-ஆம் வகுப்பு)',
  'higherSecondary': 'மேல்நிலைக் கல்வி (12-ஆம் வகுப்பு)',
  'graduate': 'இளங்கலை பட்டதாரி (Graduate)',
  'postGraduate': 'முதுகலை பட்டதாரி அல்லது அதற்கு மேல்',

  // Question Options - Occupation
  'farmer': 'விவசாயி / பயிரிடுபவர்',
  'dailyWageWorker': 'தினக்கூலி தொழிலாளி',
  'artisan': 'கைவினைஞர் / கைவினை தொழிலாளி',
  'smallBusinessOwner': 'சிறு வணிகர் / வியாபாரி',
  'salariedPrivate': 'தனியார் துறை பணியாளர்',
  'salariedGovernment': 'அரசு / பொதுத்துறை பணியாளர்',
  'student': 'மாணவர் / மாணவி',
  'unemployed': 'வேலையற்றவர்',
  'homemaker': 'குடும்பத்தலைவி',
  'retired': 'ஓய்வுபெற்றவர் / மூத்த குடிமகன்',

  // Eligibility Results
  'mayQualify': 'தகுதி பெற வாய்ப்புள்ளது',
  'needsMoreInfo': 'கூடுதல் தகவல் தேவைப்படுகிறது',
  'doesNotQualify': 'தகுதி பெறவில்லை',
  'eligible': 'தகுதியுடையவர்',
  'notEligible': 'தகுதியற்றவர்',
  'partiallyEligible': 'பகுதி தகுதியுடையவர்',
  'eligibilityCheck': 'தகுதி மதிப்பீடு',
  'checkEligibility': 'தகுதியை சரிபார்க்கவும்',
  'checkEligibilityNow': 'இப்போதே தகுதியை சரிபார்க்கவும்',

  // Documents
  'aadhaar': 'ஆதார் அட்டை',
  'panCard': 'பான் (PAN) அட்டை',
  'rationCard': 'குடும்ப அட்டை (ரேஷன் அட்டை)',
  'incomeCertificate': 'வருமானச் சான்றிதழ்',
  'casteCertificate': 'சாதிச் சான்றிதழ்',
  'domicileCertificate': 'இருப்பிடச் சான்றிதழ்',
  'bankPassbook': 'வங்கி சேமிப்புக் கணக்கு புத்தகம்',
  'passport': 'கடவுச்சீட்டு (பாஸ்போர்ட்)',
  'voterID': 'வாக்காளர் அடையாள அட்டை',
  'landDocuments': 'நில ஆவணங்கள் (பட்டா / சிட்டா)',
  'disabilityCertificate': 'மாற்றுத்திறனாளி சான்றிதழ் (UDID)',
  'deathCertificate': 'இறப்புச் சான்றிதழ்',
  'marriageCertificate': 'திருமண பதிவுச் சான்றிதழ்',

  // Actions
  'apply': 'விண்ணப்பிக்கவும்',
  'viewDetails': 'விவரங்களைக் காண்க',
  'downloadChecklist': 'ஆவணப் பட்டியலை பதிவிறக்கவும்',
  'shareResults': 'முடிவுகளைப் பகிரவும்',
  'clearData': 'எனது தரவை அழிக்கவும்',
  'changeLanguage': 'மொழியை மாற்றவும்',
  'back': 'பின்னே',
  'next': 'அடுத்து',
  'submit': 'சமர்ப்பிக்கவும்',
  'skip': 'தவிர்க்கவும்',
  'cancel': 'ரத்து செய்',
  'confirm': 'உறுதி செய்',
  'continueButton': 'தொடரவும்',

  // Privacy & Session
  'privacyTitle': 'தரவு பாதுகாப்பு மற்றும் தனியுரிமை',
  'privacyDescription':
      'உங்கள் தரவு உங்கள் சாதனத்தில் மட்டுமே பாதுகாப்பாக இருக்கும். உங்கள் அனுமதியின்றி தொலைநிலை சேவையகங்களில் தனிப்பட்ட விவரங்கள் சேமிக்கப்படாது.',
  'clearDataConfirm':
      'பதிவுசெய்த அனைத்து சுயவிவரத் தரவுகளையும் நீக்க விரும்புகிறீர்களா? இதை மீட்டெடுக்க முடியாது.',
  'dataCleared': 'சேமிக்கப்பட்ட அனைத்து சுயவிவரத் தகவல்களும் வெற்றிகரமாக அழிக்கப்பட்டன.',
  'sessionOnly': 'அமர்வு முறை மட்டும் (Session Only)',
  'sessionNotice':
      'செயலி மூடப்பட்டவுடன் இந்த அமர்வில் உள்ளிடப்பட்ட அனைத்து தகவல்களும் அழிக்கப்படும்.',

  // Voice
  'tapToSpeak': 'பேச மைக்-ஐ அழுத்தவும்',
  'listening': 'கேட்கிறது...',
  'processing': 'செயலாக்குகிறது...',
  'speakNow': 'உங்கள் தாய்மொழியில் பேசுங்கள்',

  // Errors
  'networkError': 'இணைய இணைப்பு சிக்கல். தயவுசெய்து சரிபார்க்கவும்.',
  'serverError': 'சர்வர் பிழை ஏற்பட்டுள்ளது. சிறிது நேரம் கழித்து முயற்சிக்கவும்.',
  'noInternet': 'இணைய இணைப்பு இல்லை. சில அம்சங்கள் ஆஃப்லைனில் செயல்படும்.',
  'tryAgain': 'மீண்டும் முயற்சிக்கவும்',
  'somethingWentWrong': 'ஏதோ தவறு நடந்துவிட்டது. பின்னர் மீண்டும் முயற்சிக்கவும்.',

  // Scheme Details
  'benefits': 'திட்டத்தின் பயன்கள் மற்றும் உதவிகள்',
  'eligibilityCriteria': 'தகுதி வரம்புகள்',
  'requiredDocuments': 'தேவையான ஆவணங்கள்',
  'applicationProcess': 'விண்ணப்பிக்கும் முறை',
  'officialSource': 'அதிகாரப்பூர்வ ஆதாரம்',
  'lastVerified': 'கடைசியாக சரிபார்க்கப்பட்டது',
  'ministry': 'பொறுப்பு அமைச்சகம் / துறை',
  'governmentLevel': 'அரசு நிலை',
  'central': 'மத்திய அரசு',
  'stateGovernment': 'மாநில அரசு',
  'stateLevel': 'மாநில அளவிலான திட்டம்',
  'applicableStates': 'பொருந்தும் மாநிலங்கள்',

  // Explanations & Disclaimers
  'youMayQualifyBecause':
      'உங்கள் சுயவிவரம் முக்கிய அளவுகோல்களை பூர்த்தி செய்வதால் நீங்கள் இத்திட்டத்திற்கு தகுதி பெறலாம்.',
  'youDoNotQualifyBecause':
      'கட்டாய தகுதி நிபந்தனைகளில் ஒன்றை பூர்த்தி செய்யாததால் நீங்கள் தகுதி பெறவில்லை.',
  'missingInformation':
      'முழுமையான தகுதியை உறுதிப்படுத்த கூடுதல் தகவல்கள் தேவைப்படுகின்றன.',
  'borderlineWarning':
      'நீங்கள் உள்ளிட்ட விவரங்கள் தகுதி வரம்புக்கு மிக அருகில் உள்ளன. இறுதி முடிவு செயல்படுத்தும் அதிகார அமைப்பைச் சார்ந்தது.',
  'verifyWithOfficial':
      'விண்ணப்பிக்கும் முன் அதிகாரப்பூர்வ அரசு இணையதளத்தில் அனைத்து வழிகாட்டுதல்களையும் சரிபார்க்கவும்.',
  'disclaimerText':
      'சஹாய் (SAHAY) குடிமக்கள் அரசு நலத்திட்டங்களை கண்டறிய உதவும் ஒரு தகவல் தளமாகும். இறுதி தகுதி மற்றும் பயன் ஒப்புதல் சம்பந்தப்பட்ட அரசு துறைகளின் அதிகாரத்திற்கு உட்பட்டது.',
};
