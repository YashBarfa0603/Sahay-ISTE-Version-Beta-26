# SAHAY (सहाय) — Search Input & Eligibility Additional Information Fix Report

**Date:** 2026-11-01  
**Project:** SAHAY (सहाय) — Citizen Welfare Scheme Discovery Platform  
**Environment:** Flutter 3.35+, Dart 3.9+, macOS  
**Verification Status:** Verified & Passing (206/206 unit/widget tests passing; 0 flutter analyze warnings)

---

## Executive Summary

This engineering report details the root cause analysis, architecture design, code implementations, and automated verification for two core bug fixes and user experience enhancements in SAHAY:

1. **Issue 1 — Keyboard / Text Input Focus Dismissal**:
   - Resolved persistent soft keyboard visibility upon search submission, search icon button press, voice input, tapping outside the input container, and list scrolling.
   - Preserved search queries and reactive debounced search while restoring visibility to search results.
   - Implemented across [SchemesScreen](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/schemes_screen.dart), [HomeScreen](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/home_screen.dart), and [CscLocatorScreen](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/csc_locator_screen.dart).

2. **Issue 2 — Dedicated "Provide Additional Information" Flow for Eligibility Results**:
   - Replaced erroneous redirection from `questionnaire_screen.dart` (which restarted the entire questionnaire from Q1 and re-asked already provided answers).
   - Created a dedicated, focused screen: [`SchemeMissingInfoScreen`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/scheme_missing_info_screen.dart).
   - Designed and integrated `QuestionEngine.getMissingQuestionsForScheme(...)` to isolate **only** unanswered mandatory criteria for the target scheme, strictly preventing repeated questions (such as age, state, or occupation).
   - Implemented state preservation via [`UserProfileProvider`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/providers/user_profile_provider.dart) and immediate re-evaluation of the scheme and all catalogue schemes via [`EligibilityProvider`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/providers/eligibility_provider.dart).
   - Wired bidirectional navigation from both [`EligibilityCard`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/widgets/eligibility_card.dart) on `ResultsScreen` and [`SchemeDetailScreen`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/scheme_detail_screen.dart).
   - Localized all UI elements across all 8 supported Indian languages: English, Hindi, Tamil, Marathi, Bengali, Gujarati, Kannada, and Odia.

---

## 1. Root Cause Analysis

### 1.1 Issue 1: Keyboard / Text Input Did Not Disappear After Searching
- **Unmanaged Focus Hierarchy**: The `TextField` in `SchemesScreen` and `HomeScreen` lacked dedicated `FocusNode` management. Submitting a query did not call `unfocus()` on the primary focus node or `FocusScope.of(context).unfocus()`.
- **Static Search Icon**: In both `HomeScreen` and `SchemesScreen`, the magnifying glass was a static `Icon` widget inside the search bar row rather than an interactive `IconButton` or tap target, forcing users to submit via the soft keyboard.
- **Missing Keyboard Dismiss Behavior on Scroll**: `ListView.separated` and `SingleChildScrollView` were missing `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`, allowing the keyboard to obscure results during scrolling.
- **No Background Tap Dismissal**: The screen root was not enclosed in a translucent `GestureDetector` that unfocused active inputs when tapping outside.
- **Lingering Focus Across Navigation**: Tapping a scheme card pushed `SchemeDetailScreen` without explicitly dismissing keyboard focus, leaving the keyboard open or reappearing when returning.

### 1.2 Issue 2: Incorrect Redirection to Full Questionnaire
- **Hardcoded Questionnaire Route**: In `SchemeDetailScreen` (line 587), the "Provide Missing Information" button was hardcoded to `MaterialPageRoute(builder: (_) => const QuestionnaireScreen())`.
- **Missing Action on EligibilityCard**: In `ResultsScreen` and other list views, `EligibilityCard` lacked a dedicated direct action for schemes classified as `EligibilityResult.needsMoreInformation`.
- **Questionnaire Reset Mechanics**: `QuestionnaireScreen` is an end-to-end multi-step flow that starts at Step 1 (`_questionHistory.clear()`) and iterates through general demographic questions. It lacked any mechanism to filter questions to a specific scheme's missing criteria.
- **Field Alias Desynchronization**: Rules in `SchemeDataService` referenced canonical evaluation fields (e.g., `ownsCultivableLand`, `annualFamilyIncome`, `bplCard`, `hasAadhaarOrIdProof`, `isVulnerableCategory`) that needed bidirectional mapping to `QuestionItem.id` (`landOwnership`, `annualIncome`, `hasPriorityRationCard`, `hasBankAccount`, `casteCategory`).

---

