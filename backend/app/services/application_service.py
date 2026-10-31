"""
Application Service: Central Coordinator for SAHAY Smart Application Filler.
Coordinates the 10 verified schemes, citizen information store with provenance,
document vault retrieval, EasyOCR extraction, missing field calculation,
sandboxed declarative portal population, and read-back verification.
"""

from datetime import datetime
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from backend.app.database.db_interface import InMemorySchemeDatabase
from backend.app.schemas.application_schema import (
    ApplicationSection,
    ApplicationSessionModel,
    ApplicationStatus,
    ApplicationValidationResponse,
    DocumentRequirement,
    DocumentVerificationStatus,
    FieldMapping,
    FieldType,
    MappingStatus,
    NormalizedCitizenProfile,
    PortalPopulationPayload,
    ReadBackFieldStatus,
    ReadBackVerificationReport,
    SchemeRegistryEntry,
    SourceType,
    ValueProvenance,
)
from backend.app.services.easyocr_service import EasyOCRService
from backend.app.services.portal_adapter_service import PortalAdapterService

logger = logging.getLogger(__name__)


class ApplicationService:
    """Manages 10-scheme smart application filler sessions, citizen profiles, and portal coordination."""

    def __init__(self, scheme_db: Optional[InMemorySchemeDatabase] = None):
        self.scheme_db = scheme_db or InMemorySchemeDatabase()
        self.ocr_service = EasyOCRService()
        self.portal_service = PortalAdapterService()
        # In-memory session store (keyed by session_id)
        self._sessions: Dict[str, ApplicationSessionModel] = {}
        # In-memory user documents vault (keyed by user_id)
        self._user_documents: Dict[str, List[Dict[str, Any]]] = {}

    # ==========================================
    # Registry & Availability
    # ==========================================

    def get_supported_schemes(self) -> List[SchemeRegistryEntry]:
        """Returns the central registry of the 10 verified smart application schemes."""
        return self.portal_service.get_supported_schemes_registry()

    def is_scheme_supported(self, scheme_id: str) -> bool:
        """Checks if a scheme is part of the 10-scheme smart application filler."""
        return self.portal_service.is_scheme_supported(scheme_id)

    # ==========================================
    # Citizen Information Normalization Layer
    # ==========================================

    def normalize_citizen_profile(
        self,
        user_id: str,
        raw_answers: Optional[Dict[str, Any]] = None,
        extracted_docs: Optional[List[Dict[str, Any]]] = None,
    ) -> NormalizedCitizenProfile:
        """
        Synthesizes a normalized citizen profile from profile answers and Document Vault OCR,
        attaching clear provenance to every single attribute.
        """
        raw = raw_answers or {}
        now_str = datetime.utcnow().isoformat()
        profile = NormalizedCitizenProfile(user_id=user_id)
        prov_map: Dict[str, ValueProvenance] = {}

        # 1. Personal Information
        name_val = raw.get("fullName") or raw.get("name")
        if name_val:
            profile.personal.full_name = str(name_val)
            prov_map["personal.full_name"] = ValueProvenance(
                field="personal.full_name",
                value=name_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        dob_val = raw.get("dob") or raw.get("dateOfBirth")
        if dob_val:
            profile.personal.dob = str(dob_val)
            prov_map["personal.dob"] = ValueProvenance(
                field="personal.dob",
                value=dob_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        gender_val = raw.get("gender")
        if gender_val:
            profile.personal.gender = str(gender_val)
            prov_map["personal.gender"] = ValueProvenance(
                field="personal.gender",
                value=gender_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        father_val = raw.get("fatherName") or raw.get("guardianName")
        if father_val:
            profile.personal.father_name = str(father_val)
            prov_map["personal.father_name"] = ValueProvenance(
                field="personal.father_name",
                value=father_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        # 2. Contact Information
        phone_val = raw.get("mobileNumber") or raw.get("phone")
        if phone_val:
            profile.contact.mobile_number = str(phone_val)
            prov_map["contact.mobile_number"] = ValueProvenance(
                field="contact.mobile_number",
                value=phone_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        email_val = raw.get("email") or raw.get("emailId")
        if email_val:
            profile.contact.email = str(email_val)
            prov_map["contact.email"] = ValueProvenance(
                field="contact.email",
                value=email_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        # 3. Address Information
        state_val = raw.get("state") or raw.get("stateOfResidence") or "Madhya Pradesh"
        profile.address.state = str(state_val)
        prov_map["address.state"] = ValueProvenance(
            field="address.state",
            value=state_val,
            source="user_profile",
            verification_status="self_reported",
            last_updated_at=now_str,
        )

        district_val = raw.get("district")
        if district_val:
            profile.address.district = str(district_val)
            prov_map["address.district"] = ValueProvenance(
                field="address.district",
                value=district_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        sub_dist = raw.get("subDistrict") or raw.get("tehsil")
        if sub_dist:
            profile.address.sub_district = str(sub_dist)
            prov_map["address.sub_district"] = ValueProvenance(
                field="address.sub_district",
                value=sub_dist,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        block_val = raw.get("block")
        if block_val:
            profile.address.block = str(block_val)
            prov_map["address.block"] = ValueProvenance(
                field="address.block",
                value=block_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        village_val = raw.get("village") or raw.get("city")
        if village_val:
            profile.address.village = str(village_val)
            profile.address.city = str(village_val)
            prov_map["address.village"] = ValueProvenance(
                field="address.village",
                value=village_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        pincode_val = raw.get("pincode") or raw.get("pinCode")
        if pincode_val:
            profile.address.pincode = str(pincode_val)
            prov_map["address.pincode"] = ValueProvenance(
                field="address.pincode",
                value=pincode_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        addr_val = raw.get("fullAddress") or raw.get("currentAddress")
        if addr_val:
            profile.address.full_address = str(addr_val)
            prov_map["address.full_address"] = ValueProvenance(
                field="address.full_address",
                value=addr_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        # 4. Social Information
        caste_val = raw.get("casteCategory") or raw.get("category") or raw.get("socialCategory")
        if caste_val:
            profile.social.caste_category = str(caste_val)
            prov_map["social.caste_category"] = ValueProvenance(
                field="social.caste_category",
                value=caste_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        marital_val = raw.get("maritalStatus")
        if marital_val:
            profile.social.marital_status = str(marital_val)
            prov_map["social.marital_status"] = ValueProvenance(
                field="social.marital_status",
                value=marital_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        if raw.get("hasDisability") in [True, "Yes", "true"]:
            profile.social.is_disabled = True
            profile.social.disability_type = raw.get("disabilityType", "Locomotor")
            profile.social.disability_percentage = int(raw.get("disabilityPercentage", 40))

        # 5. Financial Information
        income_val = raw.get("annualIncome") or raw.get("annualFamilyIncome")
        if income_val is not None:
            try:
                num_inc = int(float(str(income_val).replace(",", "").strip()))
                profile.financial.annual_income = num_inc
                profile.financial.household_income = num_inc
                prov_map["financial.annual_income"] = ValueProvenance(
                    field="financial.annual_income",
                    value=num_inc,
                    source="user_profile",
                    verification_status="self_reported",
                    last_updated_at=now_str,
                )
            except Exception:
                pass

        bank_acc = raw.get("bankAccountNumber") or raw.get("accountNumber")
        if bank_acc:
            profile.financial.bank_account_number = str(bank_acc)
            prov_map["financial.bank_account_number"] = ValueProvenance(
                field="financial.bank_account_number",
                value=bank_acc,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        ifsc_val = raw.get("ifscCode") or raw.get("ifsc")
        if ifsc_val:
            profile.financial.ifsc_code = str(ifsc_val).upper().strip()
            prov_map["financial.ifsc_code"] = ValueProvenance(
                field="financial.ifsc_code",
                value=ifsc_val,
                source="user_profile",
                verification_status="self_reported",
                last_updated_at=now_str,
            )

        # 6. Occupation & Business Information
        if raw.get("isFarmer") in [True, "Yes", "true"]:
            profile.occupation.is_farmer = True
        occ_val = raw.get("occupation") or raw.get("primaryOccupation")
        if occ_val:
            profile.occupation.occupation_name = str(occ_val)
        biz_val = raw.get("enterpriseName") or raw.get("businessName")
        if biz_val:
            profile.occupation.business_name = str(biz_val)

        # 7. Document OCR Integration (Aadhaar, PAN, Passbook, Income)
        for doc in (extracted_docs or []):
            d_type = doc.get("document_type")
            d_id = doc.get("document_id", d_type)
            fields = doc.get("fields", {})

            if d_type == "aadhaar_card":
                uid = fields.get("aadhaar_number", {}).get("value") if isinstance(fields.get("aadhaar_number"), dict) else fields.get("aadhaar_number")
                if uid:
                    prov_map["personal.aadhaar_number"] = ValueProvenance(
                        field="personal.aadhaar_number",
                        value=uid,
                        source="document_ocr",
                        verification_status="ocr_extracted",
                        source_document_id=d_id,
                        last_updated_at=now_str,
                    )
            elif d_type == "pan_card":
                pan = fields.get("pan_number", {}).get("value") if isinstance(fields.get("pan_number"), dict) else fields.get("pan_number")
                if pan:
                    prov_map["financial.pan_number"] = ValueProvenance(
                        field="financial.pan_number",
                        value=pan,
                        source="document_ocr",
                        verification_status="ocr_extracted",
                        source_document_id=d_id,
                        last_updated_at=now_str,
                    )
            elif d_type == "income_certificate":
                inc = fields.get("annual_income", {}).get("value") if isinstance(fields.get("annual_income"), dict) else fields.get("annual_income")
                if inc is not None:
                    # Note potential conflict if user profile also provided income
                    doc_inc = int(inc)
                    prov_map["financial.annual_income_doc"] = ValueProvenance(
                        field="financial.annual_income",
                        value=doc_inc,
                        source="document_ocr",
                        verification_status="ocr_extracted",
                        source_document_id=d_id,
                        last_updated_at=now_str,
                    )

        profile.provenance_map = prov_map
        return profile

    # ==========================================
    # Session Management (Resumable Workflow)
    # ==========================================

    def start_session(
        self,
        scheme_id: str,
        user_id: str,
        user_profile: Optional[Dict[str, Any]] = None,
        language: str = "en",
    ) -> ApplicationSessionModel:
        """
        Initializes or resumes an application assistant session for one of the 10 supported schemes.
        """
        # Verify scheme is supported in the 10-scheme registry
        entry = self.portal_service.get_entry_for_scheme(scheme_id)
        if not entry:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Scheme '{scheme_id}' is not currently configured in the SAHAY Smart Application Filler.",
            )

        # Check for existing resumable session
        for existing in self._sessions.values():
            if existing.user_id == user_id and existing.scheme_id == scheme_id and existing.status != ApplicationStatus.CANCELLED:
                logger.info(f"Resuming existing session {existing.session_id} for user {user_id}")
                return existing

        session_id = f"app_sess_{uuid.uuid4().hex[:12]}"
        now_str = datetime.utcnow().isoformat()

        # Ingest citizen data and documents
        docs = self._user_documents.get(user_id, [])
        normalized_profile = self.normalize_citizen_profile(user_id, user_profile, docs)

        # Build scheme-specific application sections and fields
        configs = self.portal_service.get_fields_config(scheme_id)
        sections = self._build_sections_for_scheme(scheme_id, configs, normalized_profile)

        # Prepare document requirements checklist
        doc_requirements = []
        for req in entry.requiredDocuments:
            doc_requirements.append(
                DocumentRequirement(
                    document_id=req,
                    document_name=req.replace("_", " ").title(),
                    is_mandatory=True,
                    status="missing",
                )
            )

        # Calculate initial missing fields count & conflict detection
        missing_count = sum(1 for sec in sections for f in sec.fields if f.is_required and (f.mapped_value is None or str(f.mapped_value).strip() == ""))
        conflicts_count = sum(1 for sec in sections for f in sec.fields if f.conflict_detected)

        session = ApplicationSessionModel(
            session_id=session_id,
            user_id=user_id,
            scheme_id=scheme_id,
            scheme_name=entry.schemeName,
            scheme_category=entry.category,
            official_application_url=entry.officialApplicationUrl,
            portal_adapter_id=entry.adapterId,
            status=ApplicationStatus.READY,
            sections=sections,
            documents=doc_requirements,
            missing_fields_count=missing_count,
            conflicts_count=conflicts_count,
            can_submit=False,
            submission_confirmed=False,
            created_at=now_str,
            updated_at=now_str,
        )

        self._sessions[session_id] = session
        return session

    def get_session(self, session_id: str) -> ApplicationSessionModel:
        """Retrieves an existing session by ID."""
        session = self._sessions.get(session_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Application session '{session_id}' not found.",
            )
        return session

    # ==========================================
    # Field Answering & Conflict Resolution
    # ==========================================

    def answer_missing_fields(
        self,
        session_id: str,
        answers: Dict[str, Any],
    ) -> ApplicationSessionModel:
        """Updates multiple missing fields answered by the user."""
        session = self.get_session(session_id)
        now_str = datetime.utcnow().isoformat()

        for sec in session.sections:
            for f in sec.fields:
                if f.field_id in answers:
                    new_val = answers[f.field_id]
                    f.mapped_value = new_val
                    f.user_confirmed = True
                    f.mapping_status = MappingStatus.USER_CONFIRMED
                    f.validation_status = "valid"
                    f.provenance = ValueProvenance(
                        field=f.field_id,
                        value=new_val,
                        source="user_confirmed_answer",
                        verification_status="user_confirmed",
                        last_updated_at=now_str,
                    )

        self._revalidate_session(session)
        session.updated_at = now_str
        return session

    def resolve_field_conflict(
        self,
        session_id: str,
        field_id: str,
        confirmed_value: Any,
        chosen_source: str = "user_confirmed_answer",
    ) -> ApplicationSessionModel:
        """Resolves a conflicting field value where profile and document OCR disagree."""
        session = self.get_session(session_id)
        now_str = datetime.utcnow().isoformat()

        for sec in session.sections:
            for f in sec.fields:
                if f.field_id == field_id:
                    f.mapped_value = confirmed_value
                    f.conflict_detected = False
                    f.user_confirmed = True
                    f.mapping_status = MappingStatus.USER_CONFIRMED
                    f.validation_status = "valid"
                    f.provenance = ValueProvenance(
                        field=field_id,
                        value=confirmed_value,
                        source=chosen_source,
                        verification_status="user_confirmed",
                        last_updated_at=now_str,
                    )
                    break

        self._revalidate_session(session)
        session.updated_at = now_str
        return session

    # ==========================================
    # Portal Population & Read-Back Verification
    # ==========================================

    def get_portal_population_payload(self, session_id: str) -> PortalPopulationPayload:
        """
        Synthesizes declarative, sandboxed population instructions for the official portal.
        """
        session = self.get_session(session_id)
        entry = self.portal_service.get_entry_for_scheme(session.scheme_id)

        # Collate all non-empty field values
        field_values = {}
        for sec in session.sections:
            for f in sec.fields:
                if f.mapped_value is not None and str(f.mapped_value).strip() != "":
                    field_values[f.field_id] = f.mapped_value

        script = self.portal_service.generate_population_script(session.scheme_id, field_values)
        configs = self.portal_service.get_fields_config(session.scheme_id)
        selectors = [{"field_id": c["field_id"], "selector": c["selector"]} for c in configs]

        session.status = ApplicationStatus.FILLING_PORTAL
        session.updated_at = datetime.utcnow().isoformat()

        return PortalPopulationPayload(
            portal_id=entry.adapterId,
            portal_domain=entry.portalDomain,
            declarative_instructions=[{"script": script}],
            read_back_selectors=selectors,
            manual_intervention_required=entry.manualInterventionRequirements,
        )

    def verify_portal_readback(
        self,
        session_id: str,
        actual_dom_values: Dict[str, Any],
    ) -> ReadBackVerificationReport:
        """
        Compares expected populated values against read-back values directly inspected
        from the official portal DOM.
        """
        session = self.get_session(session_id)

        expected_values = {}
        for sec in session.sections:
            for f in sec.fields:
                if f.mapped_value is not None:
                    expected_values[f.field_id] = f.mapped_value

        report = self.portal_service.verify_readback(
            session.scheme_id,
            expected_values=expected_values,
            actual_dom_values=actual_dom_values,
        )

        session.read_back_report = report
        # Update individual field read-back status
        item_status_map = {item.field_id: item.status for item in report.items}
        for sec in session.sections:
            for f in sec.fields:
                if f.field_id in item_status_map:
                    f.read_back_status = item_status_map[f.field_id]

        if report.can_proceed_to_review:
            session.status = ApplicationStatus.READY_FOR_REVIEW
        else:
            session.status = ApplicationStatus.AWAITING_USER_INPUT

        self._revalidate_session(session)
        session.updated_at = datetime.utcnow().isoformat()
        return report

    # ==========================================
    # Validation & Citizen Submission Gate
    # ==========================================

    def validate_session(self, session_id: str) -> ApplicationValidationResponse:
        """Runs pre-submission validation checks across all sections."""
        session = self.get_session(session_id)
        self._revalidate_session(session)

        missing = [f.field_label for sec in session.sections for f in sec.fields if f.is_required and (f.mapped_value is None or str(f.mapped_value).strip() == "")]
        conflicts = [f.conflict_details for sec in session.sections for f in sec.fields if f.conflict_detected and f.conflict_details]
        invalid = [f.field_label for sec in session.sections for f in sec.fields if f.validation_status == "invalid"]

        is_valid = (len(missing) == 0 and len(conflicts) == 0 and len(invalid) == 0)
        session.can_submit = is_valid

        return ApplicationValidationResponse(
            is_valid=is_valid,
            missing_required_fields=missing,
            conflicts=conflicts,
            invalid_format_fields=invalid,
            missing_mandatory_documents=[],
            warnings=session.warnings,
            can_submit=is_valid,
        )

    def confirm_submission(
        self,
        session_id: str,
        user_explicit_approval: bool,
        acknowledgement_number: Optional[str] = None,
    ) -> ApplicationSessionModel:
        """
        CRITICAL CITIZEN GATE:
        Only marks application confirmed if the citizen has provided explicit approval.
        """
        session = self.get_session(session_id)

        if not user_explicit_approval:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Explicit citizen approval declaration is required before application submission.",
            )

        session.submission_confirmed = True
        session.status = ApplicationStatus.SUBMITTED_CONFIRMED
        session.submission_reference = (
            acknowledgement_number or f"SAHAY-{session.scheme_id[:6]}-{datetime.utcnow().strftime('%Y%m%d%H%M')}"
        )
        session.updated_at = datetime.utcnow().isoformat()
        return session

    # ==========================================
    # Internal Helpers
    # ==========================================

    def _build_sections_for_scheme(
        self,
        scheme_id: str,
        configs: List[Dict[str, Any]],
        profile: NormalizedCitizenProfile,
    ) -> List[ApplicationSection]:
        """Maps scheme configs and normalized profile values into logical sections."""
        now_str = datetime.utcnow().isoformat()
        fields_by_section: Dict[str, List[FieldMapping]] = {
            "sec_personal": [],
            "sec_address": [],
            "sec_financial": [],
            "sec_scheme_specific": [],
        }

        for item in configs:
            f_id = item["field_id"]
            lbl = item["label"]
            f_type_str = item.get("type", "text").upper()
            f_type = getattr(FieldType, f_type_str, FieldType.TEXT)
            req = item.get("required", True)
            source_path = item.get("source", "")

            # Resolve mapped value from normalized profile provenance map or attributes
            mapped_val = None
            provenance = None
            conflict = False
            conflict_info = None

            if source_path in profile.provenance_map:
                provenance = profile.provenance_map[source_path]
                mapped_val = provenance.value

            # Check for conflict between profile and document OCR (e.g. income)
            if f_id == "annual_income" and "financial.annual_income_doc" in profile.provenance_map and "financial.annual_income" in profile.provenance_map:
                p_inc = profile.provenance_map["financial.annual_income"].value
                d_inc = profile.provenance_map["financial.annual_income_doc"].value
                if p_inc != d_inc:
                    conflict = True
                    conflict_info = {
                        "field": "annual_income",
                        "profile_value": p_inc,
                        "document_value": d_inc,
                        "description": f"Profile lists annual income as ₹{p_inc:,}, but Income Certificate shows ₹{d_inc:,}.",
                    }

            status_enum = MappingStatus.PREFILLED if mapped_val is not None else MappingStatus.MISSING
            if conflict:
                status_enum = MappingStatus.CONFLICT

            field_obj = FieldMapping(
                field_id=f_id,
                field_label=lbl,
                field_type=f_type,
                is_required=req,
                mapped_value=mapped_val,
                source_type=SourceType.USER_PROFILE if mapped_val is not None else None,
                mapping_status=status_enum,
                user_confirmed=False,
                validation_status="valid" if mapped_val is not None and not conflict else ("pending" if not conflict else "invalid"),
                conflict_detected=conflict,
                conflict_details=conflict_info,
                provenance=provenance,
                portal_selector=item["selector"],
            )

            # Categorize into sections
            if any(term in f_id for term in ["name", "aadhaar", "dob", "gender", "father"]):
                fields_by_section["sec_personal"].append(field_obj)
            elif any(term in f_id for term in ["state", "district", "address", "block", "village", "city"]):
                fields_by_section["sec_address"].append(field_obj)
            elif any(term in f_id for term in ["income", "bank", "ifsc", "pan", "account"]):
                fields_by_section["sec_financial"].append(field_obj)
            else:
                fields_by_section["sec_scheme_specific"].append(field_obj)

        sections = []
        if fields_by_section["sec_personal"]:
            sections.append(ApplicationSection(section_id="sec_personal", title="Personal & Demographic Details", fields=fields_by_section["sec_personal"]))
        if fields_by_section["sec_address"]:
            sections.append(ApplicationSection(section_id="sec_address", title="Address & Location Details", fields=fields_by_section["sec_address"]))
        if fields_by_section["sec_financial"]:
            sections.append(ApplicationSection(section_id="sec_financial", title="Financial & Bank Account Details", fields=fields_by_section["sec_financial"]))
        if fields_by_section["sec_scheme_specific"]:
            sections.append(ApplicationSection(section_id="sec_scheme_specific", title="Scheme-Specific Details", fields=fields_by_section["sec_scheme_specific"]))

        return sections

    def _revalidate_session(self, session: ApplicationSessionModel):
        """Calculates missing fields, conflicts, and submission viability."""
        missing = []
        conflicts = []

        for sec in session.sections:
            for f in sec.fields:
                if f.is_required and (f.mapped_value is None or str(f.mapped_value).strip() == ""):
                    missing.append(f.field_label)
                if f.conflict_detected:
                    conflicts.append(f.field_label)

        session.missing_fields_count = len(missing)
        session.conflicts_count = len(conflicts)
        session.validation_errors = [f"Missing required: {m}" for m in missing] + [f"Conflict unresolved: {c}" for c in conflicts]
        session.can_submit = (len(missing) == 0 and len(conflicts) == 0)
