# SAHAY Firestore Data Layer Specification (Schema v2)

This document specifies the Firestore data model, indexing strategy, query conventions, and Flutter Dart mapping for **SAHAY (सहाय)**.

---

## 1. Collections Architecture

| Collection / Path | Purpose | Access Policy | Seeded in Catalogue |
|---|---|---|---|
| `schemes/{schemeId}` | Curated & discovered scheme documents | Public Read, Admin Write Only | Yes (100 curated) |
| `categories/{categoryId}` | 13 controlled scheme categories | Public Read, Admin Write Only | Yes |
| `appConfig/profileFields` | Controlled vocabulary of citizen profile fields | Public Read, Admin Write Only | Yes |
| `appConfig/catalogue` | Metadata (counts, timestamps, version) | Public Read, Admin Write Only | Yes |
| `users/{userId}` | Citizen profiles & preferences | Owned by teammate | **No (Out of scope)** |
| `eligibility_assessments/{id}` | Citizen eligibility evaluations | Owned by teammate | **No (Out of scope)** |

---

## 2. Document Specification: `schemes/{schemeId}`

All fields use camelCase. Dates are stored as Firestore `Timestamp` objects.

| Field Name | Firestore Type | Nullable | Description & Invariants |
|---|---|---|---|
| `schemeId` | `String` | No | Unique document identifier (matches Firestore Doc ID). |
| `name` | `String` | No | Official English title of the scheme. |
| `nameHindi` | `String` | Yes | Official Hindi title (or vetted translation). |
| `description` | `String` | No | 1–3 concise sentences directly from official portal. |
| `descriptionHindi` | `String` | Yes | Hindi translation of description. |
| `category` | `String` | No | Document ID from `categories` collection (e.g., `agriculture`). |
| `tags` | `List<String>` | No | Controlled tags (e.g. `['farmers', 'rural']`). |
| `ministry` | `String` | Yes | Owning Central Ministry or State Department. |
| `governmentLevel` | `String` | No | Enum: `'central'` \| `'state'`. |
| `applicableStates` | `List<String>` | No | `['ALL_INDIA']` for central schemes, or state codes like `['MP']`. |
| `benefits` | `String` | No | Concise summary of financial or in-kind assistance. |
| `benefitsHindi` | `String` | Yes | Hindi translation of benefits. |
| `eligibilityText` | `String` | Yes | Plain-language human-readable criteria summary. |
| `eligibilityTextHindi` | `String` | Yes | Hindi criteria summary. |
| `eligibilityRules` | `List<Map>` | No | Structured rule list. Defaults to `[]`. |
| `ruleStages` | `List<Map>` | Yes | Staged eligibility decision trees (e.g., Ayushman PM-JAY). |
| `rulesComplete` | `bool` | No | `true` only if rules cover 100% of official mandatory conditions. |
| `rulesVerificationStatus` | `String` | No | `'unverified'` \| `'verified'`. Agent always sets `'unverified'`. |
| `eligibilityEnabled` | `bool` | No | Invariant: `rulesVerificationStatus == 'verified' && rulesComplete == true && rules.isNotEmpty`. Default `false`. |
| `requiredDocuments` | `List<String>` | No | Official list of necessary documents. Default `[]`. |
| `requiredDocumentsHindi` | `List<String>` | No | Hindi document list. Must match length of `requiredDocuments` or be `[]`. |
| `applicationProcess` | `String` | No | Numbered sequential steps to apply. |
| `applicationProcessHindi` | `String` | Yes | Hindi application steps. |
| `applicationUrl` | `String` | Yes | Direct official online application URL (`.gov.in` / `.nic.in`). |
| `officialSourceUrl` | `String` | Yes | Primary official portal or guidelines PDF URL. |
| `sourceName` | `String` | Yes | Name of official authority/portal. |
| `sourceUrls` | `List<String>` | No | All official URLs consulted. |
| `sourceType` | `String` | No | Enum: `'curated'` (catalogue seed) \| `'discovered'` (backend crawler). |
| `discoveredAt` | `Timestamp` | Yes | Timestamp if discovered by crawler; `null` for curated seed. |
| `verificationStatus` | `String` | No | Enum: `'verified'` \| `'pending'`. |
| `verifiedBy` | `String` | Yes | Enum: `'agent'` \| `'human'` \| `null`. |
| `status` | `String` | No | Enum: `'active'` \| `'inactive'` \| `'underVerification'`. |
| `lastVerified` | `Timestamp` | Yes | Last time facts were cross-checked with official portal. |
| `isPopular` | `bool` | No | `true` for Tier-1 home-screen featured schemes. |
| `popularityRank` | `int` | No | `1` to `10` for Tier-1, `0` for all others. |
| `searchKeywords` | `List<String>` | No | Lowercase tokens, acronyms, Hindi words (max 25). |
| `nameLower` | `String` | No | Lowercase title used for stable sorting and cursor pagination. |
| `dataQuality` | `Map` | No | `{hasBenefits, hasDocuments, hasRules, hasHindi, hindiReviewed, flags: []}` |
| `schemaVersion` | `int` | No | `2` |
| `createdAt` | `Timestamp` | No | Document creation time. |
| `updatedAt` | `Timestamp` | No | Last update time. |

