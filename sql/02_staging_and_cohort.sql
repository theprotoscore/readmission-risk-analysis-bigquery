-- 02_staging_and_cohort.sql
-- Purpose : typed/cleaned staging view, cohort definition, and the derived analysis view.
-- Layers  : raw_diabetic_data (all STRING, untouched)
--           -> stg_encounters (typed, '?' -> NULL)
--           -> cohort (one index encounter per patient, death/hospice excluded)
--           -> analytic_cohort (derived groupings used by every analysis)
-- All objects are VIEWS so the pipeline re-runs top-to-bottom with no destructive steps.

-- ---- Layer 1: staging --------------------------------------------------------------------
-- `weight` is intentionally NOT selected: it is ~97% missing (see 01_profiling.sql).
CREATE OR REPLACE VIEW readmission.stg_encounters AS
SELECT
  SAFE_CAST(encounter_id AS INT64)               AS encounter_id,
  SAFE_CAST(patient_nbr AS INT64)                AS patient_nbr,
  NULLIF(race, '?')                              AS race,
  NULLIF(NULLIF(gender, '?'), 'Unknown/Invalid') AS gender,
  age                                            AS age_band,
  SAFE_CAST(REGEXP_EXTRACT(age, r'\[(\d+)-') AS INT64) + 5 AS age_midpoint,
  SAFE_CAST(admission_type_id AS INT64)          AS admission_type_id,
  SAFE_CAST(discharge_disposition_id AS INT64)   AS discharge_disposition_id,
  SAFE_CAST(admission_source_id AS INT64)        AS admission_source_id,
  SAFE_CAST(time_in_hospital AS INT64)           AS time_in_hospital,
  NULLIF(payer_code, '?')                        AS payer_code,
  NULLIF(medical_specialty, '?')                 AS medical_specialty,
  SAFE_CAST(num_lab_procedures AS INT64)         AS num_lab_procedures,
  SAFE_CAST(num_procedures AS INT64)             AS num_procedures,
  SAFE_CAST(num_medications AS INT64)            AS num_medications,
  SAFE_CAST(number_outpatient AS INT64)          AS number_outpatient,
  SAFE_CAST(number_emergency AS INT64)           AS number_emergency,
  SAFE_CAST(number_inpatient AS INT64)           AS number_inpatient,
  NULLIF(diag_1, '?')                            AS diag_1,
  NULLIF(diag_2, '?')                            AS diag_2,
  NULLIF(diag_3, '?')                            AS diag_3,
  SAFE_CAST(number_diagnoses AS INT64)           AS number_diagnoses,
  max_glu_serum,
  A1Cresult                                      AS a1c_result,
  change                                         AS med_change,
  diabetesMed                                    AS diabetes_med,
  readmitted,
  readmitted = '<30'                             AS is_readmit_30d
FROM readmission.raw_diabetic_data;

-- ---- Layer 2: cohort ---------------------------------------------------------------------
-- Step A: one index encounter per patient (lowest encounter_id; the data has no dates, so
--         this is an assumption, tested in 08_sensitivity_checks.sql).
CREATE OR REPLACE VIEW readmission.cohort_index_encounters AS
SELECT * EXCEPT (rn)
FROM (
  SELECT s.*, ROW_NUMBER() OVER (PARTITION BY s.patient_nbr ORDER BY s.encounter_id) AS rn
  FROM readmission.stg_encounters s
)
WHERE rn = 1;

-- Step B: drop discharges after which a readmission cannot occur (died / hospice).
CREATE OR REPLACE VIEW readmission.cohort AS
SELECT i.*
FROM readmission.cohort_index_encounters i
LEFT JOIN readmission.ref_discharge_disposition d USING (discharge_disposition_id)
WHERE NOT COALESCE(d.is_death_or_hospice, FALSE);

