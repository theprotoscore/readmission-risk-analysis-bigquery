# Data dictionary (columns used)

Source: UCI dataset page and Strack et al. (2014).

| Column | Meaning |
|---|---|
| encounter_id / patient_nbr | Encounter and patient identifiers. A patient can have many encounters |
| race, gender | `?` and `Unknown/Invalid` are treated as missing |
| age | 10-year band, e.g. `[70-80)`. `age_midpoint` is derived (band start + 5) |
| weight | Mostly missing (~97%); excluded from analysis |
| admission_type_id, discharge_disposition_id, admission_source_id | Codes decoded by the `ref_*` tables |
| time_in_hospital | Days between admission and discharge (1-14) |
| payer_code, medical_specialty | Payer and admitting-physician specialty; many missing |
| num_lab_procedures, num_procedures, num_medications | Counts during the encounter |
| number_outpatient / emergency / inpatient | Visits in the year before the encounter |
| diag_1..3, number_diagnoses | ICD-9 codes (stored as text) and count of diagnoses entered |
| max_glu_serum, A1Cresult | Lab results; `A1Cresult` values: `None` (not tested), `Norm`, `>7`, `>8` |
| change | Whether diabetic medications were changed (`Ch` / `No`) |
| readmitted | `<30`, `>30`, `NO`. Target is `<30` |

Derived fields (view `analytic_cohort`): `diag1_group`, `prior_inpatient_bucket`, `prior_ed_bucket`,
`medication_burden_tier`, `diagnosis_complexity_tier`, `dataset_split`, `is_readmit_30d`.
