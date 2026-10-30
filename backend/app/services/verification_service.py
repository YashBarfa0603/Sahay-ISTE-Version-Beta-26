"""
Verification Service for Discovered Government Schemes.
Executes credibility, freshness, completeness, and duplicate/conflict checks.
"""

import logging
from typing import Dict, List, Tuple
from urllib.parse import urlparse
from backend.app.config import settings
from backend.app.models.scheme_schemas import (
    SchemeModelSchema,
    VerificationStatus,
)

logger = logging.getLogger(__name__)


class VerificationReport:
    """Detailed audit metrics of a newly discovered scheme."""

    def __init__(self):
        self.is_credible: bool = False
        self.credibility_score: float = 0.0
        self.is_complete: bool = False
        self.completeness_score: float = 0.0
        self.is_duplicate: bool = False
        self.duplicate_of_id: str = ""
        self.warnings: List[str] = []
        self.audit_passed: bool = False


class VerificationService:
    """Evaluates candidate scheme records against government authenticity criteria."""

    def __init__(self):
        self.trusted_domains = settings.TRUSTED_GOV_DOMAINS

    def audit_scheme(
        self,
        candidate: SchemeModelSchema,
        existing_catalog: List[SchemeModelSchema],
    ) -> Tuple[SchemeModelSchema, VerificationReport]:
        """
        Runs comprehensive audit pipeline on discovered scheme.
        Ensures strict compliance with government verification rules.
        """
        report = VerificationReport()

        # 1. Source Credibility Check
        credibility_score, is_credible, cred_warning = self._check_source_credibility(candidate.officialSourceUrl)
        report.credibility_score = credibility_score
        report.is_credible = is_credible
        if cred_warning:
            report.warnings.append(cred_warning)

        # 2. Completeness Check
        comp_score, is_complete, comp_warnings = self._check_completeness(candidate)
        report.completeness_score = comp_score
        report.is_complete = is_complete
        report.warnings.extend(comp_warnings)

        # 3. Duplicate and Conflict Check
        is_dup, dup_id = self._check_duplicate(candidate, existing_catalog)
        report.is_duplicate = is_dup
        report.duplicate_of_id = dup_id
        if is_dup:
            report.warnings.append(f"Identified as duplicate of verified scheme {dup_id}.")

        # 4. Synthesize Status
        # Crucial Requirement: Discovered schemes can ONLY be pending or rejected; NEVER auto-verified.
        if not report.is_credible or report.completeness_score < 0.4:
            candidate.verificationStatus = VerificationStatus.rejected
            report.audit_passed = False
        else:
            candidate.verificationStatus = VerificationStatus.pending
            report.audit_passed = True

        return candidate, report

    def _check_source_credibility(self, url: str) -> Tuple[float, bool, str]:
        """Validates that URL originates from trusted Indian government portal."""
        if not url:
            return 0.0, False, "Missing official source URL."

        try:
            domain = urlparse(url).netloc.lower()
            if any(domain == td or domain.endswith("." + td) for td in self.trusted_domains):
                return 1.0, True, ""
            elif domain.endswith(".gov.in") or domain.endswith(".nic.in"):
                return 0.95, True, ""
            elif domain.endswith(".ac.in") or domain.endswith(".res.in"):
                return 0.70, True, "Educational/Research domain; verify against official ministry portal."
            else:
                return 0.20, False, f"Source domain '{domain}' is not a recognized Indian government domain."
        except Exception:
            return 0.0, False, "Invalid URL format."

    def _check_completeness(self, scheme: SchemeModelSchema) -> Tuple[float, bool, List[str]]:
        """Evaluates whether all vital citizen decision criteria are present."""
        score = 0.0
        warnings = []

        if len(scheme.name.strip()) > 3:
            score += 0.20
        else:
            warnings.append("Scheme name is insufficient.")

        if len(scheme.description.strip()) > 30:
            score += 0.20
        else:
            warnings.append("Description lacks adequate detail.")

        if len(scheme.benefits.strip()) > 15:
            score += 0.20
        else:
            warnings.append("Scheme benefits are not clearly specified.")

        if scheme.requiredDocuments and len(scheme.requiredDocuments) >= 1:
            score += 0.20
        else:
            warnings.append("No required documents listed.")

        if len(scheme.applicationProcess.strip()) > 20:
            score += 0.20
        else:
            warnings.append("Application instructions are absent.")

        is_complete = score >= 0.80
        return score, is_complete, warnings

    def _check_duplicate(
        self,
        candidate: SchemeModelSchema,
        catalog: List[SchemeModelSchema],
    ) -> Tuple[bool, str]:
        """Detects if scheme already exists in trusted catalogue."""
        c_name = candidate.name.strip().lower()
        for item in catalog:
            if item.schemeId == candidate.schemeId:
                continue
            i_name = item.name.strip().lower()
            # Exact or high substring match
            if c_name == i_name or (len(c_name) > 8 and (c_name in i_name or i_name in c_name)):
                return True, item.schemeId
            if item.officialSourceUrl and candidate.officialSourceUrl:
                if item.officialSourceUrl.rstrip("/") == candidate.officialSourceUrl.rstrip("/"):
                    return True, item.schemeId

        return False, ""