## 2. Architecture & Implementation Details

### 2.1 Search Focus Management & Keyboard Dismissal

#### A. SchemesScreen (`lib/screens/schemes_screen.dart`)
1. **Focus Node Lifecycle**:
   - Initialized `final FocusNode _searchFocusNode = FocusNode();` and disposed it in `dispose()`.
2. **Keyboard Submission**:
   - Configured `textInputAction: TextInputAction.search`.
   - On `onSubmitted(query)`: cancelled any pending debounce timer, triggered immediate `searchSchemes(query)`, and called `_searchFocusNode.unfocus()`. The query text in `_searchController` is preserved.
3. **Interactive Search Button**:
   - Replaced static `Icon` with an `IconButton` (tooltip "Search", 42x42 minimum hit target) that cancels debouncing, executes search, and unfocuses.
4. **Clear & Voice Input**:
   - Clicking Clear or completing voice recognition immediately unfocuses `_searchFocusNode`.
5. **Dismiss on Drag & Tap Outside**:
   - Added `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` to `ListView.separated`.
   - Enclosed the entire `SafeArea` content in `GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => FocusScope.of(context).unfocus(), child: ...)`.
6. **Navigation Safety**:
   - In `_SchemeCard.onTap`, invoked `FocusScope.of(context).unfocus()` prior to `Navigator.of(context).push(...)`.

#### B. HomeScreen (`lib/screens/home_screen.dart`)
1. **Interactive Search Bar**:
   - Assigned `focusNode: _searchFocusNode` and `textInputAction: TextInputAction.search`.
   - Implemented `onSubmitted(query)` and search `IconButton` which unfocus and navigate to `SchemesScreen(initialQuery: query)`.
2. **Body Dismissal**:
   - Wrapped `SingleChildScrollView` with `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` and `GestureDetector(onTap: () => FocusScope.of(context).unfocus())`.
3. **Voice Input Integration**:
   - In `_handleVoiceResult`, unfocuses `_searchFocusNode` before navigation.

#### C. CscLocatorScreen (`lib/screens/csc_locator_screen.dart`)
1. In `_searchCentres()`, added `FocusScope.of(context).unfocus()`.
2. Added `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` and background tap dismiss.

---

### 2.2 Dedicated Scheme Missing Information Flow

#### A. Field Mapping & Question Isolation in `QuestionEngine` (`lib/services/question_engine.dart`)
1. **Canonical Field Mapping**:
   ```dart
   String mapFieldToQuestionId(String field) {
     switch (field) {
       case 'annualFamilyIncome':
       case 'income':
         return 'annualIncome';
       case 'ownsCultivableLand':
       case 'landArea':
         return 'landOwnership';
       case 'isDependentOfExServiceman':
         return 'isExServiceman';
       case 'hasAadhaarOrIdProof':
         return 'hasBankAccount';
       case 'isVulnerableCategory':
         return 'casteCategory';
       case 'ownsFourWheeler':
       case 'hasMotorizedVehicle':
         return 'hasFourWheeler';
       case 'bplCard':
         return 'hasPriorityRationCard';
       default:
         return field;
     }
   }
   ```
2. **Missing Question Isolation**:
   ```dart
   List<QuestionItem> getMissingQuestionsForScheme(
     SchemeModel scheme,
     Map<String, dynamic> existingAnswers, {
     EligibilityModel? assessment,
   }) {
     final eval = assessment ?? _eligibilityEngine.evaluateScheme(scheme, existingAnswers);
     final pendingConditions = eval.conditionResults
         .where((c) => c.status == ConditionStatus.pending && c.isMandatory)
         .toList();

     final missingQuestions = <QuestionItem>[];
     final seenIds = <String>{};

     for (final cond in pendingConditions) {
       final questionId = mapFieldToQuestionId(cond.field);

       // Skip if already answered in profile
       if (existingAnswers.containsKey(questionId) &&
           existingAnswers[questionId] != null &&
           existingAnswers[questionId].toString().trim().isNotEmpty) {
         continue;
       }
       if (existingAnswers.containsKey(cond.field) &&
           existingAnswers[cond.field] != null &&
           existingAnswers[cond.field].toString().trim().isNotEmpty) {
         continue;
       }

       if (seenIds.contains(questionId)) continue;
       seenIds.add(questionId);

       final questionItem = getQuestionForField(cond.field) ??
           QuestionItem(
             id: cond.field,
             type: cond.expectedValue is bool
                 ? 'boolean'
                 : (cond.expectedValue is num ? 'number' : 'text'),
             label: cond.label ?? cond.field,
             labelHindi: cond.labelHindi,
             helperText: cond.requiredDescription,
           );

       missingQuestions.add(questionItem);
     }
     return missingQuestions;
   }
   ```

