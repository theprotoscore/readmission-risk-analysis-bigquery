# Assumptions and decisions

Each decision states the choice, the reason, and how it was checked.

**D1. Missing values.** `?` becomes NULL in staging. `Unknown/Invalid` gender becomes NULL.

**D2. One row per patient.** Repeat patients would otherwise get extra weight. The index encounter is the
lowest `encounter_id`. The data has no dates, so "first" is an assumption. `sql/08` tested the opposite choice: the overall rate fell from 9.0% to 4.6%, so the absolute rate depends on this choice (the prior-visit gradient does not). Death/hospice exclusions concentrating at highest encounter_ids (2,349 vs 1,545) are consistent with IDs being roughly chronological.

**D3. Weight excluded.** About 97% missing; no finding should rest on it. The column is not dropped from the raw table.

**D4. Death/hospice exclusion.** Discharge codes 11, 13, 14, 19, 20, 21 (expired, hospice). Those patients
cannot be readmitted, so keeping them dilutes the rate. Code 26 (Unknown/Invalid) is not excluded because it does not indicate death or hospice.

**D5. Metric.** 30-day readmission = `readmitted = '<30'`. Rates are patient-level in the final cohort.
Encounter-level rates (all 101,766 rows) are higher and are not comparable.

**D6. Minimum group size.** Rankings use n >= 100 (n >= 200 for the A1C-by-diagnosis cross-tab).
Every rate has a 95% Wilson interval.

**D7. Diagnosis grouping.** ICD-9 ranges follow Table 2 of Strack et al. (2014); V/E codes are kept as their own group.

**D8. Tier thresholds.** Medication burden (<=10 / 11-20 / >20) and diagnosis complexity (<=5 / 6-8 / >=9)
are judgment calls, not clinical standards.

**D9. Risk score.** Points: prior inpatient visits (capped at 3), any prior ED visit, 9 or more diagnoses,
more than 20 medications, not discharged to home. Validated on a 30% holdout split by patient. Exploratory queries (04, 06) ran on ALL patients, so point choices were informed by the full cohort; treat the holdout as a consistency check, not an untouched test.

**D10. Cohort order.** Index encounter first, then the death/hospice exclusion. The alternative order differs
only in rare cases (first encounter ended in hospice but later encounters exist).
