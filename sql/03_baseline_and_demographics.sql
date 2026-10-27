-- 03_baseline_and_demographics.sql
-- Purpose : baseline readmission picture. Every rate table reports n, readmits, rate and a
--           95% Wilson confidence interval so small groups are not over-read.
-- Metric  : 30-day readmission rate = share of cohort patients with readmitted = '<30'.

-- 3.1 Target distribution in the final cohort.
SELECT readmitted, COUNT(*) AS n,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM readmission.analytic_cohort
GROUP BY readmitted
ORDER BY n DESC;

-- 3.2 Overall 30-day readmission rate (the baseline every other table is compared to).
WITH agg AS (
  SELECT 'All patients' AS cohort, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT cohort, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY 1;

-- 3.3 By age band (sorted by age).
WITH agg AS (
  SELECT age_band AS age_band, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT age_band, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY age_band;

-- 3.4 By gender (missing/invalid gender kept as its own row).
WITH agg AS (
  SELECT COALESCE(gender, 'Unknown') AS gender, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT gender, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY n DESC;

-- 3.5 By race. Report as description only; do not infer causes (see docs/limitations.md).
WITH agg AS (
  SELECT COALESCE(race, 'Unknown') AS race, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
  HAVING COUNT(*) >= 100
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT race, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY n DESC;

-- 3.6 By length of stay.
WITH agg AS (
  SELECT CASE WHEN time_in_hospital <= 3 THEN '1-3 days' WHEN time_in_hospital <= 7 THEN '4-7 days' ELSE '8-14 days' END AS length_of_stay, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT length_of_stay, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY length_of_stay;

-- 3.7 By admission type (lookup is a unique-key join on the patient-level view, so no fan-out).
WITH agg AS (
  SELECT COALESCE(admission_type, 'Unmapped') AS admission_type, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM (SELECT c.*, t.description AS admission_type FROM readmission.analytic_cohort c LEFT JOIN readmission.ref_admission_type t USING (admission_type_id))
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT admission_type, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY n DESC;