#### B. SchemeMissingInfoScreen (`lib/screens/scheme_missing_info_screen.dart`)
A dedicated, responsive Flutter screen providing:
- **Prominent Scheme Header**: Scheme name in active language, blue `additionalInfoRequired` badge, and explanatory helper text.
- **Specific Unanswered Inputs**:
  - `boolean`: Dual choice interactive tiles (Yes / No) with teal accent.
  - `number`: Form field with unit suffix (e.g. Acres, ₹, %), numeric keypad, and validation.
  - `single_choice`: Translated choice chips using `_formatOptionLabel` or `IndianStates` dropdown.
  - `text`: Text input with appropriate hint.
- **Validation Before Submission**: Verifies that every required missing field is filled; surfaces a localized error alert (`pleaseFillAllFields`) if incomplete.
- **Atomic State Merge & Re-Evaluation**:
  1. Calls `userProfile.setAnswers(_answers)` (merges answers in-place; all previously answered demographic questions are preserved).
  2. Calls `eligibilityProvider.evaluateSingle(widget.scheme, userProfile.answers)`.
  3. Calls `eligibilityProvider.evaluateAll(schemeProvider.schemes, userProfile.answers)` so all scheme classifications and result counters update immediately.
  4. Asynchronously updates authenticated cloud profile via `authProvider.updateProfile(_answers)`.
  5. Pops with updated assessment and presents a feedback SnackBar (`forestGreen` if qualifying, `deepNavy` otherwise).
- **Cancel Action**: Pops without modifying `UserProfileProvider` answers.

#### C. EligibilityCard (`lib/widgets/eligibility_card.dart`)
- When `eligibility.result == EligibilityResult.needsMoreInformation`, displays an OutlinedButton labeled `l10n.provideAdditionalInfo`.
- Tapping opens `SchemeMissingInfoScreen(scheme: scheme, eligibility: eligibility)`.

#### D. SchemeDetailScreen (`lib/screens/scheme_detail_screen.dart`)
- Replaced route on line 587 to open `SchemeMissingInfoScreen(scheme: widget.scheme, eligibility: assessment)`.
- Prioritized newly updated assessments from `eligibilityProvider.getResultForScheme(widget.scheme.schemeId)`.

---

### 2.3 Multilingual Localization Matrix
Added 6 typed localization getters to `AppLocalizations` (`SahayLocalizations`) and implemented exact localized translations across all 8 supported languages:

