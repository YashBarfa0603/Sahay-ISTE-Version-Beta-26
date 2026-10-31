# SAHAY — Manual Authentication Test Checklist

Use this checklist to manually verify all authentication, profile setup, and navigation flows on a physical device (iOS or Android) or simulator.

---

## Prerequisites
- Physical device or simulator connected (`flutter devices`).
- Firebase project configured: `sahay-8e9b3`.
- Android debug fingerprints registered in Firebase Console (if testing on Android).
- Support email set in Firebase Console -> Authentication -> Settings.

---

## 1. Welcome & Guest Access Flow

| Step | Action | Expected Behavior | Result |
| :--- | :--- | :--- | :--- |
| **1.1** | Launch app on clean install | `WelcomeScreen` renders mascot, localized greeting badge, "Get Started", and "Continue as Guest". | [ ] Pass |
| **1.2** | Toggle language to Hindi (हिंदी) | Greeting badge changes to "नमस्ते", title and button text update immediately. | [ ] Pass |
| **1.3** | Tap "Continue as Guest" | Navigates to `HomeScreen`. Guest banner appears under greeting: *"Guest mode: Sign in to save your eligible schemes"*. | [ ] Pass |
| **1.4** | Browse schemes as guest | Schemes catalog loads and opens detail screens without authentication errors. | [ ] Pass |
| **1.5** | Tap Profile tab (icon in bottom nav) | Bottom sheet opens showing **Browsing as a Guest** card with "Sign In / Sign Up" button. | [ ] Pass |
| **1.6** | Tap "Sign In / Sign Up" from guest sheet | Closes sheet and opens `LoginScreen`. | [ ] Pass |

---

## 2. Email & Password Sign-Up Flow

| Step | Action | Expected Behavior | Result |
| :--- | :--- | :--- | :--- |
| **2.1** | From `LoginScreen`, tap "Sign Up" | `SignupScreen` opens with inputs: Full Name, 10-digit Mobile, Email, Password, Confirm Password, Consent Checkbox. | [ ] Pass |
| **2.2** | Tap "Create Account" with blank fields | Field validation triggers: full name, mobile, email, and password required. | [ ] Pass |
| **2.3** | Enter invalid email format (`user@bad`) | Error message: *"Please enter a valid email address"*. | [ ] Pass |
| **2.4** | Enter short password (`pass1`) | Error message: *"Password must contain at least 8 characters..."*. | [ ] Pass |
| **2.5** | Enter mismatched passwords | Error message: *"Passwords do not match"*. | [ ] Pass |
| **2.6** | Enter valid data but leave terms unchecked | "Create Account" button remains disabled (dimmed). | [ ] Pass |
| **2.7** | Tap "Terms of Service & Privacy Policy" text | Modal bottom sheet opens detailing SAHAY's privacy and data protection principles. | [ ] Pass |
| **2.8** | Check the consent checkbox | "Create Account" button becomes active (solid teal). | [ ] Pass |
| **2.9** | Tap "Create Account" with valid data | Inline spinner appears. User created in Firebase Auth and Firestore `users/{uid}` stub profile created. `AuthGate` routes to `ProfileSetupScreen`. | [ ] Pass |

---

## 3. Mandatory Profile Setup Flow

| Step | Action | Expected Behavior | Result |
| :--- | :--- | :--- | :--- |
| **3.1** | Arrive on `ProfileSetupScreen` | Shows mandatory fields: Age, State dropdown, District, Occupation dropdown, Preferred Language. Optional: Gender, Residence Type. | [ ] Pass |
| **3.2** | Try submitting without Age or State | Form highlights missing mandatory fields with validation messages. | [ ] Pass |
| **3.3** | Inspect Occupation dropdown | Displays exactly 13 canonical occupations with localized labels (e.g. Farmer, Daily Wage Worker, etc.). | [ ] Pass |
| **3.4** | Fill mandatory fields and tap "Save Profile" | Inline spinner displays. Firestore profile updated with `profileComplete: true` and `updatedAt: request.time`. | [ ] Pass |
| **3.5** | Transition to `HomeScreen` | `AuthGate` automatically transitions to `HomeScreen`. Top greeting displays personalized name (e.g. *"Hello Rahul!"*). | [ ] Pass |

---

## 4. Google Sign-In Flow

| Step | Action | Expected Behavior | Result |
| :--- | :--- | :--- | :--- |
| **4.1** | From `LoginScreen`, tap "Continue with Google" | Google account picker sheet opens. | [ ] Pass |
| **4.2** | Dismiss / cancel the Google dialog | Picker closes quietly without any error banners or crashing. | [ ] Pass |
| **4.3** | First-time Google user selects account | Firebase Auth user created. Firestore stub created with `profileComplete: false`. Routed to `ProfileSetupScreen`. | [ ] Pass |
| **4.4** | Complete profile and log out | User signs out successfully, returning to `WelcomeScreen`. | [ ] Pass |
| **4.5** | Returning Google user selects account | Signed in directly to `HomeScreen` without asking for profile completion again. Existing profile data is preserved. | [ ] Pass |

---

## 5. Password Reset Flow

| Step | Action | Expected Behavior | Result |
| :--- | :--- | :--- | :--- |
| **5.1** | On `LoginScreen`, leave email empty and tap "Forgot Password?" | SnackBar prompts: *"Please enter your email address first"*. | [ ] Pass |
| **5.2** | Enter registered email and tap "Forgot Password?" | SnackBar displays confirmation: *"If this email is registered, a password reset link has been sent to it"*. | [ ] Pass |

---

## 6. Authenticated User Profile & Account Deletion

| Step | Action | Expected Behavior | Result |
| :--- | :--- | :--- | :--- |
| **6.1** | On `HomeScreen`, tap Profile bottom nav item | Sheet displays user's full name, email, mobile, and demographic chips (Age, State, District, Occupation, etc.). | [ ] Pass |
| **6.2** | Tap "Edit Optional Details" | Dialog opens allowing changes to Gender and Residence Type. Saving updates Firestore immediately. | [ ] Pass |
| **6.3** | Tap "Log Out" | User signed out from Firebase Auth and Google. `AuthGate` immediately resets to `WelcomeScreen`. | [ ] Pass |
| **6.4** | Log back in, tap "Delete Account" | Confirmation dialog warns that profile and account will be permanently deleted. | [ ] Pass |
| **6.5** | Confirm deletion | Deletes Firestore document `users/{uid}` and Firebase Auth record. Returns to `WelcomeScreen`. | [ ] Pass |

