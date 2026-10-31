# SAHAY (सहाय) — Intelligent AI Scheme Discovery System

## 1. Executive Summary

The SAHAY Intelligent AI Scheme Discovery architecture implements a **Hybrid Discovery and Strict Verification Pipeline** that combines verified local/cloud government scheme catalogues with dynamic real-time web discovery powered by Tavily Search, BeautifulSoup scraping, and Qwen2.5 LLM extraction coordinated by LangGraph.

Citizens searching for welfare benefits are protected by strict provenance and credibility audits. Every scheme displayed in the interface explicitly communicates its verification status via unambiguous visual badges: **VERIFIED**, **PARTIALLY VERIFIED**, and **UNVERIFIED**.

---

## 2. System Architecture

```
                    ┌────────────────────────┐
                    │  Citizen Search Query   │
                    └───────────┬────────────┘
                                │
                                ▼
            ┌────────────────────────────────────────┐
            │ Stage 1: Trusted Scheme Catalogue     │
            │ (Cloud Firestore / Embedded 100 Seed)  │
            └───────────────────┬────────────────────┘
                                │
                 [Hits >= Threshold & !Forced?]
                                ├───► YES ──► Return Verified Results
                                │
                                ▼ NO
            ┌────────────────────────────────────────┐
            │ Stage 2: Tavily Search API Discovery   │
            │ Restrict to official gov/nic domains   │
            └───────────────────┬────────────────────┘
                                │
                                ▼
            ┌────────────────────────────────────────┐
            │ Stage 3: BeautifulSoup Scraping        │
            │ Extract HTML, text, guidelines, pdfs   │
            └───────────────────┬────────────────────┘
                                │
                                ▼
            ┌────────────────────────────────────────┐
            │ Stage 4: Qwen2.5 LLM Schema Extraction  │
            │ Transform raw text -> SchemeModelSchema│
            └───────────────────┬────────────────────┘
                                │
                                ▼
            ┌────────────────────────────────────────┐
            │ Stage 5: Verification & Authenticity   │
            │ Audit: Domain, Freshness, Duplication  │
            └───────────────────┬────────────────────┘
                                │
                                ▼
            ┌────────────────────────────────────────┐
            │ Stage 6: Client Display with Badges    │
            │ VERIFIED | PARTIALLY VERIFIED | UNVERIFIED
            └────────────────────────────────────────┘
```

---

## 3. The 10-Step Hybrid Discovery Pipeline

1. **Query Normalization**: User inputs search query (text or speech translated via STT) with optional state and category filters.
2. **Local/Firestore Lookup**: Database query against curated schemes (100 schemes catalogue across 60 Central and 40 State programs).
3. **Threshold Evaluation**: If matches satisfy user criteria and `forceDynamicDiscovery` is false, results are immediately returned from the verified cache with 0ms external latency.
4. **Autonomous External Search**: If results are below minimum threshold (`CATALOGUE_MIN_RESULTS = 3`) or citizen explicitly taps "AI Deep Scheme Discovery", the backend queries Tavily Search API restricted to trusted Indian government portals.
5. **Content Extraction**: Webpage content is fetched and sanitized using `BeautifulSoup` to strip script tags, styles, and navigational chrome.
6. **Structured Extraction**: The sanitized text is fed into `Qwen2.5` (via Ollama or local inference) to parse title, Hindi title, department, benefits, eligibility rules, and required documents.
7. **Verification Audit**:
   - **Domain Check**: Verifies that the source belongs to `.gov.in`, `.nic.in`, or official state portal.
   - **Freshness Check**: Verifies publication date or active program timeline.
   - **Completeness Check**: Asserts mandatory presence of benefit statements and core document checklists.
   - **Duplicate Detection**: Computes token similarity against existing 100 curated schemes to prevent duplicate entries.
8. **Status Assignment**:
   - If domain check fails or source is untrusted: marked `rejected` or `unverified`.
   - If discovered from government domain: marked `pending` with `sourceType = discovered`.
9. **Persistence & Queueing**: Discovered records are queued into the administrative review staging collection.
10. **Delivery to Client**: Result list returned to Flutter app with transparent badge status.

---

## 4. Visual Verification Badge System

Every scheme card in `lib/screens/schemes_screen.dart` renders a distinctive Material 3 verification status pill:

| Badge Status | Visual Pill Color | Icon | Criteria | Localized Label (HI) |
| :--- | :--- | :--- | :--- | :--- |
| **VERIFIED** | Green (`#2E7D32` on `#E8F5E9`) | `Icons.verified_rounded` | Curated scheme with verified official gazette/portal URL (`.gov.in` / `.nic.in`) | प्रमाणित |
| **PARTIALLY VERIFIED** | Amber (`#E65100` on `#FFF3E0`) | `Icons.warning_amber_rounded` | Government domain source discovered by AI, pending administrative manual sign-off | आंशिक |
| **UNVERIFIED** | Muted Coral (`#C62828` on `#FFEBEE`) | `Icons.help_outline_rounded` | Third-party source, news bulletin, or user-reported scheme | गैर-प्रमाणित |

---

## 5. Security & Hallucination Mitigation Safeguards

1. **No Silent Upgrades**: Discovered schemes are **never** automatically marked as `VERIFIED`. Only human administrators or pre-curated gazette records hold `VERIFIED` status.
2. **Explicit Citizen Warning**: Newly discovered schemes display an in-app caution banner alerting citizens that the scheme is under departmental verification before they submit sensitive records.
3. **No Credential Phishing**: Application URLs in unverified schemes are locked to external browser launches with confirmation dialogs.
4. **Offline Resilience**: When backend services or external search APIs are unreachable, the Flutter client gracefully falls back to the embedded 100-scheme offline catalogue without throwing exceptions.

