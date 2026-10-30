#!/usr/bin/env python3
"""
Firestore Seeding Script for SAHAY (Schema v2).
Idempotent, human-decision preserving, validated via Pydantic before writing.
Supports Firestore Emulator and Cloud Firestore.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Set, Any, Optional, Tuple

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1 import DocumentSnapshot

# Add project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from backend.app.schemas.scheme_schema import (
    SchemeDocument,
    CategoryItem,
    ProfileFieldsConfig,
)
from backend.scripts.validate_catalogue import (
    EXPECTED_SCHEMES_SPEC,
    validate_scheme_dict,
)

EXPECTED_IDS = {s["schemeId"] for s in EXPECTED_SCHEMES_SPEC}


def parse_iso_datetime(val: Any) -> Optional[datetime]:
    """Converts ISO 8601 string or timestamp to UTC datetime."""
    if not val:
        return None
    if isinstance(val, datetime):
        return val
    if isinstance(val, str):
        try:
            # Handle ISO formats like 2026-10-31T01:00:00Z or +05:30
            dt = datetime.fromisoformat(val.replace("Z", "+00:00"))
            return dt.astimezone(timezone.utc)
        except Exception:
            return None
    return None


def init_firebase_app(use_emulator: bool, project_id: Optional[str] = None):
    """Initializes Firebase Admin SDK with emulator or explicit credentials."""
    if use_emulator:
        if "FIRESTORE_EMULATOR_HOST" not in os.environ:
            os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
        print(f"[*] Running against Firestore Emulator: {os.environ['FIRESTORE_EMULATOR_HOST']}")
        proj = project_id or "demo-sahay"
        from google.cloud import firestore as gc_firestore
        from google.auth.credentials import AnonymousCredentials
        db = gc_firestore.Client(project=proj, credentials=AnonymousCredentials())
        return db
    else:
        # Check Application Default Credentials or GOOGLE_APPLICATION_CREDENTIALS
        cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path and os.path.exists(cred_path):
            print(f"[*] Authenticating with service account at: {cred_path}")
            cred = credentials.Certificate(cred_path)
            options = {"projectId": project_id} if project_id else None
            if not firebase_admin._apps:
                firebase_admin.initialize_app(cred, options)
        else:
            print("[*] Authenticating with Application Default Credentials (ADC)...")
            options = {"projectId": project_id} if project_id else None
            if not firebase_admin._apps:
                firebase_admin.initialize_app(options=options)

        db = firestore.client()
        return db


def merge_and_preserve(
    existing: Dict[str, Any],
    new_doc: Dict[str, Any],
    reset_popularity: bool = False,
) -> Tuple[Dict[str, Any], List[str]]:
    """
    Implements rule 9 / section 9:
    Preserve human decisions on re-seed.
    """
    merged = dict(new_doc)
    preserved_fields = []

    # 1. Never overwrite human verified rules or status
    human_locked_fields = [
        "rulesVerificationStatus",
        "eligibilityEnabled",
        "eligibilityRules",
        "ruleStages",
        "rulesComplete",
        "createdAt",
    ]
    for field in human_locked_fields:
        if field in existing and existing[field] is not None:
            merged[field] = existing[field]
            preserved_fields.append(field)

    # 2. If human verified the catalogue content, preserve their verification
    if existing.get("verifiedBy") == "human":
        for field in ["verificationStatus", "verifiedBy", "lastVerified"]:
            if field in existing:
                merged[field] = existing[field]
                preserved_fields.append(f"{field}(human)")

    # 3. Popularity preservation unless reset requested
    if not reset_popularity:
        if "isPopular" in existing:
            merged["isPopular"] = existing["isPopular"]
            preserved_fields.append("isPopular")
        if "popularityRank" in existing:
            merged["popularityRank"] = existing["popularityRank"]
            preserved_fields.append("popularityRank")

    return merged, preserved_fields


def convert_datetimes_to_timestamps(data: Dict[str, Any]) -> Dict[str, Any]:
    """Recursively converts ISO strings or datetime objects to Firestore Timestamps."""
    res = {}
    for k, v in data.items():
        if k in ("createdAt", "updatedAt", "lastVerified", "discoveredAt"):
            if v is not None:
                dt = parse_iso_datetime(v)
                res[k] = dt if dt else v
            else:
                res[k] = None
        elif isinstance(v, dict):
            res[k] = convert_datetimes_to_timestamps(v)
        elif isinstance(v, list):
            res[k] = [
                convert_datetimes_to_timestamps(item) if isinstance(item, dict) else item
                for item in v
            ]
        else:
            res[k] = v
    return res


def seed_catalogue(
    data_dir: Path,
    use_emulator: bool = False,
    dry_run: bool = False,
    only_ids: Optional[Set[str]] = None,
    reset_popularity: bool = False,
    project_id: Optional[str] = None,
):
    print("=" * 65)
    print("SAHAY Scheme Catalogue Firestore Seeder (Schema v2)")
    print(f"Data directory:   {data_dir}")
    print(f"Target:           {'Emulator' if use_emulator else 'Cloud Firestore'}")
    print(f"Dry Run:          {dry_run}")
    print(f"Filter (only):    {sorted(only_ids) if only_ids else 'All 100 schemes'}")
    print(f"Reset Popularity: {reset_popularity}")
    print("=" * 65)

    # 1. Load categories and profile fields
    categories_file = data_dir / "_categories.json"
    profile_fields_file = data_dir / "_profile_fields.json"

    if not categories_file.exists():
        raise FileNotFoundError(f"Missing {categories_file}")
    if not profile_fields_file.exists():
        raise FileNotFoundError(f"Missing {profile_fields_file}")

    with open(categories_file, "r", encoding="utf-8") as f:
        categories_list = json.load(f)

    with open(profile_fields_file, "r", encoding="utf-8") as f:
        profile_fields_data = json.load(f)

    profile_field_keys = {pf["key"] for pf in profile_fields_data.get("fields", [])}
    category_keys = {cat["categoryId"] for cat in categories_list}

    # 2. Load and validate local scheme files
    scheme_files = list(data_dir.glob("*.json"))
    scheme_files = [p for p in scheme_files if not p.name.startswith("_")]

    if only_ids:
        scheme_files = [p for p in scheme_files if p.stem in only_ids]

    print(f"[*] Found {len(scheme_files)} scheme files to process.")

    validated_docs: Dict[str, Dict[str, Any]] = {}
    category_counts: Dict[str, int] = {cat: 0 for cat in category_keys}
    central_count = 0
    state_count = 0

    for p in scheme_files:
        scheme_id = p.stem
        if scheme_id not in EXPECTED_IDS:
            print(f"[!] Skipping unknown file not in Section 7 list: {p.name}")
            continue

        with open(p, "r", encoding="utf-8") as f:
            raw_data = json.load(f)

        errors = validate_scheme_dict(raw_data, profile_field_keys, category_keys)
        if errors:
            print(f"[ERROR] Validation failed for {scheme_id}:")
            for err in errors:
                print(f"  - {err}")
            raise ValueError(f"Aborting seed due to schema errors in {scheme_id}")

        validated_docs[scheme_id] = raw_data
        cat = raw_data.get("category")
        if cat in category_counts:
            category_counts[cat] += 1
        if raw_data.get("governmentLevel") == "central":
            central_count += 1
        else:
            state_count += 1

    print(f"[*] Successfully validated {len(validated_docs)} scheme documents against Pydantic schema v2.")

    if dry_run:
        print("\n[DRY-RUN SUMMARY]")
        print(f"Schemes to write/update: {len(validated_docs)}")
        print(f"  Central schemes:       {central_count}")
        print(f"  State schemes:         {state_count}")
        print(f"Categories to seed:      {len(categories_list)}")
        print(f"Profile fields to seed:  {len(profile_fields_data.get('fields', []))}")
        print("Dry run completed without performing any database writes.")
        return

    # 3. Connect to Firestore
    db = init_firebase_app(use_emulator, project_id)

    # 4. Seed categories
    print("\n[*] Seeding controlled categories...")
    batch = db.batch()
    batch_count = 0
    now = datetime.now(timezone.utc)

    for cat in categories_list:
        cat_id = cat["categoryId"]
        cat_data = dict(cat)
        cat_data["schemeCount"] = category_counts.get(cat_id, 0)
        cat_data["updatedAt"] = now
        cat_ref = db.collection("categories").document(cat_id)
        # Set createdAt if not present
        existing_cat = cat_ref.get()
        if existing_cat.exists:
            cat_data["createdAt"] = existing_cat.to_dict().get("createdAt", now)
        else:
            cat_data["createdAt"] = now

        batch.set(cat_ref, cat_data)
        batch_count += 1

    batch.commit()
    print(f"[OK] Successfully seeded {len(categories_list)} categories with calculated scheme counts.")

    # 5. Seed appConfig/profileFields
    print("[*] Seeding appConfig/profileFields...")
    pf_ref = db.collection("appConfig").document("profileFields")
    pf_ref.set(profile_fields_data)
    print("[OK] Successfully seeded appConfig/profileFields.")

    # 6. Seed schemes (idempotent, batch size <= 500)
    print("\n[*] Seeding schemes into Cloud Firestore...")
    created_count = 0
    updated_count = 0
    skipped_discovered = 0

    batch = db.batch()
    batch_ops = 0

    for scheme_id, doc_data in validated_docs.items():
        doc_ref = db.collection("schemes").document(scheme_id)
        existing_snap = doc_ref.get()

        if existing_snap.exists:
            existing_data = existing_snap.to_dict()
            # NEVER touch discovered documents
            if existing_data.get("sourceType") == "discovered":
                print(f"[-] Skipping discovered scheme: {scheme_id} (never modified by seed)")
                skipped_discovered += 1
                continue

            merged_data, preserved = merge_and_preserve(existing_data, doc_data, reset_popularity)
            merged_data["updatedAt"] = now
            if preserved:
                print(f"[~] Updating {scheme_id} (Preserved human/existing: {', '.join(preserved)})")
            else:
                print(f"[~] Updating {scheme_id}")

            data_to_save = convert_datetimes_to_timestamps(merged_data)
            batch.set(doc_ref, data_to_save)
            updated_count += 1
        else:
            print(f"[+] Creating {scheme_id}")
            doc_data["createdAt"] = now
            doc_data["updatedAt"] = now
            data_to_save = convert_datetimes_to_timestamps(doc_data)
            batch.set(doc_ref, data_to_save)
            created_count += 1

        batch_ops += 1
        if batch_ops >= 450:
            batch.commit()
            batch = db.batch()
            batch_ops = 0

    if batch_ops > 0:
        batch.commit()

    # 7. Seed appConfig/catalogue metadata
    print("\n[*] Writing catalogue metadata to appConfig/catalogue...")
    catalogue_ref = db.collection("appConfig").document("catalogue")
    catalogue_meta = {
        "version": 2,
        "totalSchemes": len(validated_docs),
        "centralCount": central_count,
        "stateCount": state_count,
        "lastSeededAt": now,
        "categoriesCount": len(categories_list),
    }
    catalogue_ref.set(catalogue_meta)
    print("[OK] Catalogue metadata updated.")

    print("\n" + "=" * 65)
    print("SEEDING SUMMARY:")
    print(f"  Created Schemes:       {created_count}")
    print(f"  Updated Schemes:       {updated_count}")
    print(f"  Skipped Discovered:    {skipped_discovered}")
    print(f"  Categories Seeded:     {len(categories_list)}")
    print(f"  Profile Fields Seeded: {len(profile_fields_data.get('fields', []))}")
    print("=" * 65)


def main():
    parser = argparse.ArgumentParser(description="Seed Cloud Firestore Scheme Catalogue")
    parser.add_argument("--emulator", action="store_true", help="Target local Firestore emulator")
    parser.add_argument("--dry-run", action="store_true", help="Simulate seeding without database writes")
    parser.add_argument("--only", type=str, help="Comma-separated scheme IDs to seed")
    parser.add_argument("--reset-popularity", action="store_true", help="Reset popularity rankings")
    parser.add_argument("--project", type=str, help="Explicit Google Cloud / Firebase Project ID")
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=PROJECT_ROOT / "data" / "schemes_seed",
        help="Path to seed data directory",
    )
    args = parser.parse_args()

    only_set = {x.strip() for x in args.only.split(",")} if args.only else None

    seed_catalogue(
        data_dir=args.data_dir,
        use_emulator=args.emulator,
        dry_run=args.dry_run,
        only_ids=only_set,
        reset_popularity=args.reset_popularity,
        project_id=args.project,
    )


if __name__ == "__main__":
    main()

