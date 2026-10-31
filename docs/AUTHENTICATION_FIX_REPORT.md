# SAHAY — Authentication & Session Bug Fixes Report (Phase 1)

## Executive Summary
This report details the root cause analysis, implementation, and verification for the two critical session and authentication navigation bugs resolved in Phase 1 of the SAHAY Master Implementation Plan.

---

## 1. Bug 1: "End Session & Clear" Did Not Return to WelcomeScreen

### Root Cause Analysis
- **Location**: `lib/widgets/privacy_dialog.dart:117-120`
- **Defect**: When the user pressed "End Session" in the Privacy Confirmation Dialog, the callback executed:
  ```dart
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (route) => false,
  );
  ```
- **Consequence**: Instead of clearing the session and returning to the public `WelcomeScreen`, the app routed directly back to `HomeScreen`. Furthermore, `AuthProvider.exitGuestMode()` was not invoked, preserving `isGuest = true` in state.

### Solution & Changes Made
1. **`lib/widgets/privacy_dialog.dart`**:
   - Added imports for `WelcomeScreen` and `AuthProvider`.
   - Before navigation, sequentially executed:
     - `context.read<UserProfileProvider>().clearAllAnswers()`
     - `context.read<EligibilityProvider>().clearResults()`
     - `PrivacyService().clearSessionData()`
     - `context.read<AuthProvider>().exitGuestMode()`
   - Changed the target route in `pushAndRemoveUntil` to `WelcomeScreen()` with `(route) => false`.
2. **`lib/services/privacy_service.dart`**:
   - Refactored `PrivacyService` into a thread-safe singleton (`PrivacyService._internal()`) to ensure consistent in-memory session clearance across separate caller instances.

---

## 2. Bug 2: "Log Out" Left User on HomeScreen with Authenticated State

### Root Cause Analysis
- **Location**: `lib/screens/home_screen.dart:328-333`
- **Defect**: In the user profile bottom sheet, the logout action was implemented as:
  ```dart
  onPressed: () async {
    Navigator.of(ctx).pop();
    await auth.signOut();
  }
  ```
- **Consequence**: The app popped only the modal bottom sheet (`ctx`), leaving the underlying `HomeScreen` mounted and visible. The navigation stack was not cleared, and no route transition to `WelcomeScreen` was performed. Pressing the back button kept the user within the application context.

### Solution & Changes Made
1. **`lib/screens/home_screen.dart`**:
   - Updated the "Log Out" callback to:
     - Pop the profile modal sheet.
     - Clear in-memory session assessment data (`EligibilityProvider.clearResults()`, `UserProfileProvider.clearAllAnswers()`, `PrivacyService().clearSessionData()`).
     - Await `auth.signOut()`.
     - Completely clear the navigation stack using `pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false)`.
   - Updated the permanent account deletion action (`_confirmDeleteAccount`) with the identical stack-clearing and data-wipe sequence.
   - Added an active route guard in `HomeScreen.build`: if `!auth.isLoading && !auth.isAuthenticated && !auth.isGuest`, a post-frame callback immediately replaces the screen with `WelcomeScreen`, rendering a fallback loading indicator to prevent any stale view leaks.

---

## 3. Automated Test Verification

A dedicated regression test suite was created in `test/auth_session_bug_fixes_test.dart`:
1. `Bug 1: End Session & Clear wipes state, resets guest, and returns to WelcomeScreen`:
   - Populated assessment answers in `UserProfileProvider`, `EligibilityProvider`, and `PrivacyService`.
   - Opened `PrivacyDialog` and clicked "End Session".
   - Verified that `WelcomeScreen` is mounted.
   - Verified that all in-memory answers and session states are empty.
   - Verified that `authProvider.isGuest` is `false`.
   - Verified that `NavigatorState.canPop()` is `false` (back navigation cannot return to previous screens).
2. `Bug 2: Log Out clears session state, auth state, and returns to WelcomeScreen`:
   - Simulated an authenticated user session on `HomeScreen`.
   - Opened profile sheet and tapped "Log Out".
   - Verified that `WelcomeScreen` is mounted.
   - Verified that `authProvider.isAuthenticated` is `false`.
   - Verified that `PrivacyService` and assessment state are wiped.
   - Verified that `NavigatorState.canPop()` is `false`.

### Test Results
- `flutter test test/auth_session_bug_fixes_test.dart`: **2/2 passed**
- `flutter test test/`: **103/103 passed**
- `flutter analyze`: **0 issues found**

