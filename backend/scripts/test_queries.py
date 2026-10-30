#!/usr/bin/env python3
"""
Test queries specified in Section 8 against Cloud Firestore (Emulator or Live).
Validates:
1. Popular schemes (isPopular == true, verificationStatus == verified, orderBy popularityRank, limit 10)
2. Category list (category == X, orderBy nameLower, paginated)
3. Central vs state (governmentLevel == X, orderBy nameLower, paginated)
4. For a user's state (applicableStates array-contains-any [STATE, ALL_INDIA], orderBy nameLower, paginated)
5. Keyword search (searchKeywords array-contains-any [tokens])
6. Single scheme by schemeId
7. Eligibility-ready schemes (eligibilityEnabled == true)
"""

import argparse
import os
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

def init_firestore(use_emulator: bool = True, project_id: str = "demo-sahay"):
    if use_emulator:
        if "FIRESTORE_EMULATOR_HOST" not in os.environ:
            os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
        print(f"[*] Connecting to Firestore Emulator at {os.environ['FIRESTORE_EMULATOR_HOST']}")
        from google.cloud import firestore as gc_firestore
        from google.auth.credentials import AnonymousCredentials
        return gc_firestore.Client(project=project_id, credentials=AnonymousCredentials())
    else:
        cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            if not firebase_admin._apps:
                firebase_admin.initialize_app(cred, {"projectId": project_id})
        else:
            if not firebase_admin._apps:
                firebase_admin.initialize_app(options={"projectId": project_id})
        return firestore.client()

