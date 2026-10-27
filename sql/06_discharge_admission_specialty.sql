-- 06_discharge_admission_specialty.sql
-- Purpose : where patients go after discharge, how they arrive, and which admitting specialties
--           show higher readmission. There is NO hospital identifier in this dataset, so
--           hospital-level comparisons are not possible (see docs/limitations.md).
-- Minimum group size n >= 100 everywhere a ranking is shown.

-- 6.1 Discharge disposition (lookup id included so labels are unambiguous).
WITH agg AS (
  SELECT discharge_disposition_id, COALESCE(description, 'Unmapped') AS discharge_disposition,
         COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM (
    SELECT c.*, d.description
    FROM readmission.analytic_cohort c
    LEFT JOIN readmission.ref_discharge_disposition d USING (discharge_disposition_id)
  )
  GROUP BY 1, 2
  HAVING COUNT(*) >= 100
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT discharge_disposition_id, discharge_disposition, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY rate_pct DESC;

-- 6.2 Admission source.
WITH agg AS (
  SELECT COALESCE(description, 'Unmapped') AS admission_source, COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM (SELECT c.*, s.description FROM readmission.analytic_cohort c LEFT JOIN readmission.ref_admission_source s USING (admission_source_id))
  GROUP BY 1
  HAVING COUNT(*) >= 100
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT admission_source, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct
FROM calc
ORDER BY rate_pct DESC;

-- 6.3 Admitting specialty, ranked, with percentile among eligible specialties.
WITH agg AS (
  SELECT COALESCE(medical_specialty, 'Unknown') AS specialty,
         COUNT(*) AS n, COUNTIF(is_readmit_30d) AS readmits
  FROM readmission.analytic_cohort
  GROUP BY 1
  HAVING COUNT(*) >= 100
),
calc AS (SELECT *, SAFE_DIVIDE(readmits, n) AS p, 1.96 AS z FROM agg)
SELECT specialty, n, readmits,
  ROUND(100 * p, 1) AS rate_pct,
  ROUND(100 * (p + z*z/(2*n) - z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_low_pct,
  ROUND(100 * (p + z*z/(2*n) + z*SQRT(p*(1-p)/n + z*z/(4*n*n))) / (1 + z*z/n), 1) AS ci_high_pct,
  RANK() OVER (ORDER BY p DESC) AS rate_rank,
  ROUND(100 * PERCENT_RANK() OVER (ORDER BY p), 0) AS percentile
FROM calc
ORDER BY rate_rank;
