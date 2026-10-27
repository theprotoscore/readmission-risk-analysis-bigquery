-- 07_risk_score_validation.sql
-- Purpose : a transparent points-based readmission risk score, validated on a HOLDOUT of patients.
-- Design  : points are simple and explainable (one point per risk signal; prior inpatient visits
--           capped at 3). They were chosen from clinical plausibility and the exploratory results in
--           04, which ran on all patients (docs/assumptions_and_decisions.md, D9).
-- Scoring is validated on dataset_split = 'validation' (30% of patients, deterministic hash split).
-- Ties are handled by grouping on the exact score (no NTILE), so identical scores are never split.

CREATE OR REPLACE VIEW readmission.scored_cohort AS
SELECT
  a.*,
    LEAST(COALESCE(number_inpatient, 0), 3)
  + IF(COALESCE(number_emergency, 0) >= 1, 1, 0)
  + IF(COALESCE(number_diagnoses, 0) >= 9, 1, 0)
  + IF(COALESCE(num_medications, 0) > 20, 1, 0)
  + IF(COALESCE(discharge_disposition_id, 0) != 1, 1, 0)   -- 1 = discharged to home
  AS risk_score
FROM readmission.analytic_cohort a;

-- 7.1 Score table on the validation set, highest score first, with cumulative capture and lift.
--     cum_pct_of_readmits = share of ALL readmissions found among patients at or above this score.
--     A useful score: rate rises with score, and lift at the top is clearly above 1.0.
WITH by_score AS (
  SELECT risk_score, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.scored_cohort
  WHERE dataset_split = 'validation'
  GROUP BY risk_score
),
cum AS (
  SELECT risk_score, n, readmits,
    SUM(n)        OVER (ORDER BY risk_score DESC) AS cum_n,
    SUM(readmits) OVER (ORDER BY risk_score DESC) AS cum_readmits,
    SUM(n)        OVER () AS tot_n,
    SUM(readmits) OVER () AS tot_readmits
  FROM by_score
)
SELECT risk_score, n, readmits,
  ROUND(100 * SAFE_DIVIDE(readmits, n), 1)               AS rate_pct,
  ROUND(100 * SAFE_DIVIDE(cum_n, tot_n), 1)              AS cum_pct_of_patients,
  ROUND(100 * SAFE_DIVIDE(cum_readmits, tot_readmits), 1) AS cum_pct_of_readmits,
  ROUND(SAFE_DIVIDE(SAFE_DIVIDE(cum_readmits, cum_n), SAFE_DIVIDE(tot_readmits, tot_n)), 2) AS cumulative_lift
FROM cum
ORDER BY risk_score DESC;

-- 7.2 Rate by score on both splits, for comparison.
SELECT dataset_split, risk_score, COUNT(*) AS n,
       ROUND(100 * AVG(CAST(is_readmit_30d AS INT64)), 1) AS rate_pct
FROM readmission.scored_cohort
GROUP BY dataset_split, risk_score
ORDER BY dataset_split, risk_score DESC;
