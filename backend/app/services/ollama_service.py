"""
Ollama Service for AI-assisted scheme information extraction using Qwen2.5.

RULE ADHERENCE:
Qwen2.5 is used solely to parse, structure, translate, and explain information.
It NEVER approves verificationStatus (always marked 'pending') and NEVER makes
eligibility decisions.
"""

import json
import logging
import re
import uuid
from datetime import datetime
from typing import Any, Dict, Optional
import httpx
from backend.app.config import settings
from backend.app.models.scheme_schemas import (
    SchemeModelSchema,
    GovernmentLevel,
    VerificationStatus,
    SchemeStatus,
    SchemeSourceType,
    EligibilityRuleSchema,
    EligibilityOperator,
)

logger = logging.getLogger(__name__)


EXTRACTION_PROMPT = """
You are an expert Indian Government Scheme Information Extraction Assistant for SAHAY (सहाय).
Your task is to analyze the provided text extracted from an official government webpage and
convert it into a strictly valid JSON object matching the exact schema below.

Do not guess or fabricate information. If a field is not present in the text, use null or an empty list.

JSON SCHEMA:
{
  "name": "Full official name of the scheme in English",
  "nameHindi": "Official or accurate Hindi name of the scheme in Devanagari script",
  "description": "2-3 sentence overview of what the scheme is and who it helps",
  "descriptionHindi": "Accurate Hindi translation of the description in Devanagari",
  "category": "One of: agriculture, health, housing, education, women, employment, socialWelfare, financial",
  "ministry": "Responsible Ministry or Government Department name",
  "governmentLevel": "central OR state",
  "applicableStates": ["List of Indian States if state-level, or empty list [] if all India"],
  "benefits": "Key quantifiable or qualitative benefits provided to beneficiaries",
  "benefitsHindi": "Hindi translation of the benefits",
  "eligibilityRules": [
    {
      "field": "One of: gender, age, annualIncome, occupation, residenceType, casteCategory, landOwnership, hasHouse, existingLPG, isExServiceman, hasBankAccount",
      "operator": "One of: equals, notEquals, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, inList, notInList, isTrue, isFalse",
      "value": "number, string, boolean, or list depending on operator",
      "isMandatory": true,
      "description": "Short explanation of this specific eligibility requirement"
    }
  ],
  "requiredDocuments": ["List of official documents needed to apply, e.g., Aadhaar Card, Ration Card"],
  "applicationProcess": "Clear step-by-step instructions on how a citizen applies",
  "applicationUrl": "Direct URL to apply online if mentioned, else null"
}

Respond ONLY with the raw JSON object. Do not include markdown code blocks or surrounding text.
"""


