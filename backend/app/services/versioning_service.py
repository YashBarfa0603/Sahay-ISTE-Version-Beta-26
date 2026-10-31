"""
Scheme Rule Versioning and Source Verification Audit System.
Maintains rule provenance, version immutability, candidate review, and rollback capabilities.
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from backend.app.models.scheme_schemas import (
    EligibilityRuleSchema,
    SchemeModelSchema,
    VerificationStatus,
)


class RuleVersionRecord(BaseModel):
    version: int
    schemeId: str
    rules: List[EligibilityRuleSchema]
    officialSourceUrl: str
    sourceName: str
    department: str
    verifiedBy: str
    verificationNotes: str
    verificationStatus: VerificationStatus
    effectiveFrom: datetime = Field(default_factory=datetime.utcnow)
    isActive: bool = True


class CandidateRuleProposal(BaseModel):
    proposalId: str
    schemeId: str
    proposedRules: List[EligibilityRuleSchema]
    sourceUrl: str
    sourceName: str
    department: str
    justification: str
    proposedBy: str = "ai_discovery_pipeline"
    status: str = "pending_human_review"  # pending_human_review, approved, rejected
    reviewedBy: Optional[str] = None
    reviewNotes: Optional[str] = None
    createdAt: datetime = Field(default_factory=datetime.utcnow)


class SchemeVersioningService:
    """
    Manages scheme rule history, audit trails, and version rollbacks.
    INVARIANT: Discovered or LLM-extracted rules CANNOT directly modify active production rules.
    They must be proposed as CandidateRuleProposal and approved.
    """

    def __init__(self):
        # scheme_id -> list of version records (most recent last)
        self._version_history: Dict[str, List[RuleVersionRecord]] = {}
        # proposal_id -> proposal
        self._candidate_proposals: Dict[str, CandidateRuleProposal] = {}

    def initialize_scheme_version(self, scheme: SchemeModelSchema, verified_by: str = "curator"):
        """Initializes Version 1 for a verified baseline scheme."""
        if scheme.schemeId not in self._version_history:
            v1 = RuleVersionRecord(
                version=1,
                schemeId=scheme.schemeId,
                rules=scheme.eligibilityRules,
                officialSourceUrl=scheme.officialSourceUrl,
                sourceName=scheme.sourceName or "Official Department",
                department=scheme.ministry,
                verifiedBy=verified_by,
                verificationNotes="Initial baseline verified release.",
                verificationStatus=scheme.verificationStatus,
                effectiveFrom=datetime.utcnow(),
                isActive=True,
            )
            self._version_history[scheme.schemeId] = [v1]

    def get_active_version(self, scheme_id: str) -> Optional[RuleVersionRecord]:
        history = self._version_history.get(scheme_id, [])
        for record in reversed(history):
            if record.isActive:
                return record
        return None

    def get_version_history(self, scheme_id: str) -> List[RuleVersionRecord]:
        return list(self._version_history.get(scheme_id, []))

    def submit_candidate_proposal(self, proposal: CandidateRuleProposal) -> str:
        """Stores candidate rules proposed by AI discovery or scraper for human review."""
        self._candidate_proposals[proposal.proposalId] = proposal
        return proposal.proposalId

    def list_pending_proposals(self, scheme_id: Optional[str] = None) -> List[CandidateRuleProposal]:
        proposals = [p for p in self._candidate_proposals.values() if p.status == "pending_human_review"]
        if scheme_id:
            proposals = [p for p in proposals if p.schemeId == scheme_id]
        return proposals

    def approve_proposal(
        self,
        proposal_id: str,
        reviewer_id: str,
        notes: str,
    ) -> Optional[RuleVersionRecord]:
        """Human reviewer approves candidate rules, creating a new production rule version."""
        proposal = self._candidate_proposals.get(proposal_id)
        if not proposal or proposal.status != "pending_human_review":
            return None

        proposal.status = "approved"
        proposal.reviewedBy = reviewer_id
        proposal.reviewNotes = notes

        # Deactivate existing active version
        history = self._version_history.setdefault(proposal.schemeId, [])
        for rec in history:
            rec.isActive = False

        new_version_num = len(history) + 1
        new_record = RuleVersionRecord(
            version=new_version_num,
            schemeId=proposal.schemeId,
            rules=proposal.proposedRules,
            officialSourceUrl=proposal.sourceUrl,
            sourceName=proposal.sourceName,
            department=proposal.department,
            verifiedBy=reviewer_id,
            verificationNotes=f"Approved from proposal {proposal_id}: {notes}",
            verificationStatus=VerificationStatus.verified,
            effectiveFrom=datetime.utcnow(),
            isActive=True,
        )
        history.append(new_record)
        return new_record

    def rollback_to_version(
        self,
        scheme_id: str,
        target_version: int,
        operator_id: str,
        reason: str,
    ) -> Optional[RuleVersionRecord]:
        """Rolls back scheme eligibility rules to a prior approved version."""
        history = self._version_history.get(scheme_id, [])
        target = next((r for r in history if r.version == target_version), None)
        if not target:
            return None

        for rec in history:
            rec.isActive = False

        new_version_num = len(history) + 1
        rollback_record = RuleVersionRecord(
            version=new_version_num,
            schemeId=scheme_id,
            rules=target.rules,
            officialSourceUrl=target.officialSourceUrl,
            sourceName=target.sourceName,
            department=target.department,
            verifiedBy=operator_id,
            verificationNotes=f"Rolled back to v{target_version}. Reason: {reason}",
            verificationStatus=VerificationStatus.verified,
            effectiveFrom=datetime.utcnow(),
            isActive=True,
        )
        history.append(rollback_record)
        return rollback_record
