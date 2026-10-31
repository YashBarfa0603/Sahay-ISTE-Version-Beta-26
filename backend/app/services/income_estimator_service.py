"""
Unknown Household Income Estimation Service.
Computes conservative annual income ranges with clear assumptions and threshold mapping.
Enforces zero-retention privacy: inputs and estimates are temporary session data.
"""

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class IncomeEstimationInput(BaseModel):
    primary_source: str = "unorganized_labor"  # farming, daily_wage, street_vendor, salary, business, other
    monthly_estimated_income: Optional[float] = None
    household_earners: int = 1
    has_agricultural_income: bool = False
    seasonal_agricultural_income: Optional[float] = None
    notes: Optional[str] = None


class ThresholdComparisonResult(BaseModel):
    schemeId: str
    thresholdAmount: float
    status: str  # satisfies_condition, fails_condition, crosses_threshold, unverified
    explanation: str


class IncomeEstimationOutput(BaseModel):
    min_annual_income: float
    max_annual_income: float
    median_estimate: float
    uncertainty_level: str  # low, moderate, high
    assumptions: List[str]
    explanation: str
    requires_official_verification: bool = True
    threshold_evaluations: List[ThresholdComparisonResult] = Field(default_factory=list)


class IncomeEstimatorService:
    """Calculates conservative annual household income estimates for uncertain citizens."""

    # Default monthly benchmark medians for informal sectors when citizen answers 'I do not know'
    SECTOR_MONTHLY_BENCHMARKS = {
        "farming": 8000.0,
        "agricultural_worker": 6500.0,
        "daily_wage": 7500.0,
        "street_vendor": 9000.0,
        "artisan": 8500.0,
        "unorganized_worker": 7000.0,
        "salaried_private": 18000.0,
        "small_business": 15000.0,
        "other": 8000.0,
    }

    def estimate_income(
        self,
        data: IncomeEstimationInput,
        scheme_thresholds: Optional[Dict[str, float]] = None,
    ) -> IncomeEstimationOutput:
        source = data.primary_source.lower()
        benchmark = self.SECTOR_MONTHLY_BENCHMARKS.get(source, 8000.0)

        # Use citizen's approximate monthly estimate if provided, else use sector baseline
        monthly_base = data.monthly_estimated_income if (data.monthly_estimated_income and data.monthly_estimated_income > 0) else benchmark
        earners = max(1, min(data.household_earners, 8))

        base_annual = monthly_base * 12 * earners
        agri_annual = 0.0

        assumptions: List[str] = []
        uncertainty = "low" if (data.monthly_estimated_income is not None and data.monthly_estimated_income > 0) else "moderate"

        if data.monthly_estimated_income:
            assumptions.append(f"Based on approximate monthly earning of ₹{monthly_base:,.0f} per earner.")
        else:
            assumptions.append(f"Applied conservative benchmark of ₹{benchmark:,.0f}/month for {source.replace('_', ' ').title()}.")

        assumptions.append(f"Calculated across {earners} earning member(s) in the family.")

        if data.has_agricultural_income:
            agri_annual = data.seasonal_agricultural_income if data.seasonal_agricultural_income else 25000.0
            assumptions.append(f"Added estimated seasonal farm harvest income of ₹{agri_annual:,.0f}.")
            uncertainty = "moderate" if uncertainty == "low" else "high"

        total_median = base_annual + agri_annual

        # Unorganized and informal income has higher variance (lower bound -20%, upper bound +25%)
        variance_lower = 0.80 if source in ["daily_wage", "street_vendor", "farming"] else 0.90
        variance_upper = 1.30 if source in ["daily_wage", "street_vendor", "farming"] else 1.15

        min_annual = round(total_median * variance_lower, -2)
        max_annual = round(total_median * variance_upper, -2)

        explanation = (
            f"Estimated annual household income ranges between ₹{min_annual:,.0f} and ₹{max_annual:,.0f}. "
            "This conservative estimate is provided to guide scheme qualification and does not replace "
            "an official Tehsildar/Revenue Income Certificate."
        )

        threshold_evals: List[ThresholdComparisonResult] = []
        if scheme_thresholds:
            for s_id, limit in scheme_thresholds.items():
                if max_annual <= limit:
                    st = "satisfies_condition"
                    exp = f"Entire estimated range (up to ₹{max_annual:,.0f}) is below the scheme limit of ₹{limit:,.0f}."
                elif min_annual > limit:
                    st = "fails_condition"
                    exp = f"Estimated lower bound (₹{min_annual:,.0f}) exceeds the scheme threshold of ₹{limit:,.0f}."
                else:
                    st = "crosses_threshold"
                    exp = f"Estimated range crosses the ₹{limit:,.0f} threshold. Needs formal income documentation to confirm."
                threshold_evals.append(
                    ThresholdComparisonResult(
                        schemeId=s_id,
                        thresholdAmount=limit,
                        status=st,
                        explanation=exp,
                    )
                )

        return IncomeEstimationOutput(
            min_annual_income=min_annual,
            max_annual_income=max_annual,
            median_estimate=total_median,
            uncertainty_level=uncertainty,
            assumptions=assumptions,
            explanation=explanation,
            requires_official_verification=True,
            threshold_evaluations=threshold_evals,
        )
