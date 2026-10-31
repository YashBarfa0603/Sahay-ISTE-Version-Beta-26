# SAHAY — Authentication Architecture & Developer Notes

This document provides technical background, architectural decisions, and integration guidelines for SAHAY's authentication, user profile management, and Firestore security rules.

---

## 1. Architecture Overview

SAHAY adheres to a strict separation of concerns across data, domain, state, and presentation layers:

```
[Presentation Layer]
  AuthGate -> LoginScreen / SignupScreen / ProfileSetupScreen / WelcomeScreen / HomeScreen
     │
[State Layer]
  AuthProvider (ChangeNotifier, listens to stream, manages UI loading/error state)
     │
[Domain / Repository Layer]
  AuthRepository (Coordinates auth state with Firestore user profiles)
     ├── AuthService (Sole interface to FirebaseAuth and GoogleSignIn)
     └── UserService (Sole interface to Cloud Firestore users/{uid})
     │
[Data Models & Utilities]
  UserModel, AuthStrings, AuthErrorMapper, IndianStates, ProfileOptions, Validators
```

### Key Principles
1. **No Credentials in State or Logs**: Passwords and tokens exist only in transient controllers passed directly to Firebase. Errors are sanitized via `AuthErrorMapper` without echoing user input.
2. **Lazy Initialization**: `AuthService` and `UserService` use lazy getters for `FirebaseAuth.instance` and `FirebaseFirestore.instance`, allowing unit and widget tests to run in headless environments without crashing on uninitialized Firebase apps.
3. **Reactive Gateway**: `AuthGate` reacts directly to `currentUserProfileStream`, automatically directing between unauthenticated (`WelcomeScreen`), guest (`HomeScreen`), incomplete profile (`ProfileSetupScreen`), and authenticated complete (`HomeScreen`).

---

## 2. Canonical Occupation Identifiers

The user profile and eligibility assessment systems share 13 canonical occupation identifiers derived from the scheme catalogue seed (`_profile_fields.json`):

| Canonical Key | English Label | Hindi Label (हिंदी) |
| :--- | :--- | :--- |
| `farmer` | Farmer / Cultivator | किसान / कृषक |
| `agricultural_worker` | Agricultural Laborer | कृषि मजदूर |
| `unorganized_worker` | Informal / Unorganized Worker | असंगठित क्षेत्र का श्रमिक |
| `construction_worker` | Construction Worker | निर्माण मजदूर |
| `street_vendor` | Street Vendor / Hawker | स्ट्रीट वेंडर / रेहड़ी पटरी वाला |
| `artisan_craftsperson` | Artisan / Craftsperson | कारीगर / शिल्पकार |
| `student` | Student | विद्यार्थी / छात्र |
| `salaried_private` | Private Sector Employee | निजी क्षेत्र का कर्मचारी |
| `government_employee` | Government Employee | सरकारी कर्मचारी |
| `self_employed_business`| Business Owner / Self-Employed | व्यवसायी / स्वरोजगार |
| `homemaker` | Homemaker | गृहिणी |
| `unemployed` | Unemployed / Job Seeker | बेरोजगार / नौकरी की तलाश में |
| `retired` | Retired Senior Citizen | सेवानिवृत्त / वरिष्ठ नागरिक |

Display labels are translated across all 8 supported languages (`en`, `hi`, `ta`, `mr`, `bn`, `gu`, `kn`, `or`) via [`ProfileOptions`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/utils/profile_options.dart), while database queries and rules strictly store the canonical keys.

---

## 3. Security Rules & Data Protection

[`firestore.rules`](file:///Users/yash/PROJECTS/MANIT/sahay/firestore.rules) guarantees complete citizen privacy:
- **Public Schemes**: `/schemes`, `/categories`, and `/appConfig` allow public read access for all citizens, including guests. Client writes are forbidden.
- **Strict Profile Isolation**: A user can only access `/users/{uid}` where `request.auth.uid == uid`. Guests cannot read or write any user records.
- **Forbidden Fields**: The rule explicitly rejects any write containing sensitive identity or financial information:
  `aadhaar`, `aadhaarNumber`, `pan`, `panNumber`, `bank`, `bankAccount`, `bankDetails`, `accountNumber`, `ifsc`, `income`, `annualIncome`, `salary`.
- **Server Timestamps**: `createdAt` and `updatedAt` are validated against `request.time`.
- **Immutable Fields on Update**: `uid`, `email`, `authProvider`, `consentAcceptedAt`, `consentVersion`, and `createdAt` cannot be altered once written.

---

## 4. How to Add Another Auth Provider (e.g. Apple or Phone)

To add another authentication provider in the future:

1. **Enable in Firebase Console**:
   - Navigate to **Authentication ➔ Sign-in method** and enable the provider (e.g., Apple).

2. **Add Provider Method in `AuthService`**:
   - In [`lib/services/auth_service.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/services/auth_service.dart), add the signing method (e.g. `signInWithApple()`) returning `Future<User?>`. Wrap errors in typed `AuthFailure`.

3. **Handle First-time vs Returning Profile in `AuthRepository`**:
   - In [`lib/repositories/auth_repository.dart`](file:///Users/yash/PROJECTS/MANIT/sahay/lib/repositories/auth_repository.dart):
     ```dart
     Future<UserModel?> signInWithApple() async {
       final user = await _authService.signInWithApple();
       if (user == null) return null;

       final existing = await _userService.getProfile(user.uid);
       if (existing != null) return existing;

       final stub = UserModel(
         uid: user.uid,
         fullName: user.displayName ?? '',
         email: user.email ?? '',
         mobileNumber: user.phoneNumber ?? '',
         authProvider: 'apple',
         profileComplete: false,
         consentAcceptedAt: DateTime.now(),
         consentVersion: '1.0',
       );
       await _userService.createProfile(stub);
       return stub;
     }
     ```

4. **Security Rules**:
   - The security rules in `firestore.rules` already allow `'apple'` and `'phone'` under `hasValidOptionalTypes`:
     ```javascript
     data.authProvider in ['google', 'phone', 'email', 'apple']
     ```

5. **Expose in `AuthProvider` & Wire UI**:
   - Add `authProvider.signInWithApple()` and add the button to `LoginScreen` and `SignupScreen`.