def run_tests(db):
    print("=" * 65)
    print("Running SAHAY Query Verification Suite (Section 8)")
    print("=" * 65)

    # 1. Popular schemes
    print("\n[Query 1] Popular schemes (isPopular == True, verificationStatus == 'verified', orderBy popularityRank, limit 10)")
    q1 = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("isPopular", "==", True))
        .where(filter=firestore.FieldFilter("verificationStatus", "==", "verified"))
        .order_by("popularityRank")
        .limit(10)
    )
    docs1 = list(q1.stream())
    print(f"  -> Returned {len(docs1)} popular schemes:")
    ranks = []
    for d in docs1:
        data = d.to_dict()
        rank = data.get("popularityRank")
        ranks.append(rank)
        print(f"     Rank {rank}: {d.id} - {data.get('name')[:40]}...")
    assert len(docs1) == 10, f"Expected 10 popular schemes, got {len(docs1)}"
    assert ranks == list(range(1, 11)), f"Expected ranks 1..10, got {ranks}"
    print("  [OK] Query 1 passed.")

    # 2. Category list with pagination
    print("\n[Query 2] Category list (category == 'agriculture', orderBy nameLower, paginated)")
    page_size = 5
    q2_page1 = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("category", "==", "agriculture"))
        .order_by("nameLower")
        .limit(page_size)
    )
    docs2_p1 = list(q2_page1.stream())
    print(f"  -> Page 1 returned {len(docs2_p1)} agriculture schemes:")
    for d in docs2_p1:
        print(f"     - {d.id} ({d.to_dict().get('nameLower')[:35]})")
    assert len(docs2_p1) == page_size, f"Expected {page_size} docs on page 1"

    last_doc = docs2_p1[-1]
    q2_page2 = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("category", "==", "agriculture"))
        .order_by("nameLower")
        .start_after(last_doc)
        .limit(page_size)
    )
    docs2_p2 = list(q2_page2.stream())
    print(f"  -> Page 2 (cursor after {last_doc.id}) returned {len(docs2_p2)} schemes:")
    for d in docs2_p2:
        print(f"     - {d.id} ({d.to_dict().get('nameLower')[:35]})")
    assert len(docs2_p2) > 0, "Page 2 should return next page of schemes"
    print("  [OK] Query 2 passed with cursor pagination.")

    # 3. Central vs State
    print("\n[Query 3] Central vs State (governmentLevel == 'central' vs 'state')")
    q3_central = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("governmentLevel", "==", "central"))
        .order_by("nameLower")
        .limit(5)
    )
    docs3_c = list(q3_central.stream())
    print(f"  -> Central schemes (limit 5): {[d.id for d in docs3_c]}")
    assert len(docs3_c) == 5

    q3_state = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("governmentLevel", "==", "state"))
        .order_by("nameLower")
        .limit(5)
    )
    docs3_s = list(q3_state.stream())
    print(f"  -> State schemes (limit 5): {[d.id for d in docs3_s]}")
    assert len(docs3_s) == 5
    print("  [OK] Query 3 passed.")

    # 4. For a user's state (MP and ALL_INDIA)
    print("\n[Query 4] For a user's state (applicableStates array-contains-any ['MP', 'ALL_INDIA'], orderBy nameLower)")
    q4 = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("applicableStates", "array_contains_any", ["MP", "ALL_INDIA"]))
        .order_by("nameLower")
        .limit(10)
    )
    docs4 = list(q4.stream())
    print(f"  -> Found {len(docs4)} schemes applicable to MP user (limit 10):")
    for d in docs4:
        st = d.to_dict().get("applicableStates")
        print(f"     - {d.id} states: {st}")
    assert len(docs4) == 10
    print("  [OK] Query 4 passed.")

    # 5. Keyword search
    print("\n[Query 5] Keyword search (searchKeywords array-contains-any ['kisan', 'farmer'])")
    q5 = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("searchKeywords", "array_contains_any", ["kisan", "farmer"]))
        .limit(5)
    )
    docs5 = list(q5.stream())
    print(f"  -> Found {len(docs5)} schemes matching keyword search:")
    for d in docs5:
        print(f"     - {d.id}: {d.to_dict().get('name')[:40]}")
    assert len(docs5) > 0
    print("  [OK] Query 5 passed.")

    # 6. Single scheme by schemeId
    print("\n[Query 6] Single scheme lookup by schemeId ('PM_KISAN_001')")
    doc6 = db.collection("schemes").document("PM_KISAN_001").get()
    assert doc6.exists, "PM_KISAN_001 must exist"
    data6 = doc6.to_dict()
    print(f"  -> Loaded {doc6.id}: '{data6.get('name')}', Category: {data6.get('category')}")
    print(f"     Rules: {len(data6.get('eligibilityRules', []))}, Documents: {len(data6.get('requiredDocuments', []))}")
    print("  [OK] Query 6 passed.")

    # 7. Eligibility-ready schemes
    print("\n[Query 7] Eligibility-ready schemes (eligibilityEnabled == True)")
    q7 = (
        db.collection("schemes")
        .where(filter=firestore.FieldFilter("eligibilityEnabled", "==", True))
    )
    docs7 = list(q7.stream())
    print(f"  -> Found {len(docs7)} eligibility-ready schemes.")
    assert len(docs7) == 0, f"Expected 0 eligibility-enabled schemes (Rule 5 invariant), found {len(docs7)}"
    print("  [OK] Query 7 passed (Confirmed strict safety invariant: 0 eligibility-enabled schemes).")

    # 8. Categories collection and appConfig
    print("\n[Bonus Checks] Categories & appConfig metadata verification")
    cats = list(db.collection("categories").stream())
    print(f"  -> Found {len(cats)} categories in Firestore:")
    for c in cats[:3]:
        cd = c.to_dict()
        print(f"     - {c.id}: {cd.get('name')} (schemeCount: {cd.get('schemeCount')})")
    assert len(cats) == 13, f"Expected 13 categories, got {len(cats)}"

    app_catalogue = db.collection("appConfig").document("catalogue").get()
    assert app_catalogue.exists, "appConfig/catalogue must exist"
    meta = app_catalogue.to_dict()
    print(f"  -> appConfig/catalogue metadata: {meta}")
    assert meta.get("totalSchemes") == 100, f"Expected 100 totalSchemes, got {meta.get('totalSchemes')}"

    app_pf = db.collection("appConfig").document("profileFields").get()
    assert app_pf.exists, "appConfig/profileFields must exist"
    print(f"  -> appConfig/profileFields: {len(app_pf.to_dict().get('fields', []))} fields.")

    print("\n" + "=" * 65)
    print("ALL 7 QUERIES AND METADATA CHECKS PASSED SUCCESSFULLY!")
    print("=" * 65)

def main():
    parser = argparse.ArgumentParser(description="Test Section 8 Firestore Queries")
    parser.add_argument("--live", action="store_true", help="Run against live Cloud Firestore instead of emulator")
    parser.add_argument("--project", type=str, default="sahay-emulator", help="Project ID")
    args = parser.parse_args()

    db = init_firestore(use_emulator=not args.live, project_id=args.project)
    run_tests(db)

if __name__ == "__main__":
    main()