class OllamaService:
    """Interfaces with locally running Ollama instance hosting Qwen2.5."""

    def __init__(self, base_url: Optional[str] = None, model: Optional[str] = None):
        self.base_url = (base_url or settings.OLLAMA_BASE_URL).rstrip("/")
        self.model = model or settings.OLLAMA_MODEL

    async def extract_scheme_data(
        self,
        raw_text: str,
        source_url: str,
        source_name: Optional[str] = None,
    ) -> Optional[SchemeModelSchema]:
        """
        Sends extracted webpage text to Qwen2.5 via Ollama API to extract
        structured SchemeModelSchema data.
        """
        try:
            prompt = f"{EXTRACTION_PROMPT}\n\nOFFICIAL WEBPAGE TEXT CONTENT:\n{raw_text}"

            async with httpx.AsyncClient(timeout=45.0) as client:
                res = await client.post(
                    f"{self.base_url}/api/generate",
                    json={
                        "model": self.model,
                        "prompt": prompt,
                        "stream": False,
                        "format": "json",
                        "options": {"temperature": 0.1},
                    },
                )
                if res.status_code == 200:
                    response_json = res.json()
                    response_text = response_json.get("response", "{}")
                    parsed_dict = self._clean_and_parse_json(response_text)
                    if parsed_dict:
                        return self._construct_scheme_model(parsed_dict, source_url, source_name)
                else:
                    logger.warning(f"Ollama returned HTTP {res.status_code}")
        except Exception as e:
            logger.warning(f"Ollama Qwen2.5 unavailable or failed: {e}. Using deterministic heuristic parser.")

        # Fallback heuristic parser if Ollama is not active locally
        return self._heuristic_fallback_parser(raw_text, source_url, source_name)

    def _clean_and_parse_json(self, raw_response: str) -> Optional[Dict[str, Any]]:
        """Cleans and extracts JSON object from LLM response."""
        try:
            # Strip markdown formatting if any was returned
            cleaned = re.sub(r"^```(json)?", "", raw_response.strip(), flags=re.MULTILINE)
            cleaned = re.sub(r"```$", "", cleaned.strip(), flags=re.MULTILINE).strip()
            return json.loads(cleaned)
        except Exception as e:
            logger.error(f"Failed to parse JSON from LLM: {e}")
            return None

    def _construct_scheme_model(
        self,
        data: Dict[str, Any],
        source_url: str,
        source_name: Optional[str],
    ) -> SchemeModelSchema:
        """Assembles SchemeModelSchema from LLM output, strictly enforcing safety defaults."""
        scheme_id = f"disc-{uuid.uuid4().hex[:8]}"

        rules = []
        for r in data.get("eligibilityRules", []):
            try:
                rules.append(
                    EligibilityRuleSchema(
                        field=r.get("field", "annualIncome"),
                        operator=EligibilityOperator(r.get("operator", "lessThanOrEqual")),
                        value=r.get("value", 0),
                        isMandatory=bool(r.get("isMandatory", True)),
                        description=r.get("description"),
                    )
                )
            except Exception:
                continue

        # Force safety defaults for discovered records
        return SchemeModelSchema(
            schemeId=scheme_id,
            name=data.get("name", "Discovered Government Scheme"),
            nameHindi=data.get("nameHindi"),
            description=data.get("description", "Discovered scheme details pending verification."),
            descriptionHindi=data.get("descriptionHindi"),
            category=data.get("category", "socialWelfare"),
            ministry=data.get("ministry", "Government of India"),
            governmentLevel=(
                GovernmentLevel.state
                if str(data.get("governmentLevel")).lower() == "state"
                else GovernmentLevel.central
            ),
            applicableStates=data.get("applicableStates", []),
            benefits=data.get("benefits", "Benefit details pending official verification."),
            benefitsHindi=data.get("benefitsHindi"),
            eligibilityRules=rules,
            requiredDocuments=data.get("requiredDocuments", ["Aadhaar Card"]),
            applicationProcess=data.get("applicationProcess", "Refer to official portal for application steps."),
            applicationUrl=data.get("applicationUrl"),
            officialSourceUrl=source_url,
            sourceName=source_name or "Official Portal",
            sourceType=SchemeSourceType.discovered,
            discoveredAt=datetime.utcnow(),
            verificationStatus=VerificationStatus.pending,  # NEVER automatically verified
            status=SchemeStatus.underVerification,
            lastVerified=None,
            isPopular=False,
            popularityRank=99,
        )

    def _heuristic_fallback_parser(
        self,
        raw_text: str,
        source_url: str,
        source_name: Optional[str],
    ) -> SchemeModelSchema:
        """Deterministic heuristic fallback when Ollama Qwen2.5 is not running."""
        scheme_id = f"disc-{uuid.uuid4().hex[:8]}"

        # Extract title from text or URL slug
        title = "Government Welfare Scheme"
        lines = [l.strip() for l in raw_text.splitlines() if len(l.strip()) > 5]
        if lines:
            title = lines[0][:80]

        return SchemeModelSchema(
            schemeId=scheme_id,
            name=title,
            description=raw_text[:250] + "...",
            category="socialWelfare",
            ministry="Government of India",
            governmentLevel=GovernmentLevel.central,
            applicableStates=[],
            benefits="Direct welfare benefits under government guidelines.",
            eligibilityRules=[],
            requiredDocuments=["Aadhaar Card", "Ration Card", "Bank Passbook"],
            applicationProcess="Apply through the official portal or visit the nearest Common Service Centre (CSC).",
            applicationUrl=source_url,
            officialSourceUrl=source_url,
            sourceName=source_name or "Official Government Source",
            sourceType=SchemeSourceType.discovered,
            discoveredAt=datetime.utcnow(),
            verificationStatus=VerificationStatus.pending,  # NEVER marked verified
            status=SchemeStatus.underVerification,
            lastVerified=None,
            isPopular=False,
            popularityRank=99,
        )

    async def explain_eligibility(
        self,
        report: Any,
        language: str = "en",
    ) -> Optional[str]:
        """
        Synthesizes a conversational explanation of deterministic evaluation results using Qwen2.5.
        Strictly bounded by verified condition differences; never alters verdict.
        """
        try:
            verdict_str = getattr(report, "verdict", "needs_more_information")
            if hasattr(verdict_str, "value"):
                verdict_str = verdict_str.value

            scheme_name = getattr(report, "schemeName", "Government Scheme")
            satisfied = getattr(report, "satisfiedConditions", [])
            unsatisfied = getattr(report, "unsatisfiedConditions", [])
            missing = getattr(report, "missingConditions", [])

            sat_lines = [f"- {c.label}: Your value '{c.formattedUserValue}' satisfied requirement '{c.required}' ({c.reason})" for c in satisfied]
            unsat_lines = [f"- {c.label}: Your value '{c.formattedUserValue}' FAILED requirement '{c.required}'. Reason: {c.reason}" for c in unsatisfied]
            miss_lines = [f"- {c.label}: Not provided. Required for: {c.required}" for c in missing]

            lang_name = "Hindi" if language == "hi" else "English"

            prompt = (
                f"You are SAHAY's transparent Government Scheme Eligibility Explainer.\n"
                f"Translate and explain the following deterministic eligibility results to an Indian citizen in clear, respectful {lang_name}.\n\n"
                f"STRICT RULES:\n"
                f"1. Overall Decision: '{verdict_str}'. DO NOT CHANGE THIS DECISION.\n"
                f"2. DO NOT state that the government has approved anything.\n"
                f"3. Explain why the user qualified or did not qualify using ONLY these verified conditions:\n"
                f"Scheme: {scheme_name}\n"
                f"Satisfied conditions:\n{chr(10).join(sat_lines) if sat_lines else 'None'}\n"
                f"Failed conditions:\n{chr(10).join(unsat_lines) if unsat_lines else 'None'}\n"
                f"Missing details needed:\n{chr(10).join(miss_lines) if miss_lines else 'None'}\n\n"
                f"Provide a concise, 2-3 sentence conversational summary in {lang_name}."
            )

            async with httpx.AsyncClient(timeout=3.0) as client:
                res = await client.post(
                    f"{self.base_url}/api/generate",
                    json={
                        "model": self.model,
                        "prompt": prompt,
                        "stream": False,
                        "options": {"temperature": 0.2},
                    },
                )
                if res.status_code == 200:
                    data = res.json()
                    text = data.get("response", "").strip()
                    if verdict_str == "does_not_appear_to_qualify":
                        lower_text = text.lower()
                        if "congratulations" in lower_text or "you are eligible" in lower_text or "बधाई" in lower_text:
                            logger.warning("LLM hallucinated approval on rejected scheme. Discarding output.")
                            return None
                    return text
        except Exception as e:
            logger.debug(f"Ollama Qwen2.5 explanation call failed: {e}")
            return None

