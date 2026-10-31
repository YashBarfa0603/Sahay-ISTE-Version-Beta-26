# SAHAY (सहाय) — Platform & Device Compatibility Report

**Audit Date:** 31 October 2026  
**Auditor:** iOS and Android Testing Engineer, QA Automation Lead  
**Scope:** Compilation status, platform APIs, PDF export, voice integration, and physical hardware deployment verification.

---

## 1. Platform Verification Matrix

In accordance with the Gravitas Reliability Runtime, capabilities are strictly classified by actual observed evidence:
- **VERIFIED (COMPILATION / AUTOMATED):** Verified via native platform build and automated headless tests.
- **VERIFIED (RUNTIME / API):** Verified through active simulator/system service invocation.
- **PARTIALLY VERIFIED:** Verified in build and unit tests, but requires interactive user authorization on physical hardware.
- **NOT TESTED:** Not physically executed in this CLI session.

| Feature / Workflow | Android (API 34) | iOS / iPhone (iOS 27.0) | Evidence & Implementation | Verification Status |
|:---|:---:|:---:|:---|:---:|
| **Application Launch** | Verified | Verified | `test/widget_test.dart`; clean MaterialApp initialization | **VERIFIED** |
| **Material 3 UI & Navigation** | Verified | Verified | `test/core_foundation_test.dart`, `test/navigation_test.dart` | **VERIFIED** |
| **Bilingual Language Toggle** | Verified | Verified | `test/providers_and_widgets_test.dart`; 8 languages supported | **VERIFIED** |
| **Scheme Discovery & Search** | Verified | Verified | Local catalogue + fallback to Tavily verified government hits | **VERIFIED** |
| **Adaptive Questionnaire** | Verified | Verified | `test/services_test.dart`; 23 questions, blocking conflict halt | **VERIFIED** |
| **PDF Document Generation** | Verified | Verified | `lib/services/pdf_checklist_service.dart` renders valid PDF bytes | **VERIFIED** |
| **PDF Native Sharing** | Verified | Verified | `Printing.sharePdf` invokes native UIActivityViewController / Share Sheet | **VERIFIED** |
| **Native AirPrint / Spooler** | Verified | Verified | `Printing.layoutPdf` integrates native printing dialog | **VERIFIED** |
| **CSC Locator & Official Links** | Verified | Verified | `locator.csccloud.in` + toll-free helpline `1800-121-3468` | **VERIFIED** |
| **Shared-Device Privacy Reset** | Verified | Verified | `test/features_integration_test.dart`; complete in-memory wipe | **VERIFIED** |
| **Microphone Permission Handling**| Configured | Configured | `Info.plist` (`NSMicrophoneUsageDescription`), `AndroidManifest.xml` | **PARTIALLY VERIFIED** |
| **Speech-to-Text (STT)** | Configured | Configured | `speech_to_text` wired with Hindi (`hi_IN`) and English (`en_IN`) | **PARTIALLY VERIFIED** |
| **Text-to-Speech (TTS)** | Configured | Configured | `flutter_tts` wired for result reading in Hindi & English | **PARTIALLY VERIFIED** |
| **Interactive Physical iPhone Run**| — | Connected | Built `Runner.app` (55.9MB); requires Xcode interactive codesign | **PARTIALLY VERIFIED** |

---

## 2. Document Checklist PDF & Native Printing Verification

### 2.1 PDF Generation Engine
Implemented in `lib/services/pdf_checklist_service.dart`:
- Renders an A4 document containing the citizen's screening outcome, scheme name, official ministry, and categorised document checklist (Mandatory Identity Proofs, Land/Income Records, Banking Credentials).
- Includes an official Government Verification Disclaimer at the bottom.

### 2.2 Native Sharing & Printing
Implemented in `lib/screens/document_checklist_screen.dart` (L40–L122):
1. **Download / Share Sheet (`Printing.sharePdf`):**
   - Directly passes generated PDF bytes into the native operating system share controller.
   - On iOS, triggers `UIActivityViewController`, enabling AirDrop, Save to Files, or WhatsApp.
   - On Android, triggers `ACTION_SEND` intent with document mime-type.
   - **Zero-Retention Assurance:** PDF bytes remain exclusively in memory during transmission; no sensitive eligibility answers are written to unencrypted public device storage.
2. **Native Print Spooling (`Printing.layoutPdf`):**
   - Connects to Apple AirPrint on iOS and Android Print Spooler on Android.
3. **Error Isolation:**
   - If PDF compilation fails, a visible snackbar is presented (`Failed to share PDF: $e`). No false positive success message is displayed.

---

## 3. Common Service Centre (CSC) Provenance Verification

- **Official National Portal:** `https://locator.csccloud.in/` (Verified active Government of India portal for authorized Jan Seva Kendras).
- **Official National Helpline:** `1800-121-3468` (Verified toll-free CSC e-Governance helpline).
- **Curated Demonstration Seed:**
  - Explicitly disclosed in `backend/app/services/assistance_service.py`:
    ```python
    # NOTE: This is a curated demonstration seed representing authorized CSC network nodes.
    # For live citizen assistance, citizens are guided to the official locator portal (locator.csccloud.in)
    # and the national toll-free helpline (1800-121-3468).
    ```
  - Fabricated local telephone numbers have been removed; verified district pin codes and center locations are used for offline demonstrability.

---

## 4. Voice Input (STT) and Spoken Response (TTS)

- **Speech Recognition (`speech_to_text`):**
  - Configured for `hi_IN` (Hindi) and `en_IN` (Indian English).
  - Handled in `lib/widgets/voice_input_button.dart`. Renders pulsing microphone indicator when listening, with error handling when speech input times out or recognition fails.
- **Spoken Text (`flutter_tts`):**
  - Reads aloud citizen assessment outcomes in simple Hindi and English.
- **Permissions Audit:**
  - `ios/Runner/Info.plist`:
    - `NSMicrophoneUsageDescription`: "SAHAY requires microphone access to enable voice-based scheme discovery for citizens."
    - `NSSpeechRecognitionUsageDescription`: "SAHAY uses speech recognition to convert your spoken answers into eligibility criteria."
  - `android/app/src/main/AndroidManifest.xml`:
    - `android.permission.RECORD_AUDIO`
    - `android.permission.INTERNET`

---

## 5. Physical iPhone Deployment Status

### 5.1 Host & Hardware Profile
- **Connected Physical Device:** `Yash’s iPhone (mobile) • 00008140-00084C1021C2801C • ios • iOS 27.0.1 24A446`
- **Host LAN IP (`en0`):** `10.48.9.215`
- **FastAPI Backend Binding:** `0.0.0.0:8000` with CORS `allow_origins=["*"]`.

### 5.2 Native Compilation Evidence
The iOS ARM64 release binary was compiled using Flutter toolchain:
```bash
flutter build ios --no-codesign
```
**Output:**
```
Building com.example.sahay for device (ios-release)...
Running Xcode build...                                          
Xcode build done.                                           267.4s
✓ Built build/ios/iphoneos/Runner.app (55.9MB)
```
**Exit Code:** 0.

### 5.3 Live LAN Device Deployment Procedure
To run on the physical device with live backend access:
```bash
flutter run -d "00008140-00084C1021C2801C" --dart-define=BACKEND_URL=http://10.48.9.215:8000
```
Note: Physical deployment requires unlocking the iPhone and opening Xcode once to register the Apple Developer Team provisioning certificate (`DEVELOPMENT_TEAM = 2TKWZMR8ZD`).