---

## 3. Structured Eligibility Rule Model (`eligibilityRules[]`)

```json
{
  "field": "age",
  "operator": "greaterThanOrEqual",
  "value": 18,
  "isMandatory": true,
  "description": "Applicant must be at least 18 years old",
  "descriptionHindi": "आवेदक की आयु कम से कम 18 वर्ष होनी चाहिए",
  "sourceUrl": "https://pmkisan.gov.in/guidelines",
  "sourceQuote": "All landholding farmers families aged 18 and above are eligible."
}
```

Allowed operators:
- `equals`, `notEquals`, `greaterThan`, `greaterThanOrEqual`, `lessThan`, `lessThanOrEqual`
- `inList`, `notInList`
- `isTrue`, `isFalse` (with `value: null`)

---

## 4. Flutter `SchemeModel` Mapping & Required Client Updates

When consuming Firestore Schema v2 in Flutter, ensure your `SchemeModel` in `lib/models/scheme_model.dart` includes the following mappings.

### Firestore Field → Flutter Dart Model Field Mapping

| Firestore Field | Proposed Flutter Type | Notes for Flutter Developer |
|---|---|---|
| `schemeId` | `String id` | Document ID |
| `name` | `String name` | Official English title |
| `nameHindi` | `String? nameHindi` | **Add to model** for Hindi localization |
| `description` | `String description` | |
| `descriptionHindi` | `String? descriptionHindi` | **Add to model** |
| `category` | `String category` | Matches Category ID |
| `tags` | `List<String> tags` | **Add to model** for chips/filtering |
| `ministry` | `String? ministry` | |
| `governmentLevel` | `GovernmentLevel level` | Enum mapping (`'central'`, `'state'`) |
| `applicableStates` | `List<String> applicableStates` | Filter with citizen's state code |
| `benefits` | `String benefits` | |
| `benefitsHindi` | `String? benefitsHindi` | **Add to model** |
| `eligibilityText` | `String? eligibilityText` | **Add to model** for quick criteria card |
| `eligibilityTextHindi` | `String? eligibilityTextHindi` | **Add to model** |
| `eligibilityRules` | `List<EligibilityRule> eligibilityRules` | Flat deterministic rules |
| `ruleStages` | `List<RuleStage>? ruleStages` | **Add to model** for multi-step staged evaluation |
| `rulesComplete` | `bool rulesComplete` | **Add to model** |
| `rulesVerificationStatus`| `String rulesVerificationStatus` | **Add to model** (`'unverified'`, `'verified'`) |
| `eligibilityEnabled` | `bool eligibilityEnabled` | **Add to model**: only evaluate engine if `true` |
| `requiredDocuments` | `List<String> requiredDocuments` | Document checklist |
| `requiredDocumentsHindi`| `List<String> requiredDocumentsHindi`| **Add to model** |
| `applicationProcess` | `String applicationProcess` | Steps |
| `applicationProcessHindi`| `String? applicationProcessHindi` | **Add to model** |
| `applicationUrl` | `String? applicationUrl` | Open in browser / webview |
| `officialSourceUrl` | `String? officialSourceUrl` | Provenance link |
| `sourceName` | `String? sourceName` | |
| `sourceUrls` | `List<String> sourceUrls` | |
| `sourceType` | `String sourceType` | **Add to model** (`'curated'` or `'discovered'`) |
| `verificationStatus` | `String verificationStatus` | `'verified'` or `'pending'` |
| `verifiedBy` | `String? verifiedBy` | **Add to model** (`'agent'` or `'human'`) |
| `status` | `SchemeStatus status` | Enum (`'active'`, `'inactive'`, `'underVerification'`) |
| `lastVerified` | `DateTime? lastVerified` | Parsed from Firestore `Timestamp` |
| `isPopular` | `bool isPopular` | Featured list filter |
| `popularityRank` | `int popularityRank` | `1` to `10` sort order |
| `searchKeywords` | `List<String> searchKeywords` | |
| `nameLower` | `String nameLower` | Sorting and cursor key |
| `dataQuality` | `DataQuality dataQuality` | Map with flags and quality indicators |
| `schemaVersion` | `int schemaVersion` | Should equal `2` |
| `createdAt` | `DateTime createdAt` | Parsed from Firestore `Timestamp` |
| `updatedAt` | `DateTime updatedAt` | Parsed from Firestore `Timestamp` |

