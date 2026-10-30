import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sahay/core/l10n/strings_bn.dart';
import 'package:sahay/core/l10n/strings_en.dart';
import 'package:sahay/core/l10n/strings_gu.dart';
import 'package:sahay/core/l10n/strings_hi.dart';
import 'package:sahay/core/l10n/strings_kn.dart';
import 'package:sahay/core/l10n/strings_mr.dart';
import 'package:sahay/core/l10n/strings_or.dart';
import 'package:sahay/core/l10n/strings_ta.dart';

class SahayLocalizations {
  final Locale locale;

  SahayLocalizations(this.locale);

  static SahayLocalizations of(BuildContext context) {
    return Localizations.of<SahayLocalizations>(context, SahayLocalizations) ??
        SahayLocalizations(const Locale('en'));
  }

  // Languages
  static const List<String> supportedLanguageCodes = [
    'en',
    'hi',
    'ta',
    'mr',
    'bn',
    'gu',
    'kn',
    'or',
  ];

  // Locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('mr'),
    Locale('bn'),
    Locale('gu'),
    Locale('kn'),
    Locale('or'),
  ];

  static const LocalizationsDelegate<SahayLocalizations> delegate =
      SahayLocalizationsDelegate();

  // Strings
  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': stringsEn,
    'hi': stringsHi,
    'ta': stringsTa,
    'mr': stringsMr,
    'bn': stringsBn,
    'gu': stringsGu,
    'kn': stringsKn,
    'or': stringsOr,
  };

  // Lookup
  String getString(String key) {
    final currentMap = _localizedStrings[locale.languageCode] ?? stringsEn;
    return currentMap[key] ?? stringsEn[key] ?? key;
  }

  // App & Onboarding
  String get appName => getString('appName');
  String get appNameNative => getString('appNameNative');
  String get appTagline => getString('appTagline');
  String get welcomeTitle => getString('welcomeTitle');
  String get welcomeSubtitle => getString('welcomeSubtitle');
  String get getStarted => getString('getStarted');

  // Navigation & Sections
  String get home => getString('home');
  String get search => getString('search');
  String get profile => getString('profile');
  String get settings => getString('settings');
  String get schemes => getString('schemes');
  String get eligibility => getString('eligibility');

  // Search & Actions
  String get searchSchemes => getString('searchSchemes');
  String get searchHint => getString('searchHint');
  String get noResults => getString('noResults');
  String get noResultsDescription => getString('noResultsDescription');
  String get loading => getString('loading');
  String get error => getString('error');
  String get retry => getString('retry');
  String get filter => getString('filter');
  String get clearFilter => getString('clearFilter');
  String get filterByCategory => getString('filterByCategory');
  String get allSchemes => getString('allSchemes');
  String get seeAll => getString('seeAll');
  String get yes => getString('yes');
  String get no => getString('no');
  String get close => getString('close');
  String get save => getString('save');
  String get done => getString('done');
  String get selectOption => getString('selectOption');

  // Categories
  String get agriculture => getString('agriculture');
  String get health => getString('health');
  String get housing => getString('housing');
  String get education => getString('education');
  String get women => getString('women');
  String get employment => getString('employment');
  String get socialWelfare => getString('socialWelfare');
  String get financial => getString('financial');

  // Question Labels
  String get gender => getString('gender');
  String get age => getString('age');
  String get state => getString('state');
  String get stateUnionTerritory => getString('stateUnionTerritory');
  String get district => getString('district');
  String get occupation => getString('occupation');
  String get annualIncome => getString('annualIncome');
  String get residenceType => getString('residenceType');
  String get landOwnership => getString('landOwnership');
  String get casteCategory => getString('casteCategory');
  String get disability => getString('disability');
  String get maritalStatus => getString('maritalStatus');
  String get numberOfChildren => getString('numberOfChildren');
  String get existingLPG => getString('existingLPG');
  String get isExServiceman => getString('isExServiceman');
  String get educationLevel => getString('educationLevel');

  // Question Options - Gender
  String get male => getString('male');
  String get female => getString('female');
  String get other => getString('other');

  // Question Options - Residence
  String get rural => getString('rural');
  String get urban => getString('urban');
  String get semiUrban => getString('semiUrban');

  // Question Options - Land Ownership
  String get landless => getString('landless');
  String get marginalFarmer => getString('marginalFarmer');
  String get smallFarmer => getString('smallFarmer');
  String get largeFarmer => getString('largeFarmer');

  // Question Options - Caste Category
  String get general => getString('general');
  String get obc => getString('obc');
  String get sc => getString('sc');
  String get st => getString('st');
  String get ews => getString('ews');

  // Question Options - Disability
  String get disabilityYes => getString('disabilityYes');
  String get disabilityNo => getString('disabilityNo');
  String get disabilityLocomotor => getString('disabilityLocomotor');
  String get disabilityVisual => getString('disabilityVisual');
  String get disabilityHearing => getString('disabilityHearing');

  // Question Options - Marital Status
  String get single => getString('single');
  String get married => getString('married');
  String get widowed => getString('widowed');
  String get divorced => getString('divorced');
  String get separated => getString('separated');

  // Question Options - LPG Connection
  String get hasLPGConnection => getString('hasLPGConnection');
  String get noLPGConnection => getString('noLPGConnection');

  // Question Options - Ex-Serviceman
  String get exServicemanYes => getString('exServicemanYes');
  String get exServicemanNo => getString('exServicemanNo');

  // Question Options - Education
  String get illiterate => getString('illiterate');
  String get primaryEducation => getString('primaryEducation');
  String get secondaryEducation => getString('secondaryEducation');
  String get higherSecondary => getString('higherSecondary');
  String get graduate => getString('graduate');
  String get postGraduate => getString('postGraduate');

  // Question Options - Occupation
  String get farmer => getString('farmer');
  String get dailyWageWorker => getString('dailyWageWorker');
  String get artisan => getString('artisan');
  String get smallBusinessOwner => getString('smallBusinessOwner');
  String get salariedPrivate => getString('salariedPrivate');
  String get salariedGovernment => getString('salariedGovernment');
  String get student => getString('student');
  String get unemployed => getString('unemployed');
  String get homemaker => getString('homemaker');
  String get retired => getString('retired');

  // Eligibility Results
  String get mayQualify => getString('mayQualify');
  String get needsMoreInfo => getString('needsMoreInfo');
  String get doesNotQualify => getString('doesNotQualify');
  String get eligible => getString('eligible');
  String get notEligible => getString('notEligible');
  String get partiallyEligible => getString('partiallyEligible');
  String get eligibilityCheck => getString('eligibilityCheck');
  String get checkEligibility => getString('checkEligibility');
  String get checkEligibilityNow => getString('checkEligibilityNow');

  // Documents
  String get aadhaar => getString('aadhaar');
  String get panCard => getString('panCard');
  String get rationCard => getString('rationCard');
  String get incomeCertificate => getString('incomeCertificate');
  String get casteCertificate => getString('casteCertificate');
  String get domicileCertificate => getString('domicileCertificate');
  String get bankPassbook => getString('bankPassbook');
  String get passport => getString('passport');
  String get voterID => getString('voterID');
  String get landDocuments => getString('landDocuments');
  String get disabilityCertificate => getString('disabilityCertificate');
  String get deathCertificate => getString('deathCertificate');
  String get marriageCertificate => getString('marriageCertificate');

  // Actions
  String get apply => getString('apply');
  String get viewDetails => getString('viewDetails');
  String get downloadChecklist => getString('downloadChecklist');
  String get shareResults => getString('shareResults');
  String get clearData => getString('clearData');
  String get changeLanguage => getString('changeLanguage');
  String get back => getString('back');
  String get next => getString('next');
  String get submit => getString('submit');
  String get skip => getString('skip');
  String get cancel => getString('cancel');
  String get confirm => getString('confirm');
  String get continueButton => getString('continueButton');

  // Privacy & Session
  String get privacyTitle => getString('privacyTitle');
  String get privacyDescription => getString('privacyDescription');
  String get clearDataConfirm => getString('clearDataConfirm');
  String get dataCleared => getString('dataCleared');
  String get sessionOnly => getString('sessionOnly');
  String get sessionNotice => getString('sessionNotice');

  // Voice
  String get tapToSpeak => getString('tapToSpeak');
  String get listening => getString('listening');
  String get processing => getString('processing');
  String get speakNow => getString('speakNow');

  // Errors
  String get networkError => getString('networkError');
  String get serverError => getString('serverError');
  String get noInternet => getString('noInternet');
  String get tryAgain => getString('tryAgain');
  String get somethingWentWrong => getString('somethingWentWrong');

  // Scheme Details
  String get benefits => getString('benefits');
  String get eligibilityCriteria => getString('eligibilityCriteria');
  String get requiredDocuments => getString('requiredDocuments');
  String get applicationProcess => getString('applicationProcess');
  String get officialSource => getString('officialSource');
  String get lastVerified => getString('lastVerified');
  String get ministry => getString('ministry');
  String get governmentLevel => getString('governmentLevel');
  String get central => getString('central');
  String get stateGovernment => getString('stateGovernment');
  String get stateLevel => getString('stateLevel');
  String get applicableStates => getString('applicableStates');

  // Explanations & Disclaimers
  String get youMayQualifyBecause => getString('youMayQualifyBecause');
  String get youDoNotQualifyBecause => getString('youDoNotQualifyBecause');
  String get missingInformation => getString('missingInformation');
  String get borderlineWarning => getString('borderlineWarning');
  String get verifyWithOfficial => getString('verifyWithOfficial');
  String get disclaimerText => getString('disclaimerText');
}

// Delegate
class SahayLocalizationsDelegate
    extends LocalizationsDelegate<SahayLocalizations> {
  const SahayLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return SahayLocalizations.supportedLanguageCodes.contains(locale.languageCode);
  }

  @override
  Future<SahayLocalizations> load(Locale locale) {
    return SynchronousFuture<SahayLocalizations>(SahayLocalizations(locale));
  }

  @override
  bool shouldReload(SahayLocalizationsDelegate old) => false;
}
