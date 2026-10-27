-- 08_sensitivity_checks.sql
-- Purpose : do the headline numbers survive different, defensible cohort definitions?
-- If the overall rate or the prior-inpatient pattern moves a lot, say so in docs/limitations.md.

WITH defs AS (
  SELECT 'A. Primary: lowest encounter_id per patient' AS definition, is_readmit_30d, number_inpatient
  FROM readmission.cohort
  UNION ALL
  SELECT 'B. Alternative index: highest encounter_id per patient', is_readmit_30d, number_inpatient
  FROM (
    SELECT s.*, ROW_NUMBER() OVER (PARTITION BY s.patient_nbr ORDER BY s.encounter_id DESC) AS rn
    FROM readmission.stg_encounters s
  ) x
  LEFT JOIN readmission.ref_discharge_disposition d USING (discharge_disposition_id)
  WHERE x.rn = 1 AND NOT COALESCE(d.is_death_or_hospice, FALSE)
  UNION ALL
  SELECT 'C. All eligible encounters (not one per patient)', is_readmit_30d, number_inpatient
  FROM readmission.cohort_all_eligible
)
SELECT definition,
  COUNT(*) AS n,
  ROUND(100 * AVG(CAST(is_readmit_30d AS INT64)), 1) AS overall_rate_pct,
  ROUND(100 * AVG(IF(COALESCE(number_inpatient, 0) = 0, CAST(is_readmit_30d AS INT64), NULL)), 1) AS rate_pct_0_prior_inpatient,
  ROUND(100 * AVG(IF(COALESCE(number_inpatient, 0) >= 3, CAST(is_readmit_30d AS INT64), NULL)), 1) AS rate_pct_3plus_prior_inpatient
FROM defs
GROUP BY definition
ORDER BY definition;