| Key | English | Hindi | Tamil | Marathi | Bengali | Gujarati | Kannada | Odia |
|---|---|---|---|---|---|---|---|---|
| `provideAdditionalInfo` | Provide Additional Information | अतिरिक्त जानकारी प्रदान करें | கூடுதல் தகவல்களை வழங்கவும் | अतिरिक्त माहिती प्रदान करा | অতিরিক্ত তথ্য প্রদান করুন | વધારાની માહિતી આપો | ಹೆಚ್ಚುವರಿ ಮಾಹಿತಿಯನ್ನು ಒದಗಿಸಿ | ଅତିରିକ୍ତ ସୂଚନା ପ୍ରଦାନ କରନ୍ତୁ |
| `additionalInfoRequired` | Additional Information Required | अतिरिक्त जानकारी आवश्यक | கூடுதல் தகவல் தேவை | अतिरिक्त माहिती आवश्यक | অতিরিক্ত তথ্য প্রয়োজন | વધારાની માહિતી જરૂરી છે | ಹೆಚ್ಚುವರಿ ಮಾಹಿತಿ ಅಗತ್ಯವಿದೆ | ଅତିରିକ୍ତ ସୂଚନା ଆବଶ୍ୟକ |
| `missingInfoDesc` | Provide the following details to verify your eligibility for this scheme. | इस योजना के लिए अपनी पात्रता जांचने हेतु कृपया निम्नलिखित विवरण प्रदान करें। | இந்தத் திட்டத்திற்கான உங்கள் தகுதியைச் சரிபார்க்க பின்வரும் விவரங்களை வழங்கவும். | या योजनेसाठी आपली पात्रता तपासण्यासाठी कृपया खालील तपशील प्रदान करा. | এই প্রকল্পের জন্য আপনার যোগ্যতা যাচাই করতে অনুগ্রহ করে নিম্নলিখিত বিবরণ প্রদান করুন। | આ યોજના માટે તમારી પાત્રતા ચકાસવા માટે કૃપા કરીને નીચેની વિગતો પ્રદાન કરો. | ಈ ಯೋಜನೆಗೆ ನಿಮ್ಮ ಅರ್ಹತೆಯನ್ನು ಪರಿಶೀಲಿಸಲು ಕೆಳಗಿನ ವಿವರಗಳನ್ನು ಒದಗಿಸಿ. | ଏହି ଯୋଜନା ପାଇଁ ଆପଣଙ୍କ ଯୋଗ୍ୟତା ଯାଞ୍ଚ କରିବାକୁ ନିମ୍ନଲିଖିତ ବିବରଣୀ ପ୍ରଦାନ କରନ୍ତୁ। |
| `submitAndCheckEligibility` | Submit & Check Eligibility | जमा करें और पात्रता जांचें | சமர்ப்பித்து தகுதியைச் சரிபார்க்கவும் | सबमिट करा आणि पात्रता तपासा | জমা দিন এবং যোগ্যতা যাচাই করুন | સબમિટ કરો અને પાત્રતા ચકાસો | ಸಲ್ಲಿಸಿ ಮತ್ತು ಅರ್ಹತೆಯನ್ನು ಪರಿಶೀಲಿಸಿ | ଦାଖଲ କରନ୍ତୁ ଏବଂ ଯୋଗ୍ୟତା ଯାଞ୍ଚ କରନ୍ତୁ |
| `allInformationProvided` | All required information for this scheme has already been provided. | इस योजना के लिए आवश्यक सभी जानकारी पहले ही प्रदान की जा चुकी है। | இந்தத் திட்டத்திற்குத் தேவையான அனைத்து தகவல்களும் ஏற்கனவே வழங்கப்பட்டுள்ளன. | या योजनेसाठी आवश्यक असलेली सर्व माहिती आधीच प्रदान केली गेली आहे. | এই প্রকল্পের জন্য প্রয়োজনীয় সমস্ত তথ্য ইতিমধ্যেই সরবরাহ করা হয়েছে। | આ યોજના માટે જરૂરી તમામ માહિતી પહેલેથી જ આપી દેવામાં આવી છે. | ಈ ಯೋಜನೆಗೆ ಅಗತ್ಯವಿರುವ ಎಲ್ಲಾ ಮಾಹಿತಿಯನ್ನು ಈಗಾಗಲೇ ಒದಗಿಸಲಾಗಿದೆ. | ଏହି ଯୋଜନା ପାଇଁ ସମସ୍ତ ଆବଶ୍ୟକୀୟ ସୂଚନା ପୂର୍ବରୁ ପ୍ରଦାନ କରାଯାଇଛି। |
| `pleaseFillAllFields` | Please fill in all required fields. | कृपया सभी आवश्यक विवरण भरें। | தேவையான அனைத்து விவரங்களையும் நிரப்பவும். | कृपया सर्व आवश्यक तपशील भरा. | অনুগ্রহ করে সমস্ত প্রয়োজনীয় ক্ষেত্র পূরণ করুন। | કૃપા કરીને બધી જરૂરી વિગતો ભરો. | ದಯವಿಟ್ಟು ಅಗತ್ಯವಿರುವ ಎಲ್ಲಾ ವಿವರಗಳನ್ನು ಭರ್ತಿ ಮಾಡಿ. | ଦୟାକରି ସମସ୍ତ ଆବଶ୍ୟକୀୟ କ୍ଷେତ୍ର ପୂରଣ କରନ୍ତୁ। |

---

## 3. Verification & Automated Test Evidence

### 3.1 Dedicated Search Focus Tests (`test/search_focus_test.dart`)
Command executed:
```bash
flutter test test/search_focus_test.dart --no-pub
```
**Results:** 5/5 passing in 00:03.
- `SchemesScreen: submitting search query unfocuses text field and retains query`: Verified focus lost (`focusNode.hasFocus == false`), query `'Kisan'` preserved, catalogue filtered.
- `SchemesScreen: tapping search icon unfocuses text field and preserves query`: Verified tapping search `IconButton` unfocuses and retains query.
- `SchemesScreen: tapping outside search field unfocuses text field`: Verified tapping background outside the search field dismisses focus.
- `HomeScreen: submitting search query unfocuses search field and retains query`: Verified focus lost and query preserved on submit.
- `HomeScreen: tapping search icon button unfocuses and retains query`: Verified focus lost and query preserved on icon tap.

