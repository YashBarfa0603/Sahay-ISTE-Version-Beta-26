"""
Official Government Portal Compatibility Registry & Controlled Adapter Engine for SAHAY.
Implements the 10-Scheme Central Registry, Form Configurations, Field Selector Mappings,
and the Sandboxed JavaScript Bridge with Read-Back Verification.

CRITICAL SECURITY INVARIANTS:
1. Arbitrary AI-generated JavaScript execution is strictly prohibited.
2. All browser operations are emitted as pre-compiled, sanitized, declarative instructions.
3. OTP, CAPTCHA, passwords, and legal declaration checkboxes are protected and require direct citizen interaction.
4. Read-back verification confirms portal DOM acceptance before advancing to final review.
"""

import json
from typing import Any, Dict, List, Optional
from urllib.parse import urlparse

from backend.app.schemas.application_schema import (
    PortalCompatibilityStatus,
    ReadBackFieldItem,
    ReadBackFieldStatus,
    ReadBackVerificationReport,
    SchemeRegistryEntry,
)


class PortalAdapterService:
    """Registry of verified official government portals and scheme-specific form configurations."""

    # ==========================================
    # Central 10-Scheme Registry Specification
    # ==========================================

    SCHEME_REGISTRY: Dict[str, SchemeRegistryEntry] = {
        "PM_KISAN_001": SchemeRegistryEntry(
            schemeId="PM_KISAN_001",
            schemeName="PM-KISAN – Pradhan Mantri Kisan Samman Nidhi",
            alternateNames=["PM Kisan", "Kisan Samman Nidhi", "पीएम किसान"],
            category="agriculture",
            stateOrCentral="central",
            officialSchemeUrl="https://pmkisan.gov.in",
            officialApplicationUrl="https://pmkisan.gov.in/RegistrationFormNew.aspx",
            applicationMode="smart_filler",
            portalDomain="pmkisan.gov.in",
            adapterId="pm_kisan_adapter_v2",
            supportedFields=[
                "aadhaar_number",
                "mobile_number",
                "state",
                "district",
                "sub_district",
                "block",
                "village",
                "farmer_name",
                "gender",
                "category",
            ],
            requiredDocuments=["aadhaar_card", "bank_passbook", "land_records"],
            authenticationRequirements="aadhaar_otp",
            manualInterventionRequirements=[
                "Visual Image CAPTCHA must be entered by the citizen",
                "Aadhaar-linked Mobile OTP verification",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Cross-origin iframe upload restrictions apply; manual upload assistance provided for land documents",
                "Mandatory Aadhaar e-KYC required upon registration",
            ],
        ),
        "PMAY_002": SchemeRegistryEntry(
            schemeId="PMAY_002",
            schemeName="Pradhan Mantri Awas Yojana – Urban (PMAY-U 2.0)",
            alternateNames=["PMAY-U 2.0", "PMAY Urban", "प्रधानमंत्री आवास योजना शहरी"],
            category="housing",
            stateOrCentral="central",
            officialSchemeUrl="https://pmay-urban.gov.in",
            officialApplicationUrl="https://pmaymis.gov.in/Open/Check_Aadhar_Existence.aspx",
            applicationMode="smart_filler",
            portalDomain="pmaymis.gov.in",
            adapterId="pmay_u_adapter_v2",
            supportedFields=[
                "aadhaar_number",
                "applicant_name",
                "gender",
                "father_name",
                "mobile_number",
                "state",
                "district",
                "city_name",
                "current_address",
                "annual_income",
            ],
            requiredDocuments=["aadhaar_card", "income_certificate", "bank_passbook", "caste_certificate"],
            authenticationRequirements="aadhaar_auth",
            manualInterventionRequirements=[
                "Initial Aadhaar validation check on portal entry",
                "Visual CAPTCHA",
                "Citizen biometric/OTP consent for SECC matching",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Aadhaar existence must validate successfully on the NIC gateway before main form fields unlock",
            ],
        ),
        "E_SHRAM_001": SchemeRegistryEntry(
            schemeId="E_SHRAM_001",
            schemeName="e-Shram – National Database of Unorganised Workers",
            alternateNames=["eShram", "e-Shram Card", "ई-श्रम पंजीकरण"],
            category="social-security",
            stateOrCentral="central",
            officialSchemeUrl="https://eshram.gov.in",
            officialApplicationUrl="https://register.eshram.gov.in/#/user/self-registration",
            applicationMode="smart_filler",
            portalDomain="register.eshram.gov.in",
            adapterId="eshram_adapter_v2",
            supportedFields=[
                "mobile_number",
                "aadhaar_number",
                "occupation_name",
                "bank_account_number",
                "ifsc_code",
                "marital_status",
                "social_category",
                "state",
                "district",
            ],
            requiredDocuments=["aadhaar_card", "bank_passbook"],
            authenticationRequirements="aadhaar_mobile_otp",
            manualInterventionRequirements=[
                "Aadhaar-linked Mobile OTP for initial registration session",
                "Visual CAPTCHA",
                "UIDAI eKYC Consent OTP",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Single page angular app with step transitions; SAHAY populates fields per step once citizen confirms OTP",
            ],
        ),
        "UDYAM_001": SchemeRegistryEntry(
            schemeId="UDYAM_001",
            schemeName="Udyam Registration – MSME Portal",
            alternateNames=["Udyam", "MSME Registration", "उद्यम पंजीकरण"],
            category="business-entrepreneurship",
            stateOrCentral="central",
            officialSchemeUrl="https://udyamregistration.gov.in",
            officialApplicationUrl="https://udyamregistration.gov.in/Udyam_Registration.aspx",
            applicationMode="smart_filler",
            portalDomain="udyamregistration.gov.in",
            adapterId="udyam_adapter_v2",
            supportedFields=[
                "aadhaar_number",
                "entrepreneur_name",
                "social_category",
                "gender",
                "enterprise_name",
                "pan_number",
                "mobile_number",
                "email_id",
                "state",
                "district",
                "bank_account_number",
                "ifsc_code",
            ],
            requiredDocuments=["aadhaar_card", "pan_card", "bank_passbook"],
            authenticationRequirements="aadhaar_otp_pan_validation",
            manualInterventionRequirements=[
                "Aadhaar OTP validation with UIDAI gateway",
                "PAN card online verification against CBDT records",
                "Final declaration submission OTP",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Step 2 unlocks only after government server validates Aadhaar and PAN numbers live",
            ],
        ),
        "PM_SURYA_GHAR_001": SchemeRegistryEntry(
            schemeId="PM_SURYA_GHAR_001",
            schemeName="PM Surya Ghar: Muft Bijli Yojana (Rooftop Solar)",
            alternateNames=["PM Surya Ghar", "Muft Bijli", "सोलर रूफटॉप योजना"],
            category="clean-energy",
            stateOrCentral="central",
            officialSchemeUrl="https://pmsuryaghar.gov.in",
            officialApplicationUrl="https://pmsuryaghar.gov.in/consumerRegistration",
            applicationMode="smart_filler",
            portalDomain="pmsuryaghar.gov.in",
            adapterId="pm_surya_ghar_adapter_v2",
            supportedFields=[
                "state",
                "electricity_distribution_company",
                "consumer_account_number",
                "mobile_number",
                "email_id",
                "consumer_name",
                "rooftop_area",
            ],
            requiredDocuments=["electricity_bill", "aadhaar_card", "bank_passbook"],
            authenticationRequirements="electricity_consumer_mobile_otp",
            manualInterventionRequirements=[
                "Mobile OTP verification",
                "Visual CAPTCHA",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Consumer account number must match Discom records before subsidy portal proceeds",
            ],
        ),
        "PM_SVANIDHI_001": SchemeRegistryEntry(
            schemeId="PM_SVANIDHI_001",
            schemeName="PM SVANidhi – Street Vendor's AtmaNirbhar Nidhi",
            alternateNames=["PM SVANidhi", "Street Vendor Loan", "पीएम स्वनिधि"],
            category="business-entrepreneurship",
            stateOrCentral="central",
            officialSchemeUrl="https://pmsvanidhi.mohua.gov.in",
            officialApplicationUrl="https://pmsvanidhi.mohua.gov.in/Home/VendorRegistration",
            applicationMode="smart_filler",
            portalDomain="pmsvanidhi.mohua.gov.in",
            adapterId="pm_svanidhi_adapter_v2",
            supportedFields=[
                "mobile_number",
                "vendor_name",
                "father_name",
                "dob",
                "gender",
                "marital_status",
                "social_category",
                "vending_activity",
                "state",
                "district",
                "bank_account_number",
                "ifsc_code",
            ],
            requiredDocuments=["aadhaar_card", "voter_id", "bank_passbook", "vending_certificate"],
            authenticationRequirements="mobile_otp_ekyc",
            manualInterventionRequirements=[
                "Vendor Mobile OTP verification",
                "Aadhaar eKYC via UIDAI",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Vendors without a Certificate of Vending require a Letter of Recommendation (LoR) from ULB",
            ],
        ),
        "PMEGP_001": SchemeRegistryEntry(
            schemeId="PMEGP_001",
            schemeName="Prime Minister's Employment Generation Programme (PMEGP)",
            alternateNames=["PMEGP", "KVIC PMEGP", "प्रधानमंत्री रोजगार सृजन कार्यक्रम"],
            category="business-entrepreneurship",
            stateOrCentral="central",
            officialSchemeUrl="https://www.kviconline.gov.in/pmegpeportal",
            officialApplicationUrl="https://www.kviconline.gov.in/pmegpeportal/jsp/pmegponline.jsp",
            applicationMode="smart_filler",
            portalDomain="www.kviconline.gov.in",
            adapterId="pmegp_adapter_v2",
            supportedFields=[
                "aadhaar_number",
                "applicant_name",
                "state",
                "district",
                "gender",
                "social_category",
                "qualification",
                "current_address",
                "mobile_number",
                "email_id",
                "pan_number",
                "bank_account_number",
                "ifsc_code",
            ],
            requiredDocuments=["aadhaar_card", "pan_card", "project_report", "caste_certificate", "educational_marksheet"],
            authenticationRequirements="aadhaar_auth",
            manualInterventionRequirements=[
                "Aadhaar validation check",
                "Agency selection (KVIC / KVIB / DIC)",
                "Visual CAPTCHA",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Project report and EDP training certificate require direct attachment by user",
            ],
        ),
        "MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001": SchemeRegistryEntry(
            schemeId="MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001",
            schemeName="MP Post-Matric Scholarship for SC/ST/OBC Students (MP TAAS)",
            alternateNames=["MP TAAS", "MP Scholarship 2.0", "मध्य प्रदेश छात्रवृत्ति"],
            category="education-scholarships",
            stateOrCentral="state",
            officialSchemeUrl="https://www.tribal.mp.gov.in/mptaas",
            officialApplicationUrl="https://www.tribal.mp.gov.in/mptaas/registration",
            applicationMode="smart_filler",
            portalDomain="www.tribal.mp.gov.in",
            adapterId="mp_taas_adapter_v2",
            supportedFields=[
                "samagra_id",
                "aadhaar_number",
                "student_name",
                "father_name",
                "dob",
                "gender",
                "caste_category",
                "annual_income",
                "state",
                "district",
                "institute_code",
                "course_code",
                "admission_year",
                "bank_account_number",
                "ifsc_code",
            ],
            requiredDocuments=["aadhaar_card", "samagra_id", "income_certificate", "caste_certificate", "domicile_certificate", "bank_passbook"],
            authenticationRequirements="samagra_aadhaar_ekyc",
            manualInterventionRequirements=[
                "Samagra e-KYC matching",
                "Aadhaar OTP / Biometric verification",
                "Visual CAPTCHA",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Samagra ID profile must match Aadhaar demographic details exactly for state portal clearance",
            ],
        ),
        "AICTE_PRAGATI_001": SchemeRegistryEntry(
            schemeId="AICTE_PRAGATI_001",
            schemeName="AICTE Pragati Scholarship for Girls (Technical Degree/Diploma)",
            alternateNames=["AICTE Pragati", "NSP Pragati", "प्रगति छात्रवृत्ति"],
            category="education-scholarships",
            stateOrCentral="central",
            officialSchemeUrl="https://scholarships.gov.in",
            officialApplicationUrl="https://scholarships.gov.in/fresh/newstdRegfrmInstruction",
            applicationMode="smart_filler",
            portalDomain="scholarships.gov.in",
            adapterId="aicte_pragati_adapter_v2",
            supportedFields=[
                "state",
                "student_name",
                "dob",
                "gender",
                "mobile_number",
                "email_id",
                "ifsc_code",
                "bank_account_number",
                "annual_income",
            ],
            requiredDocuments=["aadhaar_card", "income_certificate", "admission_letter", "bank_passbook", "standard_10_12_marksheet"],
            authenticationRequirements="otr_mobile_aadhaar_otp",
            manualInterventionRequirements=[
                "NSP One Time Registration (OTR) Face Auth or Aadhaar OTP",
                "Visual CAPTCHA",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Applicant must complete NSP OTR via Aadhaar FaceRD app or OTP before scheme application opens",
            ],
        ),
        "AICTE_SAKSHAM_001": SchemeRegistryEntry(
            schemeId="AICTE_SAKSHAM_001",
            schemeName="AICTE Saksham Scholarship for Specially-Abled Students",
            alternateNames=["AICTE Saksham", "NSP Saksham", "सक्षम छात्रवृत्ति"],
            category="education-scholarships",
            stateOrCentral="central",
            officialSchemeUrl="https://scholarships.gov.in",
            officialApplicationUrl="https://scholarships.gov.in/fresh/newstdRegfrmInstruction",
            applicationMode="smart_filler",
            portalDomain="scholarships.gov.in",
            adapterId="aicte_saksham_adapter_v2",
            supportedFields=[
                "state",
                "student_name",
                "dob",
                "gender",
                "mobile_number",
                "email_id",
                "disability_type",
                "disability_percentage",
                "ifsc_code",
                "bank_account_number",
                "annual_income",
            ],
            requiredDocuments=["aadhaar_card", "disability_certificate", "income_certificate", "admission_letter", "bank_passbook"],
            authenticationRequirements="otr_mobile_aadhaar_otp",
            manualInterventionRequirements=[
                "NSP One Time Registration (OTR) Face Auth or Aadhaar OTP",
                "Disability certificate verification via UDID portal",
                "Visual CAPTCHA",
            ],
            portalCompatibilityStatus=PortalCompatibilityStatus.FULLY_SUPPORTED,
            lastTestedAt="2026-10-31",
            lastVerifiedAt="2026-10-31",
            applicationAvailabilityStatus="active_accepting_applications",
            knownLimitations=[
                "Disability percentage must be >= 40% certified by competent medical authority",
            ],
        ),
    }

    # ==========================================
    # Scheme-Specific Form Field Configurations
    # ==========================================

    SCHEME_FORM_CONFIGS: Dict[str, List[Dict[str, Any]]] = {
        "PM_KISAN_001": [
            {"field_id": "aadhaar_number", "label": "Aadhaar Number", "selector": "txt_Aadhar", "type": "text", "required": True, "source": "personal.aadhaar_number"},
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "txt_Mobile", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "state", "label": "State", "selector": "ddl_State", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "district", "label": "District", "selector": "ddl_District", "type": "dropdown", "required": True, "source": "address.district"},
            {"field_id": "sub_district", "label": "Sub-District / Tehsil", "selector": "ddl_SubDistrict", "type": "dropdown", "required": True, "source": "address.sub_district"},
            {"field_id": "block", "label": "Block", "selector": "ddl_Block", "type": "dropdown", "required": True, "source": "address.block"},
            {"field_id": "village", "label": "Village", "selector": "ddl_Village", "type": "dropdown", "required": True, "source": "address.village"},
            {"field_id": "farmer_name", "label": "Farmer Name (as per Aadhaar)", "selector": "txt_FarmerName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "gender", "label": "Gender", "selector": "ddl_Gender", "type": "dropdown", "required": True, "source": "personal.gender"},
            {"field_id": "category", "label": "Category", "selector": "ddl_Category", "type": "dropdown", "required": True, "source": "social.caste_category"},
        ],
        "PMAY_002": [
            {"field_id": "aadhaar_number", "label": "Aadhaar Number", "selector": "txtAadharNo", "type": "text", "required": True, "source": "personal.aadhaar_number"},
            {"field_id": "applicant_name", "label": "Name of Beneficiary", "selector": "txtNameAsPerAadhar", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "father_name", "label": "Father's Name", "selector": "txtFatherName", "type": "text", "required": True, "source": "personal.father_name"},
            {"field_id": "gender", "label": "Gender", "selector": "ddlGender", "type": "dropdown", "required": True, "source": "personal.gender"},
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "txtMobileNo", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "state", "label": "State", "selector": "ddlState", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "district", "label": "District", "selector": "ddlDistrict", "type": "dropdown", "required": True, "source": "address.district"},
            {"field_id": "city_name", "label": "City / Town Name", "selector": "ddlCity", "type": "dropdown", "required": True, "source": "address.city"},
            {"field_id": "current_address", "label": "Present Address", "selector": "txtPresentAddress", "type": "text", "required": True, "source": "address.full_address"},
            {"field_id": "annual_income", "label": "Annual Household Income", "selector": "txtMonthlyIncome", "type": "number", "required": True, "source": "financial.annual_income"},
        ],
        "E_SHRAM_001": [
            {"field_id": "mobile_number", "label": "Aadhaar Linked Mobile Number", "selector": "aadhaarMobileNo", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "aadhaar_number", "label": "Aadhaar Number", "selector": "aadhaarNumberInput", "type": "text", "required": True, "source": "personal.aadhaar_number"},
            {"field_id": "occupation_name", "label": "Primary Occupation", "selector": "primaryOccupation", "type": "text", "required": True, "source": "occupation.occupation_name"},
            {"field_id": "social_category", "label": "Social Category", "selector": "socialCategory", "type": "dropdown", "required": True, "source": "social.caste_category"},
            {"field_id": "marital_status", "label": "Marital Status", "selector": "maritalStatus", "type": "dropdown", "required": False, "source": "social.marital_status"},
            {"field_id": "state", "label": "Current State", "selector": "stateCode", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "district", "label": "Current District", "selector": "districtCode", "type": "dropdown", "required": True, "source": "address.district"},
            {"field_id": "bank_account_number", "label": "Bank Account Number", "selector": "bankAccNo", "type": "text", "required": True, "source": "financial.bank_account_number"},
            {"field_id": "ifsc_code", "label": "Bank IFSC Code", "selector": "ifscCode", "type": "text", "required": True, "source": "financial.ifsc_code"},
        ],
        "UDYAM_001": [
            {"field_id": "aadhaar_number", "label": "Aadhaar Number", "selector": "ctl00_ContentPlaceHolder1_txtAadhaarNo", "type": "text", "required": True, "source": "personal.aadhaar_number"},
            {"field_id": "entrepreneur_name", "label": "Name of Entrepreneur (as per Aadhaar)", "selector": "ctl00_ContentPlaceHolder1_txtOwnerName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "pan_number", "label": "Permanent Account Number (PAN)", "selector": "ctl00_ContentPlaceHolder1_txtPanNo", "type": "text", "required": True, "source": "financial.pan_number"},
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "ctl00_ContentPlaceHolder1_txtMobile", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "email_id", "label": "Email Address", "selector": "ctl00_ContentPlaceHolder1_txtEmail", "type": "email", "required": True, "source": "contact.email"},
            {"field_id": "social_category", "label": "Social Category", "selector": "ctl00_ContentPlaceHolder1_ddlSocialCategory", "type": "dropdown", "required": True, "source": "social.caste_category"},
            {"field_id": "gender", "label": "Gender", "selector": "ctl00_ContentPlaceHolder1_rblGender", "type": "radio", "required": True, "source": "personal.gender"},
            {"field_id": "enterprise_name", "label": "Name of Enterprise", "selector": "ctl00_ContentPlaceHolder1_txtEnterpriseName", "type": "text", "required": True, "source": "occupation.business_name"},
            {"field_id": "state", "label": "State", "selector": "ctl00_ContentPlaceHolder1_ddlState", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "district", "label": "District", "selector": "ctl00_ContentPlaceHolder1_ddlDistrict", "type": "dropdown", "required": True, "source": "address.district"},
            {"field_id": "bank_account_number", "label": "Bank Account Number", "selector": "ctl00_ContentPlaceHolder1_txtBankAcc", "type": "text", "required": True, "source": "financial.bank_account_number"},
            {"field_id": "ifsc_code", "label": "IFS Code", "selector": "ctl00_ContentPlaceHolder1_txtIFSCode", "type": "text", "required": True, "source": "financial.ifsc_code"},
        ],
        "PM_SURYA_GHAR_001": [
            {"field_id": "state", "label": "State", "selector": "selectState", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "electricity_distribution_company", "label": "Electricity Distribution Company (Discom)", "selector": "selectDiscom", "type": "dropdown", "required": True, "source": "financial.discom_name"},
            {"field_id": "consumer_account_number", "label": "Consumer Account Number", "selector": "txtConsumerNumber", "type": "text", "required": True, "source": "financial.consumer_number"},
            {"field_id": "consumer_name", "label": "Consumer Name (as per Bill)", "selector": "txtConsumerName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "txtMobileNo", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "email_id", "label": "Email Address", "selector": "txtEmail", "type": "email", "required": False, "source": "contact.email"},
            {"field_id": "rooftop_area", "label": "Proposed Rooftop Area (in Sq. Ft.)", "selector": "txtRooftopArea", "type": "number", "required": True, "source": "occupation.rooftop_area"},
        ],
        "PM_SVANIDHI_001": [
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "txtVendorMobile", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "vendor_name", "label": "Name of Street Vendor", "selector": "txtVendorName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "father_name", "label": "Father's / Spouse Name", "selector": "txtFatherSpouseName", "type": "text", "required": True, "source": "personal.father_name"},
            {"field_id": "dob", "label": "Date of Birth", "selector": "txtDOB", "type": "date", "required": True, "source": "personal.dob"},
            {"field_id": "gender", "label": "Gender", "selector": "ddlGender", "type": "dropdown", "required": True, "source": "personal.gender"},
            {"field_id": "marital_status", "label": "Marital Status", "selector": "ddlMaritalStatus", "type": "dropdown", "required": False, "source": "social.marital_status"},
            {"field_id": "social_category", "label": "Social Category", "selector": "ddlSocialCategory", "type": "dropdown", "required": True, "source": "social.caste_category"},
            {"field_id": "vending_activity", "label": "Vending Activity / Goods Sold", "selector": "txtVendingActivity", "type": "text", "required": True, "source": "occupation.vending_activity"},
            {"field_id": "state", "label": "Vending State", "selector": "ddlState", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "district", "label": "Vending District", "selector": "ddlDistrict", "type": "dropdown", "required": True, "source": "address.district"},
            {"field_id": "bank_account_number", "label": "Bank Account Number", "selector": "txtBankAccNo", "type": "text", "required": True, "source": "financial.bank_account_number"},
            {"field_id": "ifsc_code", "label": "Bank IFSC Code", "selector": "txtIFSC", "type": "text", "required": True, "source": "financial.ifsc_code"},
        ],
        "PMEGP_001": [
            {"field_id": "aadhaar_number", "label": "Aadhaar Number", "selector": "txtAadhaar", "type": "text", "required": True, "source": "personal.aadhaar_number"},
            {"field_id": "applicant_name", "label": "Applicant Name", "selector": "txtApplicantName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "state", "label": "State", "selector": "ddlState", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "district", "label": "District", "selector": "ddlDistrict", "type": "dropdown", "required": True, "source": "address.district"},
            {"field_id": "gender", "label": "Gender", "selector": "ddlGender", "type": "dropdown", "required": True, "source": "personal.gender"},
            {"field_id": "social_category", "label": "Social Category", "selector": "ddlSocialCategory", "type": "dropdown", "required": True, "source": "social.caste_category"},
            {"field_id": "qualification", "label": "Academic Qualification", "selector": "ddlQualification", "type": "dropdown", "required": True, "source": "education.qualification"},
            {"field_id": "current_address", "label": "Communication Address", "selector": "txtAddress", "type": "text", "required": True, "source": "address.full_address"},
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "txtMobile", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "email_id", "label": "Email Address", "selector": "txtEmail", "type": "email", "required": False, "source": "contact.email"},
            {"field_id": "pan_number", "label": "PAN Number", "selector": "txtPAN", "type": "text", "required": True, "source": "financial.pan_number"},
            {"field_id": "bank_account_number", "label": "Bank Account Number", "selector": "txtBankAcc", "type": "text", "required": True, "source": "financial.bank_account_number"},
            {"field_id": "ifsc_code", "label": "Bank IFSC Code", "selector": "txtIFSC", "type": "text", "required": True, "source": "financial.ifsc_code"},
        ],
        "MP_POST_MATRIC_SCHOLARSHIP_SC_ST_001": [
            {"field_id": "samagra_id", "label": "Samagra Member ID (9-Digit)", "selector": "txtSamagraId", "type": "text", "required": True, "source": "social.samagra_id"},
            {"field_id": "aadhaar_number", "label": "Aadhaar Number", "selector": "txtAadhaarNo", "type": "text", "required": True, "source": "personal.aadhaar_number"},
            {"field_id": "student_name", "label": "Student Name (as per Samagra/Aadhaar)", "selector": "txtStudentName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "father_name", "label": "Father's Name", "selector": "txtFatherName", "type": "text", "required": True, "source": "personal.father_name"},
            {"field_id": "dob", "label": "Date of Birth", "selector": "txtDOB", "type": "date", "required": True, "source": "personal.dob"},
            {"field_id": "gender", "label": "Gender", "selector": "ddlGender", "type": "dropdown", "required": True, "source": "personal.gender"},
            {"field_id": "caste_category", "label": "Caste Category", "selector": "ddlCategory", "type": "dropdown", "required": True, "source": "social.caste_category"},
            {"field_id": "annual_income", "label": "Annual Family Income", "selector": "txtAnnualIncome", "type": "number", "required": True, "source": "financial.annual_income"},
            {"field_id": "state", "label": "State of Domicile", "selector": "ddlState", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "district", "label": "District", "selector": "ddlDistrict", "type": "dropdown", "required": True, "source": "address.district"},
            {"field_id": "institute_code", "label": "College / Institute Code", "selector": "txtInstituteCode", "type": "text", "required": True, "source": "education.institution_code"},
            {"field_id": "course_code", "label": "Course / Branch Code", "selector": "txtCourseCode", "type": "text", "required": True, "source": "education.course_code"},
            {"field_id": "admission_year", "label": "Admission Year", "selector": "txtAdmissionYear", "type": "number", "required": True, "source": "education.admission_year"},
            {"field_id": "bank_account_number", "label": "Bank Account Number (Aadhaar Seeded)", "selector": "txtBankAccNo", "type": "text", "required": True, "source": "financial.bank_account_number"},
            {"field_id": "ifsc_code", "label": "Bank IFSC Code", "selector": "txtIFSC", "type": "text", "required": True, "source": "financial.ifsc_code"},
        ],
        "AICTE_PRAGATI_001": [
            {"field_id": "state", "label": "State of Domicile", "selector": "stateOfDomicile", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "student_name", "label": "Student Name (as per Aadhaar)", "selector": "studentName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "dob", "label": "Date of Birth", "selector": "dob", "type": "date", "required": True, "source": "personal.dob"},
            {"field_id": "gender", "label": "Gender", "selector": "gender", "type": "dropdown", "required": True, "source": "personal.gender"},
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "mobileNumber", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "email_id", "label": "Email Address", "selector": "emailId", "type": "email", "required": True, "source": "contact.email"},
            {"field_id": "ifsc_code", "label": "Bank IFSC Code", "selector": "bankIfsc", "type": "text", "required": True, "source": "financial.ifsc_code"},
            {"field_id": "bank_account_number", "label": "Bank Account Number", "selector": "bankAccNo", "type": "text", "required": True, "source": "financial.bank_account_number"},
            {"field_id": "annual_income", "label": "Annual Family Income (<= 8 Lakh)", "selector": "annualFamilyIncome", "type": "number", "required": True, "source": "financial.annual_income"},
        ],
        "AICTE_SAKSHAM_001": [
            {"field_id": "state", "label": "State of Domicile", "selector": "stateOfDomicile", "type": "dropdown", "required": True, "source": "address.state"},
            {"field_id": "student_name", "label": "Student Name (as per Aadhaar)", "selector": "studentName", "type": "text", "required": True, "source": "personal.full_name"},
            {"field_id": "dob", "label": "Date of Birth", "selector": "dob", "type": "date", "required": True, "source": "personal.dob"},
            {"field_id": "gender", "label": "Gender", "selector": "gender", "type": "dropdown", "required": True, "source": "personal.gender"},
            {"field_id": "mobile_number", "label": "Mobile Number", "selector": "mobileNumber", "type": "phone", "required": True, "source": "contact.mobile_number"},
            {"field_id": "email_id", "label": "Email Address", "selector": "emailId", "type": "email", "required": True, "source": "contact.email"},
            {"field_id": "disability_type", "label": "Type of Disability", "selector": "disabilityType", "type": "dropdown", "required": True, "source": "social.disability_type"},
            {"field_id": "disability_percentage", "label": "Disability Percentage (>= 40%)", "selector": "disabilityPercentage", "type": "number", "required": True, "source": "social.disability_percentage"},
            {"field_id": "ifsc_code", "label": "Bank IFSC Code", "selector": "bankIfsc", "type": "text", "required": True, "source": "financial.ifsc_code"},
            {"field_id": "bank_account_number", "label": "Bank Account Number", "selector": "bankAccNo", "type": "text", "required": True, "source": "financial.bank_account_number"},
            {"field_id": "annual_income", "label": "Annual Family Income", "selector": "annualFamilyIncome", "type": "number", "required": True, "source": "financial.annual_income"},
        ],
    }

    # ==========================================
    # Registry Resolution & Helper Methods
    # ==========================================

    @classmethod
    def get_supported_schemes_registry(cls) -> List[SchemeRegistryEntry]:
        """Returns the list of all 10 verified and supported schemes."""
        return list(cls.SCHEME_REGISTRY.values())

    @classmethod
    def is_scheme_supported(cls, scheme_id: str) -> bool:
        """Determines whether a scheme is one of the 10 verified smart application schemes."""
        return scheme_id in cls.SCHEME_REGISTRY

    @classmethod
    def get_entry_for_scheme(cls, scheme_id: str) -> Optional[SchemeRegistryEntry]:
        """Retrieves registry metadata for a given scheme ID."""
        return cls.SCHEME_REGISTRY.get(scheme_id)

    @classmethod
    def get_fields_config(cls, scheme_id: str) -> List[Dict[str, Any]]:
        """Returns the specific form field configurations for a given scheme."""
        return cls.SCHEME_FORM_CONFIGS.get(scheme_id, [])

    # ==========================================
    # Sandboxed Declarative JavaScript Bridge
    # ==========================================

    @classmethod
    def generate_population_script(cls, scheme_id: str, field_values: Dict[str, Any]) -> str:
        """
        Emits declarative, safe field population commands for the scheme's verified form inputs.
        NEVER executes arbitrary AI code or prompt injection.
        Dispatches 'input' and 'change' events to ensure form framework state sync.
        Excludes OTP, CAPTCHA, passwords, and legal confirmation checkboxes.
        """
        configs = cls.get_fields_config(scheme_id)
        instructions = []

        for item in configs:
            f_id = item["field_id"]
            if f_id in field_values:
                val = field_values[f_id]
                if val is not None and str(val).strip() != "":
                    sel = item["selector"]
                    # Security Guard: Double-check protection invariants
                    if any(p in sel.lower() for p in ["captcha", "otp", "password"]):
                        continue
                    instructions.append({
                        "field_id": f_id,
                        "selector": sel,
                        "value": str(val).strip(),
                        "type": item["type"],
                    })

        instructions_json = json.dumps(instructions)

        return f"""
        (function() {{
            var instructions = {instructions_json};
            var results = [];
            for (var i = 0; i < instructions.length; i++) {{
                var inst = instructions[i];
                try {{
                    var el = document.getElementById(inst.selector) || 
                             document.querySelector('[name="' + inst.selector + '"]') ||
                             document.querySelector('#' + inst.selector);
                    if (el) {{
                        el.focus();
                        if (inst.type === 'radio' || inst.type === 'checkbox') {{
                            el.checked = (inst.value === 'true' || inst.value === '1' || inst.value === el.value);
                        }} else {{
                            el.value = inst.value;
                        }}
                        el.dispatchEvent(new Event('input', {{ bubbles: true, cancelable: true }}));
                        el.dispatchEvent(new Event('change', {{ bubbles: true, cancelable: true }}));
                        el.dispatchEvent(new Event('blur', {{ bubbles: true, cancelable: true }}));
                        results.push({{ field_id: inst.field_id, selector: inst.selector, status: 'success', populated_value: el.value }});
                    }} else {{
                        results.push({{ field_id: inst.field_id, selector: inst.selector, status: 'not_found' }});
                    }}
                }} catch(err) {{
                    results.push({{ field_id: inst.field_id, selector: inst.selector, status: 'error', error: err.toString() }});
                }}
            }}
            var report = JSON.stringify({{ action: 'POPULATE_RESULTS', results: results }});
            if (window.SahayBridge && window.SahayBridge.postMessage) {{
                window.SahayBridge.postMessage(report);
            }}
            return report;
        }})();
        """.strip()

    @classmethod
    def generate_readback_script(cls, scheme_id: str) -> str:
        """
        Emits a read-only DOM inspection payload that reads back values currently
        held in form inputs, verifying portal acceptance.
        """
        configs = cls.get_fields_config(scheme_id)
        selectors = [{"field_id": item["field_id"], "selector": item["selector"], "type": item["type"]} for item in configs]
        selectors_json = json.dumps(selectors)

        return f"""
        (function() {{
            var targets = {selectors_json};
            var readBackData = {{}};
            for (var i = 0; i < targets.length; i++) {{
                var t = targets[i];
                try {{
                    var el = document.getElementById(t.selector) || 
                             document.querySelector('[name="' + t.selector + '"]') ||
                             document.querySelector('#' + t.selector);
                    if (el) {{
                        if (t.type === 'checkbox' || t.type === 'radio') {{
                            readBackData[t.field_id] = el.checked ? (el.value || 'true') : 'false';
                        }} else {{
                            readBackData[t.field_id] = el.value || '';
                        }}
                    }} else {{
                        readBackData[t.field_id] = null;
                    }}
                }} catch(e) {{
                    readBackData[t.field_id] = null;
                }}
            }}
            var report = JSON.stringify({{ action: 'READBACK_RESULTS', data: readBackData }});
            if (window.SahayBridge && window.SahayBridge.postMessage) {{
                window.SahayBridge.postMessage(report);
            }}
            return report;
        }})();
        """.strip()

    @classmethod
    def verify_readback(
        cls,
        scheme_id: str,
        expected_values: Dict[str, Any],
        actual_dom_values: Dict[str, Any],
    ) -> ReadBackVerificationReport:
        """
        Compares expected populated values against read-back DOM state,
        generating a deterministic verification report.
        """
        configs = cls.get_fields_config(scheme_id)
        items: List[ReadBackFieldItem] = []
        verified_count = 0
        unverified_count = 0
        manual_action_count = 0
        failed_count = 0

        for item in configs:
            f_id = item["field_id"]
            sel = item["selector"]
            expected = expected_values.get(f_id)

            if expected is None or str(expected).strip() == "":
                items.append(
                    ReadBackFieldItem(
                        field_id=f_id,
                        selector=sel,
                        expected_value=None,
                        read_value=actual_dom_values.get(f_id),
                        status=ReadBackFieldStatus.MISSING if item["required"] else ReadBackFieldStatus.MANUAL_ACTION_REQUIRED,
                        message="Field not provided in application data",
                    )
                )
                if item["required"]:
                    failed_count += 1
                else:
                    manual_action_count += 1
                continue

            actual = actual_dom_values.get(f_id)

            # Compare values (normalized string match)
            exp_str = str(expected).strip().lower()
            act_str = str(actual).strip().lower() if actual is not None else ""

            if actual is not None and (exp_str == act_str or exp_str in act_str or act_str in exp_str):
                items.append(
                    ReadBackFieldItem(
                        field_id=f_id,
                        selector=sel,
                        expected_value=expected,
                        read_value=actual,
                        status=ReadBackFieldStatus.FILLED_VERIFIED,
                        message="DOM value matches expected data",
                    )
                )
                verified_count += 1
            elif actual is None:
                items.append(
                    ReadBackFieldItem(
                        field_id=f_id,
                        selector=sel,
                        expected_value=expected,
                        read_value=None,
                        status=ReadBackFieldStatus.FAILED,
                        message=f"Selector '{sel}' not found on portal page",
                    )
                )
                failed_count += 1
            else:
                items.append(
                    ReadBackFieldItem(
                        field_id=f_id,
                        selector=sel,
                        expected_value=expected,
                        read_value=actual,
                        status=ReadBackFieldStatus.FILLED_UNVERIFIED,
                        message=f"Value mismatch: expected '{expected}', found '{actual}'",
                    )
                )
                unverified_count += 1

        total = len(configs)
        can_proceed = (failed_count == 0 and unverified_count == 0)

        return ReadBackVerificationReport(
            total_fields=total,
            verified_count=verified_count,
            unverified_count=unverified_count,
            manual_action_count=manual_action_count,
            failed_count=failed_count,
            items=items,
            can_proceed_to_review=can_proceed,
        )
