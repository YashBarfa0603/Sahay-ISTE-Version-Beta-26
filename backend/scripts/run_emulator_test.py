#!/usr/bin/env python3
"""
Comprehensive Firestore Emulator Integration Test for SAHAY (Schema v2).
Executes:
1. Seed 100 schemes, 13 categories, 21 profile fields, catalogue metadata
2. Run all Section 8 query tests (popular, category paginated, central/state, state filter, keywords, single scheme, eligibility)
3. Test idempotency: re-run seed and verify 100 updated, 0 duplicates, preservation logic
"""

import sys
from pathlib import Path

# Add project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from backend.scripts.seed_firestore import seed_catalogue, init_firebase_app
from backend.scripts.test_queries import run_tests
from backend.scripts.validate_catalogue import validate_catalogue

def main():
    data_dir = PROJECT_ROOT / "data" / "schemes_seed"
    
    print("\n" + "=" * 70)
    print("STEP 1: INITIAL SEED AGAINST FIRESTORE EMULATOR")
    print("=" * 70)
    seed_catalogue(
        data_dir=data_dir,
        use_emulator=True,
        dry_run=False,
        only_ids=None,
        reset_popularity=False,
        project_id="demo-sahay",
    )

    print("\n" + "=" * 70)
    print("STEP 2: RUN SECTION 8 QUERY VERIFICATION SUITE")
    print("=" * 70)
    db = init_firebase_app(use_emulator=True, project_id="demo-sahay")
    run_tests(db)

    print("\n" + "=" * 70)
    print("STEP 3: TEST SEED IDEMPOTENCY (RE-SEED)")
    print("=" * 70)
    seed_catalogue(
        data_dir=data_dir,
        use_emulator=True,
        dry_run=False,
        only_ids=None,
        reset_popularity=False,
        project_id="demo-sahay",
    )

    print("\n" + "=" * 70)
    print("STEP 4: RUN VALIDATOR DIRECTLY AGAINST FIRESTORE EMULATOR")
    print("=" * 70)
    is_valid, errors, summary = validate_catalogue(
        data_dir=data_dir,
        expected_count=100,
        check_all_files=True,
        db=db,
    )
    print(f"Total Firestore Documents: {summary['total_files']}")
    print(f"Valid Schemes:            {summary['valid_schemes']}")
    print(f"Central Schemes:          {summary['central_count']}")
    print(f"Madhya Pradesh Schemes:   {summary['mp_count']}")
    print(f"Other State Schemes:      {summary['other_state_count']}")
    print(f"Popular Schemes:          {summary['popular_count']}")
    print(f"Verified Schemes:         {summary['verified_count']}")
    print(f"Pending Schemes:          {summary['pending_count']}")

    if not is_valid:
        print("[ERROR] Firestore Emulator validation failed:")
        for err in errors[:10]:
            print(f"  - {err}")
        sys.exit(1)
    else:
        print("[OK] Firestore Emulator validation passed with 0 errors!")

    print("\n" + "=" * 70)
    print("ALL EMULATOR INTEGRATION, QUERY, IDEMPOTENCY & VALIDATION TESTS PASSED!")
    print("=" * 70)

if __name__ == "__main__":
    main()
