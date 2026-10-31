"""
Database Integration Interface for SAHAY Scheme Catalogue.

NOTE ON DIVISION OF RESPONSIBILITY:
Firebase Authentication and Cloud Firestore are maintained by the database engineer.
This interface defines the exact contract required by SAHAY backend services.
The default implementation provides an in-memory reference catalogue (preloaded
with the 6 verified core schemes) which can be swapped with FirestoreSchemeDatabase
by implementing this abstract base class.
"""

import json
from pathlib import Path
from abc import ABC, abstractmethod
from datetime import datetime
from typing import List, Optional
from backend.app.models.scheme_schemas import (
    SchemeModelSchema,
    GovernmentLevel,
    VerificationStatus,
    SchemeStatus,
    SchemeSourceType,
    EligibilityRuleSchema,
    EligibilityOperator,
)


class SchemeDatabaseInterface(ABC):
    """Abstract contract for scheme catalog persistence."""

    @abstractmethod
    async def get_scheme(self, scheme_id: str) -> Optional[SchemeModelSchema]:
        """Fetch a single scheme by its unique identifier."""
        pass

    @abstractmethod
    async def search_schemes(
        self,
        query: str,
        category: Optional[str] = None,
        level: Optional[GovernmentLevel] = None,
        state: Optional[str] = None,
        limit: int = 20,
    ) -> List[SchemeModelSchema]:
        """Search trusted scheme catalog with filtering."""
        pass

    @abstractmethod
    async def list_all_schemes(self, limit: int = 100) -> List[SchemeModelSchema]:
        """List verified schemes with pagination."""
        pass

    @abstractmethod
    async def save_discovered_scheme(self, scheme: SchemeModelSchema) -> bool:
        """Persist a newly discovered scheme with pending verification."""
        pass


