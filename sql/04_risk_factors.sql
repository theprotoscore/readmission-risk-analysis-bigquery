-- 04_risk_factors.sql
-- Purpose : which patient/clinical factors are associated with higher 30-day readmission?
-- Reading : associations only. This is observational data; none of these results are causal.

-- 4.1 Prior inpatient visits in the year before admission (explicit buckets, no NTILE:
--     most patients have 0 prior visits, so quantile buckets would split tied values arbitrarily).
WITH agg AS (
  SELECT prior_inpatient_bucket AS prior_inpatient_visits, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT prior_inpatient_visits, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY prior_inpatient_visits;

-- 4.2 Prior emergency visits.
WITH agg AS (
  SELECT prior_ed_bucket AS prior_ed_visits, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT prior_ed_visits, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY prior_ed_visits;

-- 4.3 Medication burden tier (thresholds are a documented, arbitrary choice: see D8).
WITH agg AS (
  SELECT medication_burden_tier AS medication_burden_tier, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT medication_burden_tier, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY medication_burden_tier;

-- 4.4 Diagnosis complexity tier (number of diagnoses entered).
WITH agg AS (
  SELECT diagnosis_complexity_tier AS diagnosis_complexity_tier, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT diagnosis_complexity_tier, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY diagnosis_complexity_tier;

-- 4.5 Primary diagnosis group, ranked, with the gap to the overall rate (window functions).
WITH agg AS (
  SELECT diag1_group, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY diag1_group
  HAVING COUNT(*) >= 100
),
calc AS (
  SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z,
         SUM(readmits) OVER () / SUM(n) OVER () AS overall_p
  FROM agg
)
SELECT diag1_group, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct,
  ROUND(100 * (p - overall_p), 1) AS pts_vs_overall,
  RANK() OVER (ORDER BY p DESC)  AS rate_rank
FROM calc
ORDER BY rate_rank;

-- 4.6 Diagnosis groups ABOVE the overall rate.
--     HAVING with a scalar subquery. NOTE: this subquery is UNCORRELATED (it does not reference
--     the outer query).
SELECT diag1_group, COUNT(*) AS n,
       ROUND(100 * AVG(CAST(is_readmit_30d AS INT64)), 1) AS rate_pct
FROM readmission.analytic_cohort
GROUP BY diag1_group
HAVING COUNT(*) >= 100
   AND AVG(CAST(is_readmit_30d AS INT64)) >
       (SELECT AVG(CAST(is_readmit_30d AS INT64)) FROM readmission.analytic_cohort)
ORDER BY rate_pct DESC;

-- 4.6b Diagnosis groups that are CLEARLY above the overall rate: the Wilson lower bound must exceed it.
--      (4.6 above lists any group above average, even by a hair; this one controls for sample size.)
WITH agg AS (
  SELECT diag1_group, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY diag1_group
  HAVING COUNT(*) >= 100
),
calc AS (
  SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z,
         SUM(readmits) OVER () / SUM(n) OVER () AS overall_p
  FROM agg
)
SELECT diag1_group, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * overall_p, 1) AS overall_rate_pct
FROM calc
WHERE (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n) > overall_p
ORDER BY rate_pct DESC;

-- 4.6b Diagnosis groups CLEARLY above the overall rate: the Wilson lower bound must exceed it.
WITH agg AS (
  SELECT diag1_group, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY diag1_group
  HAVING COUNT(*) >= 100
),
calc AS (
  SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z,
         SUM(readmits) OVER () / SUM(n) OVER () AS overall_p
  FROM agg
)
SELECT diag1_group, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * overall_p, 1) AS overall_rate_pct
FROM calc
WHERE (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n) > overall_p
ORDER BY rate_pct DESC;

-- 4.7 Prior inpatient use relative to age-band peers.
--     Result note: in this cohort the flag is identical to 'at least 1 prior inpatient visit' (every age-band
--     average is below 1), so 4.7 demonstrates the technique and is not a separate finding.
--     RESULT NOTE: in this cohort the flag is identical to 'at least 1 prior inpatient visit' (the age-band
--     averages are all below 1), so treat 4.7 as a technique demo, not a separate finding.
--     (a) CORRELATED subquery: the inner query references c.age_band from the outer row.
--     (b) The same result with a window function. The two flag counts must match.
WITH flagged AS (
  SELECT c.is_readmit_30d,
    c.number_inpatient > (
      SELECT AVG(x.number_inpatient)
      FROM readmission.analytic_cohort x
      WHERE x.age_band = c.age_band
    ) AS above_peer_avg_correlated,
    c.number_inpatient > AVG(c.number_inpatient) OVER (PARTITION BY c.age_band) AS above_peer_avg_window
  FROM readmission.analytic_cohort c
)
SELECT above_peer_avg_correlated, above_peer_avg_window,
       COUNT(*) AS n,
       ROUND(100 * AVG(CAST(is_readmit_30d AS INT64)), 1) AS rate_pct
FROM flagged
GROUP BY 1, 2
ORDER BY 1, 2;
