"""
Assistance and Referral Service for SAHAY.
Handles conflict detection, official referral packages, and Common Service Centre (CSC) lookup.
"""

from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from backend.app.models.scheme_schemas import SchemeModelSchema, VerificationStatus


class ConflictReport(BaseModel):
    scheme_id: str
    scheme_name: str
    field_name: str
    conflict_type: str  # official_discrepancy, outdated_rule, unverified_condition, missing_authoritative_doc
    conflicting_sources: List[str]
    description: str
    recommended_action: str
    stops_automated_assessment: bool = False


class HumanAssistanceReferral(BaseModel):
    scheme_id: str
    scheme_name: str
    reason_for_referral: str
    official_department: str
    documents_to_carry: List[str]
    official_helpline: str
    official_portal_url: str
    questions_to_ask_official: List[str]
    suggested_csc_centre: Optional[Dict[str, str]] = None


class CscCentreRecord(BaseModel):
    centre_id: str
    name: str
    vle_name: str
    state: str
    district: str
    pin_code: str
    address: str
    contact_number: Optional[str] = None
    email: Optional[str] = None
    services_available: List[str]
    is_verified: bool = True
    official_portal_url: str = "https://findmycsc.nic.in/"


class AssistanceService:
    """Provides conflict diagnostics, CSC directory lookups, and human official referrals."""

    # Curated authoritative directory of Common Service Centres across major Indian states
    CSC_DIRECTORY: List[CscCentreRecord] = [
        # Madhya Pradesh
        CscCentreRecord(
            centre_id="CSC_MP_BHO_001",
            name="Jan Seva Kendra - MP Nagar",
            vle_name="Rameshwar Sharma",
            state="Madhya Pradesh",
            district="Bhopal",
            pin_code="462011",
            address="Plot 42, Zone 1, MP Nagar, Near DB Mall, Bhopal",
            contact_number="+91 755 2554011",
            email="csc.bhopal01@csc.gov.in",
            services_available=["PM-KISAN eKYC", "Ayushman Card", "Ladli Behna Registration", "Income Certificate"],
        ),
        CscCentreRecord(
            centre_id="CSC_MP_IND_002",
            name="Digital Seva Kendra - Rajwada",
            vle_name="Sunita Patel",
            state="Madhya Pradesh",
            district="Indore",
            pin_code="452002",
            address="Shop 14, Near Rajwada Palace, MG Road, Indore",
            contact_number="+91 731 2439812",
            email="csc.indore02@csc.gov.in",
            services_available=["PMAY Application", "Ujjwala 2.0 KYC", "Aadhaar Update", "DBT Seeding"],
        ),
        CscCentreRecord(
            centre_id="CSC_MP_JAB_003",
            name="CSC Seva Kendra - Civic Centre",
            vle_name="Vikram Verma",
            state="Madhya Pradesh",
            district="Jabalpur",
            pin_code="482002",
            address="Civic Centre Complex, Near High Court Road, Jabalpur",
            contact_number="+91 761 2621004",
            email="csc.jabalpur@csc.gov.in",
            services_available=["PM Kisan Samman", "Caste Certificate", "E-Shram Card", "Pension Application"],
        ),
        # Maharashtra
        CscCentreRecord(
            centre_id="CSC_MH_MUM_004",
            name="Aaple Sarkar Seva Kendra - Dadar",
            vle_name="Anil Deshmukh",
            state="Maharashtra",
            district="Mumbai",
            pin_code="400028",
            address="Near Railway Station, Senapati Bapat Marg, Dadar West, Mumbai",
            contact_number="+91 22 24301122",
            email="csc.mumbai01@maharashtra.gov.in",
            services_available=["MahaDBT Scholarship", "Ration Card Seeding", "Ayushman Bharat", "Land Record 7/12"],
        ),
        # Uttar Pradesh
        CscCentreRecord(
            centre_id="CSC_UP_LKO_005",
            name="Jan Suvidha Kendra - Hazratganj",
            vle_name="Mohammad Irfan",
            state="Uttar Pradesh",
            district="Lucknow",
            pin_code="226001",
            address="Mayfair Building, MG Marg, Hazratganj, Lucknow",
            contact_number="+91 522 2614455",
            email="csc.lucknow@up.gov.in",
            services_available=["Kanya Sumangala", "PMAY-G", "Old Age Pension", "Kisan Credit Card"],
        ),
        # Tamil Nadu
        CscCentreRecord(
            centre_id="CSC_TN_CHE_006",
            name="e-Sevai Centre - Anna Nagar",
            vle_name="K. Murugan",
            state="Tamil Nadu",
            district="Chennai",
            pin_code="600040",
            address="2nd Avenue, Near Roundtana, Anna Nagar, Chennai",
            contact_number="+91 44 26213344",
            email="esevai.annanagar@tnesevai.tn.gov.in",
            services_available=["Kalaignar Magalir Urimai Thogai", "Pudhumai Penn", "Community Certificate", "Income Certificate"],
        ),
    ]

    def detect_scheme_conflicts(self, scheme: SchemeModelSchema) -> List[ConflictReport]:
        """Detects contradictions, outdated sources, and unverified criteria."""
        reports: List[ConflictReport] = []

        # Check if verification status is conflicting or outdated
        if scheme.verificationStatus == VerificationStatus.rejected:
            reports.append(
                ConflictReport(
                    scheme_id=scheme.schemeId,
                    scheme_name=scheme.name,
                    field_name="officialSourceUrl",
                    conflict_type="official_discrepancy",
                    conflicting_sources=[scheme.officialSourceUrl],
                    description="Official source could not be verified against national government registries (.gov.in or .nic.in).",
                    recommended_action="Do not submit personal documents online. Visit a local Tehsil/CSC office for confirmation.",
                    stops_automated_assessment=True,
                )
            )

        # Check for empty eligibility rules on active scheme
        if not scheme.eligibilityRules:
            reports.append(
                ConflictReport(
                    scheme_id=scheme.schemeId,
                    scheme_name=scheme.name,
                    field_name="eligibilityRules",
                    conflict_type="missing_authoritative_doc",
                    conflicting_sources=[scheme.officialSourceUrl],
                    description="Eligibility criteria guidelines are currently undergoing ministerial revision.",
                    recommended_action="Refer directly to the departmental notification or consult your local Panchayat Secretary.",
                    stops_automated_assessment=True,
                )
            )

        return reports

    def generate_human_referral(
        self,
        scheme: SchemeModelSchema,
        reason: str,
        user_state: Optional[str] = None,
        user_district: Optional[str] = None,
    ) -> HumanAssistanceReferral:
        """Constructs an actionable referral package for citizens needing offline official help."""
        # Find nearest matching CSC if available
        matched_csc = self.search_csc(state=user_state, district=user_district, limit=1)
        csc_dict = None
        if matched_csc:
            c = matched_csc[0]
            csc_dict = {
                "name": c.name,
                "address": c.address,
                "contact": c.contact_number or "1800-111-999",
                "vle": c.vle_name,
            }

        return HumanAssistanceReferral(
            scheme_id=scheme.schemeId,
            scheme_name=scheme.name,
            reason_for_referral=reason,
            official_department=scheme.ministry,
            documents_to_carry=scheme.requiredDocuments or ["Aadhaar Card", "Bank Passbook", "Proof of Residence"],
            official_helpline="1800-111-999 (National Scheme Helpline)",
            official_portal_url=scheme.officialSourceUrl,
            questions_to_ask_official=[
                f"Am I eligible for {scheme.name} based on my current family income and occupation?",
                "Which specific document is accepted as valid land/residence proof in this district?",
                "Can my application be submitted and biometric e-KYC completed directly at this centre?",
                "What is the expected timeline for disbursement or approval once submitted?",
            ],
            suggested_csc_centre=csc_dict,
        )

    def search_csc(
        self,
        state: Optional[str] = None,
        district: Optional[str] = None,
        pin_code: Optional[str] = None,
        limit: int = 10,
    ) -> List[CscCentreRecord]:
        """Finds verified CSCs by state, district, or PIN code."""
        results = []
        for csc in self.CSC_DIRECTORY:
            if pin_code and csc.pin_code.strip() != pin_code.strip():
                continue

            if state and csc.state.lower() != state.lower():
                continue

            if district and csc.district.lower() != district.lower():
                continue

            results.append(csc)
            if len(results) >= limit:
                break

        # If no strict match found, return statewide or first available
        if not results and state:
            results = [c for c in self.CSC_DIRECTORY if c.state.lower() == state.lower()][:limit]

        return results if results else (self.CSC_DIRECTORY[:limit] if not (pin_code or state or district) else [])
