-- 05_a1c_and_medication_change.sql
-- Purpose : the question the source study was built around: how does HbA1c testing relate to
--           readmission, and does it depend on a medication change / primary diagnosis?
-- Grouping mirrors the original study's four-group design (no test, normal, >8 without change,
-- >8 with change); '>7' is shown separately so nothing is silently dropped.
-- Values in the data: a1c_result in ('None','Norm','>7','>8'); med_change in ('No','Ch').

-- 5.1 Readmission by HbA1c group.
WITH agg AS (
  SELECT CASE
    WHEN a1c_result = 'None' THEN '1. No HbA1c test'
    WHEN a1c_result = 'Norm' THEN '2. HbA1c normal'
    WHEN a1c_result = '>7'   THEN '3. HbA1c >7 (not >8)'
    WHEN a1c_result = '>8' AND med_change = 'No' THEN '4. HbA1c >8, no medication change'
    WHEN a1c_result = '>8' AND med_change = 'Ch' THEN '5. HbA1c >8, medication changed'
    ELSE '9. Other/unknown'
  END AS a1c_group, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT a1c_group, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY a1c_group;

-- 5.2 Medication change on its own.
WITH agg AS (
  SELECT med_change AS medication_change, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT medication_change, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY medication_change;

-- 5.3 Does the HbA1c pattern differ by primary diagnosis? (groups with n >= 200 only)
WITH agg AS (
  SELECT CONCAT(diag1_group, ' | ', CASE     WHEN a1c_result = 'None' THEN '1. No HbA1c test'     WHEN a1c_result = 'Norm' THEN '2. HbA1c normal'     WHEN a1c_result = '>7'   THEN '3. HbA1c >7 (not >8)'     WHEN a1c_result = '>8' AND med_change = 'No' THEN '4. HbA1c >8, no medication change'     WHEN a1c_result = '>8' AND med_change = 'Ch' THEN '5. HbA1c >8, medication changed'     ELSE '9. Other/unknown'   END) AS a1c_by_diagnosis, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
  HAVING COUNT(*) >= 200
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT a1c_by_diagnosis, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY a1c_by_diagnosis;