### Timestamp Handling in `fromMap`:
```dart
DateTime? _parseTimestamp(dynamic val) {
  if (val == null) return null;
  if (val is Timestamp) return val.toDate();
  if (val is String) return DateTime.tryParse(val);
  return null;
}
```

---

## 5. App Firestore Query Patterns & Composite Indexes

### Query 1: Popular Schemes on Home Screen
```dart
FirebaseFirestore.instance
    .collection('schemes')
    .where('isPopular', isEqualTo: true)
    .where('verificationStatus', isEqualTo: 'verified')
    .orderBy('popularityRank')
    .limit(10);
```

### Query 2: Schemes by Category with Cursor Pagination
```dart
Query query = FirebaseFirestore.instance
    .collection('schemes')
    .where('category', isEqualTo: selectedCategory)
    .orderBy('nameLower')
    .limit(pageSize);

if (lastDocument != null) {
  query = query.startAfterDocument(lastDocument);
}
```

### Query 3: State-Specific + All-India Eligibility Feed
```dart
// Fetch all schemes applicable to citizen's state OR all-India
FirebaseFirestore.instance
    .collection('schemes')
    .where('applicableStates', arrayContainsAny: [userStateCode, 'ALL_INDIA'])
    .orderBy('nameLower')
    .limit(pageSize);
```

### Query 4: Token-Based Keyword Search
```dart
FirebaseFirestore.instance
    .collection('schemes')
    .where('searchKeywords', arrayContainsAny: searchTokens.take(10).toList())
    .limit(20);
```

### Query Limitation Note & Workaround:
> **Firestore Constraint:** Cloud Firestore does NOT allow combining multiple `array-contains` or `array-contains-any` clauses in a single query (e.g. searching keywords AND filtering `applicableStates` at the same time).
> **Workaround:** Query Firestore using the state filter (`applicableStates arrayContainsAny [userState, 'ALL_INDIA']`), and perform token search client-side in Dart on the returned list, or query by keyword tokens and filter for state applicability in Dart.