### 3.2 Dedicated Scheme Missing Information Tests (`test/scheme_missing_info_test.dart`)
Command executed:
```bash
flutter test test/scheme_missing_info_test.dart --no-pub
```
**Results:** 8/8 passing in 00:04.
- `getMissingQuestionsForScheme asks ONLY for unanswered missing criteria`: Passed. When user has answered age, state, occupation, only `landOwnership` is returned. Age, state, and occupation are never returned.
- `getMissingQuestionsForScheme returns empty when all criteria answered`: Passed. When all criteria are answered, returns empty list.
- `Renders scheme name and ONLY the missing fields`: Verified scheme title is rendered prominently and only missing fields are rendered.
- `Empty submission fails validation with prompt`: Verified submit button without input triggers validation alert.
- `Submitting missing information updates profile and re-evaluates scheme eligibility`: Verified `UserProfileProvider` receives `landOwnership: 1.5` while preserving `age: 40`, `state: 'MP'`, and `occupation: 'farmer'`. Verified `EligibilityProvider.getResultForScheme` updates and no longer requires more information.
- `Cancel button dismisses without modifying profile answers`: Verified answers in `UserProfileProvider` remain intact.
- `EligibilityCard: "Provide Additional Information" button opens SchemeMissingInfoScreen`: Verified button navigation routes to `SchemeMissingInfoScreen` and NOT `QuestionnaireScreen`.
- `SchemeDetailScreen: "Provide Missing Information" button opens SchemeMissingInfoScreen`: Verified button in Eligibility tab routes to `SchemeMissingInfoScreen` and NOT `QuestionnaireScreen`.

### 3.3 Full Regression Suite
Command executed:
```bash
flutter test --no-pub
```
**Results:** **206 / 206 tests passed (100% pass rate, 0 failures, 0 regressions).**

### 3.4 Static Analysis
Command executed:
```bash
flutter analyze --no-pub
```
**Results:** `No issues found! (ran in 3.3s)`

---

## 4. File Modification Summary

| File | Change Description |
|---|---|
| [`lib/screens/schemes_screen.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/schemes_screen.dart) | Added `_searchFocusNode`, `textInputAction: TextInputAction.search`, `onSubmitted`, interactive search `IconButton`, unfocus on clear/voice, background tap dismiss, `keyboardDismissBehavior: onDrag`, unfocus on card tap. |
| [`lib/screens/home_screen.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/home_screen.dart) | Added `_searchFocusNode`, `onSubmitted`, interactive search `IconButton`, unfocus in `_handleVoiceResult`, background tap dismiss, `keyboardDismissBehavior: onDrag`. |
| [`lib/screens/csc_locator_screen.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/csc_locator_screen.dart) | Added `FocusScope.of(context).unfocus()` in `_searchCentres()`, background tap dismiss, `keyboardDismissBehavior: onDrag`. |
| [`lib/services/question_engine.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/services/question_engine.dart) | Added `mapFieldToQuestionId`, `getQuestionForField`, and `getMissingQuestionsForScheme` to filter questions to only unanswered missing criteria for a specific scheme. |
| [`lib/screens/scheme_missing_info_screen.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/scheme_missing_info_screen.dart) | **New Screen**: Dedicated view asking only missing questions for a specific scheme, input validation, atomic state merge in `UserProfileProvider`, single and full scheme re-evaluation in `EligibilityProvider`, and cloud sync. |
| [`lib/widgets/eligibility_card.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/widgets/eligibility_card.dart) | Added "Provide Additional Information" action button for schemes needing more details, navigating to `SchemeMissingInfoScreen`. |
| [`lib/screens/scheme_detail_screen.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/screens/scheme_detail_screen.dart) | Replaced redirection from `QuestionnaireScreen` to `SchemeMissingInfoScreen`; prioritized refreshed assessments from `EligibilityProvider`. |
| [`lib/core/l10n/app_localizations.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/core/l10n/app_localizations.dart) | Added 6 new typed getters for additional information flow. |
| [`lib/core/l10n/strings_*.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/core/l10n/strings_en.dart) | Added localized strings for all 6 new keys across all 8 supported Indian languages. |
| [`test/search_focus_test.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/test/search_focus_test.dart) | **New Test Suite**: 5 automated tests verifying search keyboard dismissal, query retention, icon button tap, and tap outside dismiss. |
| [`test/scheme_missing_info_test.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/test/scheme_missing_info_test.dart) | **New Test Suite**: 8 automated tests verifying question isolation, form validation, re-evaluation, state preservation, cancel flow, and routing. |

---

## 5. Conclusion
Both issues have been completely resolved according to all UX and architectural specifications. Search focus management cleanly dismisses the soft keyboard across all screens while preserving query contents and debounced queries. The eligibility flow now features a dedicated, streamlined screen requesting only the specific unanswered criteria required for a scheme without ever repeating previously answered questions, preserving session/profile state, and instantly updating eligibility results across the entire application.

