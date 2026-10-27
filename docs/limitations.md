# Limitations

- **No hospital identifier.** Hospital-to-hospital comparison is impossible. Discharge disposition describes
  where a patient went, not which hospital.
- **No dates.** Ordering uses `encounter_id`, assumed chronological (unverified). Readmission timing cannot be rebuilt.
- **Old, narrow data.** 1999-2008, diabetic inpatients only. Practice and coding have changed since.
- **Observational.** Associations, not causes. A medication change may signal an unstable patient rather than
  a cause of readmission.
- **Policy context.** The CMS Hospital Readmissions Reduction Program began on 1 October 2012 (FY 2013), after this
  data period, and initially covered acute myocardial infarction, heart failure and pneumonia. This analysis
  illustrates the readmission metric; it is not an estimate of penalty exposure.
- **Sensitive fields.** Race, gender and age are reported descriptively. Differences are not explained here.
- **Score is a heuristic.** Hand-set points, not a fitted model; no calibration; holdout is one split.
- **Missingness.** Specialty and payer are heavily missing; Unknown groups may differ systematically.
- **Index-encounter dependence.** The headline 9.0% is the rate for each patient's first-recorded encounter. Using
  the last encounter gives 4.6% and all eligible encounters 11.4% (see findings F6). Relative comparisons are
  more reliable than the absolute level.
- **Confounding.** HbA1c testing, medication change and discharge destination all reflect patient severity and
  clinical judgment, not random assignment.
- **Index-encounter dependence.** The headline 9.0% is the rate for each patient's first-recorded encounter. Using
  the last encounter gives 4.6% and all eligible encounters 11.4% (findings F6). Relative comparisons are more
  reliable than the absolute level.
- **Confounding.** HbA1c testing, medication change and discharge destination reflect patient severity and clinical
  judgment, not random assignment.
- **Approximate reproduction.** Counts reconcile with the original study to within about 0.5%, but readmission
  counts are about 3% lower (docs/validation.md), most likely because ordering by `encounter_id` only
  approximates true chronology.
