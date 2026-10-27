-- 01_profiling.sql
-- Purpose : verify the load and quantify data quality before any cleaning (results in docs/data_quality_log.md).

-- 1. Row counts. The source documents 101,766 encounters; 71,518 distinct patients is reported by a
--    published analysis of this dataset.
SELECT
  COUNT(*)                      AS row_count,
  COUNT(DISTINCT encounter_id)  AS distinct_encounters,
  COUNT(DISTINCT patient_nbr)   AS distinct_patients
FROM readmission.raw_diabetic_data;

-- 2. Target distribution at encounter level (all rows, before any filtering).
SELECT readmitted, COUNT(*) AS n,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM readmission.raw_diabetic_data
GROUP BY readmitted
ORDER BY n DESC;

-- 3. Missing values coded as '?' (the source does not use real NULLs).
SELECT
  ROUND(100 * COUNTIF(race = '?') / COUNT(*), 1)              AS pct_race,
  ROUND(100 * COUNTIF(weight = '?') / COUNT(*), 1)            AS pct_weight,
  ROUND(100 * COUNTIF(payer_code = '?') / COUNT(*), 1)        AS pct_payer_code,
  ROUND(100 * COUNTIF(medical_specialty = '?') / COUNT(*), 1) AS pct_medical_specialty,
  ROUND(100 * COUNTIF(diag_1 = '?') / COUNT(*), 1)            AS pct_diag_1,
  ROUND(100 * COUNTIF(diag_2 = '?') / COUNT(*), 1)            AS pct_diag_2,
  ROUND(100 * COUNTIF(diag_3 = '?') / COUNT(*), 1)            AS pct_diag_3
FROM readmission.raw_diabetic_data;

-- 4. Invalid category values.
SELECT gender, COUNT(*) AS n FROM readmission.raw_diabetic_data GROUP BY gender ORDER BY n DESC;

-- 5. Diagnosis codes must survive the load as text: V/E-prefixed ICD-9 codes should be present.
SELECT
  COUNTIF(STARTS_WITH(diag_1, 'V')) AS diag1_v_codes,
  COUNTIF(STARTS_WITH(diag_1, 'E')) AS diag1_e_codes
FROM readmission.raw_diabetic_data;

-- 6. Repeat patients: why one-row-per-patient matters (see assumptions D2).
SELECT encounters_per_patient, COUNT(*) AS patients
FROM (
  SELECT patient_nbr, COUNT(*) AS encounters_per_patient
  FROM readmission.raw_diabetic_data
  GROUP BY patient_nbr
)
GROUP BY encounters_per_patient
ORDER BY encounters_per_patient;

-- 7. Discharge dispositions, with the death/hospice flag from the lookup table.
SELECT discharge_disposition_id, d.description, d.is_death_or_hospice, COUNT(*) AS n
FROM (SELECT SAFE_CAST(discharge_disposition_id AS INT64) AS discharge_disposition_id
      FROM readmission.raw_diabetic_data) r
LEFT JOIN readmission.ref_discharge_disposition d USING (discharge_disposition_id)
GROUP BY 1, 2, 3
ORDER BY n DESC;