class InMemorySchemeDatabase(SchemeDatabaseInterface):
    """
    Default in-memory implementation providing verified baseline schemes.
    Allows local development and testing without requiring live Firestore credentials.
    """

    def __init__(self):
        self._schemes: dict[str, SchemeModelSchema] = {}
        self._preload_baseline_schemes()
        self._preload_seed_schemes_from_disk()


    def _preload_seed_schemes_from_disk(self):
        """Loads curated SchemeDocument JSON seed files from data/schemes_seed directory."""
        seed_dir = Path(__file__).resolve().parent.parent.parent.parent / "data" / "schemes_seed"
        if not seed_dir.exists():
            seed_dir = Path("data/schemes_seed")
        if not seed_dir.exists():
            return

        for json_file in seed_dir.glob("*.json"):
            if json_file.name.startswith("_"):
                continue
            try:
                data = json.loads(json_file.read_text(encoding="utf-8"))
                scheme_id = data.get("schemeId")
                if not scheme_id or scheme_id in self._schemes:
                    continue

                rules = []
                for r in data.get("eligibilityRules", []):
                    try:
                        rules.append(
                            EligibilityRuleSchema(
                                field=r["field"],
                                operator=EligibilityOperator(r["operator"]),
                                value=r.get("value"),
                                isMandatory=r.get("isMandatory", True),
                                description=r.get("description"),
                            )
                        )
                    except Exception:
                        continue

                gov_lvl = GovernmentLevel.central
                if str(data.get("governmentLevel", "")).lower() == "state":
                    gov_lvl = GovernmentLevel.state

                model = SchemeModelSchema(
                    schemeId=scheme_id,
                    name=data.get("name", ""),
                    nameHindi=data.get("nameHindi"),
                    description=data.get("description", ""),
                    descriptionHindi=data.get("descriptionHindi"),
                    category=data.get("category", "socialWelfare"),
                    ministry=data.get("ministry", "Government of India"),
                    governmentLevel=gov_lvl,
                    applicableStates=data.get("applicableStates", []),
                    benefits=data.get("benefits", ""),
                    benefitsHindi=data.get("benefitsHindi"),
                    eligibilityRules=rules,
                    requiredDocuments=data.get("requiredDocuments", []),
                    applicationProcess=data.get("applicationProcess", ""),
                    applicationUrl=data.get("applicationUrl"),
                    officialSourceUrl=data.get("officialSourceUrl", "https://india.gov.in"),
                    sourceName=data.get("sourceName"),
                    sourceType=SchemeSourceType.curated,
                    verificationStatus=VerificationStatus.verified,
                    status=SchemeStatus.active,
                    isPopular=data.get("isPopular", False),
                    popularityRank=data.get("popularityRank", 50),
                )
                self._schemes[scheme_id] = model
            except Exception:
                continue

    def _preload_baseline_schemes(self):
        baseline = [
            SchemeModelSchema(
                schemeId="pm-kisan-001",
                name="PM Kisan Samman Nidhi",
                nameHindi="प्रधानमंत्री किसान सम्मान निधि",
                description="Financial benefit of Rs 6000 per year in three equal installments to small and marginal farmer families.",
                descriptionHindi="छोटे और सीमांत किसान परिवारों को प्रति वर्ष 6000 रुपये की वित्तीय सहायता तीन समान किस्तों में।",
                category="agriculture",
                ministry="Ministry of Agriculture and Farmers Welfare",
                governmentLevel=GovernmentLevel.central,
                applicableStates=[],
                benefits="Direct income support of ₹6,000 per annum paid directly into the bank accounts of eligible farmer families in 3 equal installments of ₹2,000.",
                benefitsHindi="पात्र किसान परिवारों के बैंक खातों में सीधे ₹6,000 प्रति वर्ष की आय सहायता, ₹2,000 की 3 समान किस्तों में।",
                eligibilityRules=[
                    EligibilityRuleSchema(
                        field="occupation",
                        operator=EligibilityOperator.equals,
                        value="farmer",
                        isMandatory=True,
                        description="Must be a practicing landholding farmer",
                    ),
                    EligibilityRuleSchema(
                        field="ownsCultivableLand",
                        operator=EligibilityOperator.isTrue,
                        value=True,
                        isMandatory=True,
                        description="Must hold registered cultivable land in family name (per June 2019 Cabinet reform, all land sizes qualify; 2ha cap was abolished)",
                    ),
                    EligibilityRuleSchema(
                        field="hasBankAccount",
                        operator=EligibilityOperator.isTrue,
                        value=True,
                        isMandatory=True,
                        description="Must possess an active Aadhaar-linked bank account",
                    ),
                    EligibilityRuleSchema(
                        field="isIncomeTaxPayer",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: No family member paid income tax in last assessment year",
                    ),
                    EligibilityRuleSchema(
                        field="isInstitutionalLandholder",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: Institutional landholders are strictly excluded",
                    ),
                    EligibilityRuleSchema(
                        field="isGovernmentEmployee",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: Serving/retired government officers and PSU employees are excluded (Group D/MTS exempted)",
                    ),
                ],
                requiredDocuments=[
                    "Aadhaar Card",
                    "Proof of Land Ownership (Khatauni/Khasra/ROR)",
                    "Aadhaar-seeded Bank Passbook",
                    "Active Mobile Number",
                ],
                applicationProcess="Apply online at pmkisan.gov.in under New Farmer Registration or visit Common Service Centres (CSC).",
                applicationUrl="https://pmkisan.gov.in/RegistrationFormNew.aspx",
                officialSourceUrl="https://pmkisan.gov.in/",
                sourceName="pmkisan.gov.in",
                sourceType=SchemeSourceType.curated,
                verificationStatus=VerificationStatus.verified,
                status=SchemeStatus.active,
                lastVerified=datetime(2026, 9, 15),
                isPopular=True,
                popularityRank=1,
            ),
            SchemeModelSchema(
                schemeId="pmjay-002",
                name="Ayushman Bharat - PM Jan Arogya Yojana",
                nameHindi="आयुष्मान भारत - प्रधानमंत्री जन आरोग्य योजना",
                description="Health insurance coverage of up to Rs 5 lakh per family per year for secondary and tertiary care hospitalization.",
                descriptionHindi="द्वितीयक और तृतीयक अस्पताल में भर्ती के लिए प्रति परिवार प्रति वर्ष 5 लाख रुपये तक का स्वास्थ्य बीमा।",
                category="health",
                ministry="Ministry of Health and Family Welfare",
                governmentLevel=GovernmentLevel.central,
                applicableStates=[],
                benefits="Cashless and paperless access to healthcare services up to ₹5,00,000 per family per year across empaneled public and private hospitals.",
                benefitsHindi="प्रति परिवार प्रति वर्ष ₹5,00,000 तक सूचीबद्ध अस्पतालों में कैशलेस स्वास्थ्य सेवाएं।",
                eligibilityRules=[
                    EligibilityRuleSchema(
                        field="hasPriorityRationCard",
                        operator=EligibilityOperator.isTrue,
                        value=True,
                        isMandatory=True,
                        description="Must be identified in SECC 2011 deprivation lists, hold an Antyodaya (AAY) / BPL / Priority Ration Card under NFSA, or qualify under Ayushman Vay Vandana (Seniors 70+)",
                    ),
                    EligibilityRuleSchema(
                        field="hasAadhaarOrIdProof",
                        operator=EligibilityOperator.isTrue,
                        value=True,
                        isMandatory=True,
                        description="Must possess valid Aadhaar Card or authorized government photo identity proof",
                    ),
                ],
                requiredDocuments=[
                    "Aadhaar Card or Ration Card",
                    "Family Identification Certificate / Ration Card",
                    "Active Mobile Number",
                ],
                applicationProcess="Check eligibility at pmjay.gov.in or visit any empaneled hospital or CSC to generate Ayushman Card.",
                applicationUrl="https://beneficiary.nha.gov.in/",
                officialSourceUrl="https://pmjay.gov.in/",
                sourceName="pmjay.gov.in",
                sourceType=SchemeSourceType.curated,
                verificationStatus=VerificationStatus.verified,
                status=SchemeStatus.active,
                lastVerified=datetime(2026, 8, 20),
                isPopular=True,
                popularityRank=2,
            ),
            SchemeModelSchema(
                schemeId="pmay-g-003",
                name="Pradhan Mantri Awaas Yojana - Gramin",
                nameHindi="प्रधानमंत्री आवास योजना - ग्रामीण",
                description="Financial assistance to rural houseless families and those living in kutcha houses for construction of pucca houses.",
                descriptionHindi="ग्रामीण बेघर परिवारों और कच्चे घरों में रहने वालों को पक्के मकान के निर्माण के लिए वित्तीय सहायता।",
                category="housing",
                ministry="Ministry of Rural Development",
                governmentLevel=GovernmentLevel.central,
                applicableStates=[],
                benefits="Grant assistance of ₹1,20,000 in plains and ₹1,30,000 in hilly/difficult areas along with 90-95 person-days of unskilled labor via MGNREGA.",
                benefitsHindi="मैदानी क्षेत्रों में ₹1,20,000 और दुर्गम क्षेत्रों में ₹1,30,000 की मकान निर्माण अनुदान सहायता।",
                eligibilityRules=[
                    EligibilityRuleSchema(
                        field="residenceType",
                        operator=EligibilityOperator.equals,
                        value="rural",
                        isMandatory=True,
                        description="Must reside in a recognized rural area",
                    ),
                    EligibilityRuleSchema(
                        field="hasHouse",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Family must not already own a pucca permanent house and live in kutcha structure",
                    ),
                    EligibilityRuleSchema(
                        field="hasMotorizedVehicle",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: Household must not own a motorized 2/3/4-wheeler or heavy agricultural equipment",
                    ),
                    EligibilityRuleSchema(
                        field="isGovernmentEmployee",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: Household must not have any regular government employee",
                    ),
                ],
                requiredDocuments=[
                    "Aadhaar Card",
                    "Bank Account details with Aadhaar seeding",
                    "Job Card under MGNREGA (if available)",
                    "Land ownership or homestead allotment document",
                ],
                applicationProcess="Registration through Gram Panchayat or Block Development Office based on SECC verification.",
                applicationUrl="https://pmayg.nic.in/",
                officialSourceUrl="https://pmayg.nic.in/",
                sourceName="pmayg.nic.in",
                sourceType=SchemeSourceType.curated,
                verificationStatus=VerificationStatus.verified,
                status=SchemeStatus.active,
                lastVerified=datetime(2026, 7, 10),
                isPopular=True,
                popularityRank=3,
            ),
            SchemeModelSchema(
                schemeId="pmuy-004",
                name="Pradhan Mantri Ujjwala Yojana 2.0",
                nameHindi="प्रधानमंत्री उज्ज्वला योजना 2.0",
                description="Free deposit-free LPG connection along with first refill and hotplate stove for adult women from poor households.",
                descriptionHindi="गरीब परिवारों की वयस्क महिलाओं के लिए मुफ्त एलपीजी कनेक्शन, पहला रिफिल और गैस चूल्हा।",
                category="women",
                ministry="Ministry of Petroleum and Natural Gas",
                governmentLevel=GovernmentLevel.central,
                applicableStates=[],
                benefits="Deposit-free LPG connection, free first cylinder refill, free gas stove, and government subsidy on subsequent refills.",
                benefitsHindi="जमानत-मुक्त एलपीजी कनेक्शन, मुफ्त पहला रिफिल सिलेंडर और गैस चूल्हा।",
                eligibilityRules=[
                    EligibilityRuleSchema(
                        field="gender",
                        operator=EligibilityOperator.equals,
                        value="female",
                        isMandatory=True,
                        description="Applicant must be an adult woman",
                    ),
                    EligibilityRuleSchema(
                        field="age",
                        operator=EligibilityOperator.greaterThanOrEqual,
                        value=18,
                        isMandatory=True,
                        description="Minimum age is 18 years",
                    ),
                    EligibilityRuleSchema(
                        field="existingLPG",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Household must not already possess an active LPG connection",
                    ),
                    EligibilityRuleSchema(
                        field="isVulnerableCategory",
                        operator=EligibilityOperator.isTrue,
                        value=True,
                        isMandatory=True,
                        description="Household must belong to eligible vulnerable category (SC/ST, PMAY, AAY/BPL, Forest dweller, MBC, or 14-point declaration)",
                    ),
                ],
                requiredDocuments=[
                    "Aadhaar Card of applicant and adult family members",
                    "Ration Card / Family Composition Certificate",
                    "Active Bank Account with IFSC code",
                    "Proof of Address / Domicile Certificate",
                ],
                applicationProcess="Apply online at pmuy.gov.in or submit physical application at nearest LPG distributor agency.",
                applicationUrl="https://www.pmuy.gov.in/ujjwala2.html",
                officialSourceUrl="https://www.pmuy.gov.in/",
                sourceName="pmuy.gov.in",
                sourceType=SchemeSourceType.curated,
                verificationStatus=VerificationStatus.verified,
                status=SchemeStatus.active,
                lastVerified=datetime(2026, 9, 1),
                isPopular=True,
                popularityRank=4,
            ),
            SchemeModelSchema(
                schemeId="pmss-005",
                name="Prime Minister Scholarship Scheme",
                nameHindi="प्रधानमंत्री छात्रवृत्ति योजना",
                description="Scholarship for dependent wards and widows of ex-servicemen pursuing professional degree courses.",
                descriptionHindi="पूर्व सैनिकों के आश्रित बच्चों और विधवाओं के लिए व्यावसायिक डिग्री पाठ्यक्रमों में छात्रवृत्ति।",
                category="education",
                ministry="Ministry of Defence",
                governmentLevel=GovernmentLevel.central,
                applicableStates=[],
                benefits="Financial assistance of ₹2,500/month for boys and ₹3,000/month for girls pursuing recognized professional and technical degree courses.",
                benefitsHindi="लड़कों के लिए ₹2,500/माह और लड़कियों के लिए ₹3,000/माह की छात्रवृत्ति।",
                eligibilityRules=[
                    EligibilityRuleSchema(
                        field="isDependentOfExServiceman",
                        operator=EligibilityOperator.isTrue,
                        value=True,
                        isMandatory=True,
                        description="Must be dependent ward (son/daughter) or unmarried widow of an ex-serviceman/ex-Coast Guard (ESM themselves ineligible)",
                    ),
                    EligibilityRuleSchema(
                        field="isProfessionalCourse",
                        operator=EligibilityOperator.isTrue,
                        value=True,
                        isMandatory=True,
                        description="Must be enrolled in an approved technical/professional degree course (Engineering, MBBS, MBA, etc. General BA/BSc excluded)",
                    ),
                    EligibilityRuleSchema(
                        field="meqMarksPercentage",
                        operator=EligibilityOperator.greaterThanOrEqual,
                        value=60.0,
                        isMandatory=True,
                        description="Must have scored at least 60% marks in entry qualification",
                    ),
                    EligibilityRuleSchema(
                        field="age",
                        operator=EligibilityOperator.lessThanOrEqual,
                        value=30,
                        isMandatory=True,
                        description="Candidate age must be within 30 years at admission",
                    ),
                ],
                requiredDocuments=[
                    "Aadhaar Card",
                    "Ex-Servicemen Certificate / PPO / Discharge Book",
                    "Admission verification from UGC/AICTE approved college",
                    "10+2 / Diploma Marksheet with minimum 60% marks",
                    "Bank Account seeded with Aadhaar",
                ],
                applicationProcess="Submit online application via the Kendriya Sainik Board portal (ksb.gov.in).",
                applicationUrl="https://ksb.gov.in/pm-scholarship.htm",
                officialSourceUrl="https://ksb.gov.in/",
                sourceName="ksb.gov.in",
                sourceType=SchemeSourceType.curated,
                verificationStatus=VerificationStatus.verified,
                status=SchemeStatus.active,
                lastVerified=datetime(2026, 6, 12),
                isPopular=False,
                popularityRank=5,
            ),
            SchemeModelSchema(
                schemeId="ladli-behna-006",
                name="Mukhyamantri Ladli Behna Yojana (MP)",
                nameHindi="मुख्यमंत्री लाड़ली बहना योजना (मध्य प्रदेश)",
                description="Direct monthly financial grant of Rs 1,250 to married and underprivileged women resident in Madhya Pradesh.",
                descriptionHindi="मध्य प्रदेश की पात्र महिलाओं को 1,250 रुपये प्रतिमाह की प्रत्यक्ष आर्थिक सहायता।",
                category="women",
                ministry="Department of Women and Child Development, MP",
                governmentLevel=GovernmentLevel.state,
                applicableStates=["Madhya Pradesh", "MP"],
                benefits="Direct benefit transfer of ₹1,250 per month into the beneficiary woman's Aadhaar-linked DBT bank account.",
                benefitsHindi="महिला के आधार-लिंक्ड बैंक खाते में प्रति माह ₹1,250 का सीधा डीबीटी ट्रांसफर।",
                eligibilityRules=[
                    EligibilityRuleSchema(
                        field="gender",
                        operator=EligibilityOperator.equals,
                        value="female",
                        isMandatory=True,
                        description="Applicant must be female",
                    ),
                    EligibilityRuleSchema(
                        field="state",
                        operator=EligibilityOperator.inList,
                        value=["Madhya Pradesh", "MP"],
                        isMandatory=True,
                        description="Must be a permanent resident of Madhya Pradesh",
                    ),
                    EligibilityRuleSchema(
                        field="maritalStatus",
                        operator=EligibilityOperator.inList,
                        value=["married", "widowed", "divorced"],
                        isMandatory=True,
                        description="Applicant must be married, widowed, or divorced (unmarried women are excluded)",
                    ),
                    EligibilityRuleSchema(
                        field="age",
                        operator=EligibilityOperator.greaterThanOrEqual,
                        value=21,
                        isMandatory=True,
                        description="Minimum age is 21 years",
                    ),
                    EligibilityRuleSchema(
                        field="age",
                        operator=EligibilityOperator.lessThanOrEqual,
                        value=60,
                        isMandatory=True,
                        description="Maximum age is 60 years",
                    ),
                    EligibilityRuleSchema(
                        field="annualIncome",
                        operator=EligibilityOperator.lessThanOrEqual,
                        value=250000,
                        isMandatory=True,
                        description="Combined family annual income must not exceed ₹2.5 lakh",
                    ),
                    EligibilityRuleSchema(
                        field="isIncomeTaxPayer",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: No member of family must be an income tax payer",
                    ),
                    EligibilityRuleSchema(
                        field="hasFourWheeler",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: Family must not own a four-wheeler motor vehicle (excluding tractor)",
                    ),
                    EligibilityRuleSchema(
                        field="isGovernmentEmployee",
                        operator=EligibilityOperator.isFalse,
                        value=False,
                        isMandatory=True,
                        description="Exclusion: No family member must be a regular/contractual government employee or pensioner",
                    ),
                ],
                requiredDocuments=[
                    "Samagra Family ID and Member ID",
                    "Aadhaar Card",
                    "DBT-enabled Bank Passbook",
                    "Registered Mobile Number linked with Aadhaar",
                ],
                applicationProcess="Apply at Gram Panchayat camps, Ward offices, or through the official Ladli Behna portal.",
                applicationUrl="https://cmladlibahna.mp.gov.in/",
                officialSourceUrl="https://cmladlibahna.mp.gov.in/",
                sourceName="cmladlibahna.mp.gov.in",
                sourceType=SchemeSourceType.curated,
                verificationStatus=VerificationStatus.verified,
                status=SchemeStatus.active,
                lastVerified=datetime(2026, 9, 25),
                isPopular=True,
                popularityRank=6,
            ),
        ]
        for s in baseline:
            self._schemes[s.schemeId] = s

    async def get_scheme(self, scheme_id: str) -> Optional[SchemeModelSchema]:
        return self._schemes.get(scheme_id)

    async def search_schemes(
        self,
        query: str,
        category: Optional[str] = None,
        level: Optional[GovernmentLevel] = None,
        state: Optional[str] = None,
        limit: int = 20,
    ) -> List[SchemeModelSchema]:
        results = []
        q = query.strip().lower()

        for s in self._schemes.values():
            # Keyword matching across name, Hindi name, description, benefits, ministry
            matches_query = (
                not q
                or q in s.name.lower()
                or (s.nameHindi and q in s.nameHindi.lower())
                or q in s.description.lower()
                or q in s.benefits.lower()
                or q in s.ministry.lower()
            )
            if not matches_query:
                continue

            # Category filter
            if category and s.category.lower() != category.lower():
                continue

            # Level filter
            if level and s.governmentLevel != level:
                continue

            # State filter
            if state and s.governmentLevel == GovernmentLevel.state:
                if not any(state.lower() == st.lower() for st in s.applicableStates):
                    continue

            results.append(s)
            if len(results) >= limit:
                break

        return results

    async def list_all_schemes(self, limit: int = 100) -> List[SchemeModelSchema]:
        return list(self._schemes.values())[:limit]

    async def save_discovered_scheme(self, scheme: SchemeModelSchema) -> bool:
        self._schemes[scheme.schemeId] = scheme
        return True


# Global database instance
db_instance: SchemeDatabaseInterface = InMemorySchemeDatabase()


def get_scheme_db() -> SchemeDatabaseInterface:
    """Dependency injector for scheme database."""
    return db_instance

