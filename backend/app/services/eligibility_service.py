"""
Deterministic Eligibility Evaluation Service for SAHAY.
Strictly non-LLM, rule-based verification ensuring verifiable correctness.
"""

from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field
from backend.app.models.scheme_schemas import (
    EligibilityOperator,
    EligibilityRuleSchema,
    SchemeModelSchema,
)


class EvaluationVerdict(str, Enum):
    mayQualify = "mayQualify"
    doesNotQualify = "doesNotQualify"
    needsMoreInformation = "needsMoreInformation"


class RuleEvaluationResult(BaseModel):
    field: str
    satisfied: bool
    operator: str
    expectedValue: Any
    actualValue: Any
    isMandatory: bool
    isMissing: bool = False
    isBorderline: bool = False
    explanation: str


class SchemeEvaluationReport(BaseModel):
    schemeId: str
    schemeName: str
    verdict: EvaluationVerdict
    matchedRulesCount: int
    totalRulesCount: int
    confidenceScore: float
    reasons: List[str]
    missingFields: List[str]
    borderlineWarnings: List[str]
    ruleBreakdown: List[RuleEvaluationResult]


class EligibilityEvaluationService:
    """Evaluates citizen eligibility against verified scheme rules deterministically."""

    def evaluate_scheme(
        self,
        scheme: SchemeModelSchema,
        user_answers: Dict[str, Any],
    ) -> SchemeEvaluationReport:
        rules = scheme.eligibilityRules
        if not rules:
            return SchemeEvaluationReport(
                schemeId=scheme.schemeId,
                schemeName=scheme.name,
                verdict=EvaluationVerdict.needsMoreInformation,
                matchedRulesCount=0,
                totalRulesCount=0,
                confidenceScore=0.5,
                reasons=["Scheme has no verified rules configured. Needs official review."],
                missingFields=[],
                borderlineWarnings=[],
                ruleBreakdown=[],
            )

        matched_count = 0
        missing_fields: List[str] = []
        borderline_warnings: List[str] = []
        reasons: List[str] = []
        breakdown: List[RuleEvaluationResult] = []
        has_failed_mandatory = False

        for rule in rules:
            field = rule.field
            has_val = field in user_answers and user_answers[field] is not None
            actual_val = user_answers.get(field)

            if not has_val:
                missing_fields.append(field)
                breakdown.append(
                    RuleEvaluationResult(
                        field=field,
                        satisfied=False,
                        operator=rule.operator.value,
                        expectedValue=rule.value,
                        actualValue=None,
                        isMandatory=rule.isMandatory,
                        isMissing=True,
                        explanation=f"Missing answer for: {rule.description or field}",
                    )
                )
                continue

            satisfied, is_borderline, expl = self._evaluate_condition(
                operator=rule.operator,
                expected=rule.value,
                actual=actual_val,
                desc=rule.description or field,
            )

            if is_borderline:
                borderline_warnings.append(
                    f"{rule.description or field}: Your value ({actual_val}) is near the limit ({rule.value})."
                )

            breakdown.append(
                RuleEvaluationResult(
                    field=field,
                    satisfied=satisfied,
                    operator=rule.operator.value,
                    expectedValue=rule.value,
                    actualValue=actual_val,
                    isMandatory=rule.isMandatory,
                    isMissing=False,
                    isBorderline=is_borderline,
                    explanation=expl,
                )
            )

            if satisfied:
                matched_count += 1
                reasons.append(f"Satisfies {rule.description or field}")
            else:
                if rule.isMandatory:
                    has_failed_mandatory = True
                    reasons.append(f"Does not meet mandatory requirement: {expl}")

        # Verdict assignment
        total = len(rules)
        if has_failed_mandatory:
            verdict = EvaluationVerdict.doesNotQualify
            confidence = 0.95
        elif missing_fields:
            verdict = EvaluationVerdict.needsMoreInformation
            confidence = 0.5
        elif matched_count == total:
            verdict = EvaluationVerdict.mayQualify
            confidence = 0.95 if not borderline_warnings else 0.8
        else:
            verdict = EvaluationVerdict.doesNotQualify
            confidence = 0.85

        return SchemeEvaluationReport(
            schemeId=scheme.schemeId,
            schemeName=scheme.name,
            verdict=verdict,
            matchedRulesCount=matched_count,
            totalRulesCount=total,
            confidenceScore=confidence,
            reasons=reasons,
            missingFields=missing_fields,
            borderlineWarnings=borderline_warnings,
            ruleBreakdown=breakdown,
        )

    def evaluate_all(
        self,
        schemes: List[SchemeModelSchema],
        user_answers: Dict[str, Any],
    ) -> List[SchemeEvaluationReport]:
        return [self.evaluate_scheme(s, user_answers) for s in schemes]

    def _evaluate_condition(
        self,
        operator: EligibilityOperator,
        expected: Any,
        actual: Any,
        desc: str,
    ) -> tuple[bool, bool, str]:
        """Evaluates single condition returning (satisfied, is_borderline, explanation)."""
        is_borderline = False

        if operator == EligibilityOperator.equals:
            sat = str(actual).strip().lower() == str(expected).strip().lower()
            expl = f"{desc} matches requirement ({expected})" if sat else f"{desc} does not match {expected} (found {actual})"
            return sat, False, expl

        if operator == EligibilityOperator.notEquals:
            sat = str(actual).strip().lower() != str(expected).strip().lower()
            return sat, False, f"Different from {expected}" if sat else f"Matches excluded value {expected}"

        if operator == EligibilityOperator.isTrue:
            sat = bool(actual) is True
            return sat, False, f"Requirement confirmed ({desc})" if sat else f"Required confirmation not met ({desc})"

        if operator == EligibilityOperator.isFalse:
            sat = bool(actual) is False
            return sat, False, f"Requirement satisfied (not excluded)" if sat else f"Condition triggers exclusion ({desc})"

        # Numeric comparisons
        try:
            num_actual = float(actual)
            num_expected = float(expected)
        except (ValueError, TypeError):
            return False, False, f"Invalid numeric comparison for {desc}: actual={actual}, expected={expected}"

        diff_ratio = abs(num_actual - num_expected) / (num_expected if num_expected != 0 else 1.0)
        is_borderline = diff_ratio <= 0.10  # within 10% threshold

        if operator == EligibilityOperator.lessThan:
            sat = num_actual < num_expected
            return sat, is_borderline, f"{actual} is below limit {expected}" if sat else f"{actual} exceeds limit {expected}"

        if operator == EligibilityOperator.lessThanOrEqual:
            sat = num_actual <= num_expected
            return sat, is_borderline, f"{actual} is within limit {expected}" if sat else f"{actual} exceeds upper limit {expected}"

        if operator == EligibilityOperator.greaterThan:
            sat = num_actual > num_expected
            return sat, is_borderline, f"{actual} meets minimum {expected}" if sat else f"{actual} below minimum {expected}"

        if operator == EligibilityOperator.greaterThanOrEqual:
            sat = num_actual >= num_expected
            return sat, is_borderline, f"{actual} satisfies minimum {expected}" if sat else f"{actual} below minimum required {expected}"

        if operator == EligibilityOperator.inList:
            expected_list = expected if isinstance(expected, list) else [expected]
            sat = any(str(actual).strip().lower() == str(e).strip().lower() for e in expected_list)
            return sat, False, f"Found in eligible list" if sat else f"Value '{actual}' not in eligible categories"

        if operator == EligibilityOperator.notInList:
            expected_list = expected if isinstance(expected, list) else [expected]
            sat = not any(str(actual).strip().lower() == str(e).strip().lower() for e in expected_list)
            return sat, False, f"Not in excluded list" if sat else f"Value '{actual}' is in excluded list"

        return False, False, "Unknown comparison operator"