-- Sensitivity cohort: every eligible encounter (no one-per-patient rule). Used in 08 only.
CREATE OR REPLACE VIEW readmission.cohort_all_eligible AS
SELECT s.*
FROM readmission.stg_encounters s
LEFT JOIN readmission.ref_discharge_disposition d USING (discharge_disposition_id)
WHERE NOT COALESCE(d.is_death_or_hospice, FALSE);

-- ---- Layer 3: analytic view --------------------------------------------------------------
-- Diagnosis grouping follows Table 2 of Strack et al. (2014): circulatory 390-459/785, respiratory 460-519/786,
-- digestive 520-579/787, genitourinary 580-629/788, diabetes 250.xx, injury 800-999, musculoskeletal 710-739,
-- neoplasms 140-239. V/E codes are kept as their own group.
CREATE OR REPLACE VIEW readmission.analytic_cohort AS
WITH base AS (
  SELECT c.*, SAFE_CAST(SPLIT(c.diag_1, '.')[SAFE_OFFSET(0)] AS INT64) AS diag1_num
  FROM readmission.cohort c
)
SELECT
  b.* EXCEPT (diag1_num),
  CASE
    WHEN diag_1 IS NULL THEN 'Missing'
    WHEN STARTS_WITH(diag_1, '250') THEN 'Diabetes'
    WHEN STARTS_WITH(diag_1, 'V') OR STARTS_WITH(diag_1, 'E') THEN 'Other (V/E codes)'
    WHEN diag1_num BETWEEN 390 AND 459 OR diag1_num = 785 THEN 'Circulatory'
    WHEN diag1_num BETWEEN 460 AND 519 OR diag1_num = 786 THEN 'Respiratory'
    WHEN diag1_num BETWEEN 520 AND 579 OR diag1_num = 787 THEN 'Digestive'
    WHEN diag1_num BETWEEN 580 AND 629 OR diag1_num = 788 THEN 'Genitourinary'
    WHEN diag1_num BETWEEN 800 AND 999 THEN 'Injury'
    WHEN diag1_num BETWEEN 710 AND 739 THEN 'Musculoskeletal'
    WHEN diag1_num BETWEEN 140 AND 239 THEN 'Neoplasms'
    ELSE 'Other'
  END AS diag1_group,
  CASE
    WHEN number_inpatient IS NULL THEN NULL
    WHEN number_inpatient = 0 THEN '0'
    WHEN number_inpatient = 1 THEN '1'
    WHEN number_inpatient = 2 THEN '2'
    ELSE '3+'
  END AS prior_inpatient_bucket,
  CASE
    WHEN number_emergency IS NULL THEN NULL
    WHEN number_emergency = 0 THEN '0'
    WHEN number_emergency = 1 THEN '1'
    ELSE '2+'
  END AS prior_ed_bucket,
  CASE
    WHEN num_medications IS NULL THEN NULL
    WHEN num_medications <= 10 THEN 'Low (<=10)'
    WHEN num_medications <= 20 THEN 'Medium (11-20)'
    ELSE 'High (>20)'
  END AS medication_burden_tier,
  CASE
    WHEN number_diagnoses IS NULL THEN NULL
    WHEN number_diagnoses <= 5 THEN 'Low (<=5)'
    WHEN number_diagnoses <= 8 THEN 'Moderate (6-8)'
    ELSE 'High (>=9)'
  END AS diagnosis_complexity_tier,
  -- Deterministic patient-level split used only for risk-score validation (07).
  IF(MOD(ABS(FARM_FINGERPRINT(CAST(patient_nbr AS STRING))), 10) < 7, 'train', 'validation') AS dataset_split
FROM base b;

-- ---- Cohort flow ------------------------------------------
SELECT 1 AS step_order, 'Raw encounters' AS step, COUNT(*) AS n FROM readmission.stg_encounters
UNION ALL SELECT 2, 'One index encounter per patient', COUNT(*) FROM readmission.cohort_index_encounters
UNION ALL SELECT 3, 'After excluding death/hospice discharges (final cohort)', COUNT(*) FROM readmission.cohort
ORDER BY step_order;
