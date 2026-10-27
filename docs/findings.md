# Findings

Cohort: 69,973 patients (one index encounter each, death and hospice discharges excluded). Overall 30-day
readmission rate: **9.0%** (6,277 patients; 95% CI 8.8 to 9.2). All rates are patient-level with 95% Wilson
intervals. Tables are in `results/`.

## F1. Prior inpatient visits show the strongest gradient (sql/04, 4.1)
| Prior inpatient visits (prior year) | n | Rate | 95% CI |
|---|---|---|---|
| 0 | 61,782 | 8.1% | 7.9 to 8.3 |
| 1 | 5,794 | 12.9% | 12.1 to 13.8 |
| 2 | 1,501 | 18.5% | 16.6 to 20.6 |
| 3+ | 896 | 26.5% | 23.7 to 29.4 |

- The rate rises at every step with no overlapping intervals. Patients with 3+ prior visits are about 3.3 times as
  likely to be readmitted as patients with none.
- Patients with at least one prior visit are 11.7% of the cohort (8,191) but 20.1% of readmissions (1,262).
- Action: prioritize post-discharge follow-up for patients with prior inpatient use.
- Caveat: association only; prior visits also mark sicker patients. Query 4.7 (above age-band average) selects
  the same patients as "at least 1 prior visit" in this cohort, so it demonstrates the technique and is not a
  separate finding.

## F2. Primary diagnosis group (4.5)
| Group | n | Rate | 95% CI | vs 9.0% overall |
|---|---|---|---|---|
| Other (V/E codes) | 919 | 13.5% | 11.4 to 15.9 | above |
| Injury | 4,694 | 10.8% | 9.9 to 11.7 | above |
| Circulatory | 21,384 | 9.7% | 9.3 to 10.1 | above |
| Diabetes | 5,748 | 9.1% | 8.4 to 9.9 | no clear difference |
| Neoplasms | 2,538 | 9.1% | 8.0 to 10.2 | no clear difference |
| Genitourinary | 3,440 | 9.0% | 8.1 to 10.0 | no clear difference |
| Other | 11,203 | 8.6% | 8.1 to 9.1 | no clear difference |
| Musculoskeletal | 4,064 | 8.4% | 7.6 to 9.3 | no clear difference |
| Digestive | 6,487 | 8.0% | 7.4 to 8.7 | below |
| Respiratory | 9,486 | 7.3% | 6.8 to 7.8 | below |

- "Above" and "below" mean the whole interval lies on that side of the overall rate.
- Circulatory is the largest block: 30.6% of patients and 32.9% of readmissions (2,067 of 6,277).
- Caveat: V/E codes describe supplementary circumstances, not diseases. Ten patients without a diagnosis code are
  outside the table (groups under 100 are hidden).

## F3. HbA1c testing and medication change (05)
| Group | n | Rate | 95% CI |
|---|---|---|---|
| No HbA1c test | 57,128 | 9.1% | 8.9 to 9.3 |
| HbA1c normal | 3,741 | 8.6% | 7.8 to 9.6 |
| HbA1c >7 (not >8) | 2,865 | 8.6% | 7.6 to 9.7 |
| HbA1c >8, no medication change | 2,181 | 7.4% | 6.4 to 8.6 |
| HbA1c >8, medication changed | 4,058 | 8.6% | 7.8 to 9.5 |

- 81.6% of patients had no HbA1c test, the same share as the original study. Tested patients had a rate of 8.4%
  (1,078 of 12,845) versus 9.1% untested; the original study reported 8.7% versus 9.4%, a gap of the same size.
- The "no change" versus "changed" difference at HbA1c above 8 (7.4% vs 8.6%) is not clearly real: the intervals
  overlap.
- Within circulatory patients the same two groups are 9.4% and 11.3% with overlapping intervals (query 5.3), so
  the pattern is not consistent across diagnoses.
- Caveat: who gets tested is not random, so this is an association, not evidence that testing lowers readmission.
  The original study found the relationship depends on primary diagnosis; this analysis does not model that.

## F4. Discharge destination (6.1)
| Destination | n | Rate | 95% CI |
|---|---|---|---|
| Rehab facility | 1,410 | 26.3% | 24.1 to 28.7 |
| Another inpatient care institution | 913 | 20.6% | 18.1 to 23.3 |
| Another short-term hospital | 1,539 | 13.8% | 12.1 to 15.6 |
| Skilled nursing facility | 8,784 | 13.4% | 12.7 to 14.1 |
| Intermediate care facility | 541 | 10.4% | 8.1 to 13.2 |
| Home with home health | 8,289 | 9.5% | 8.9 to 10.2 |
| Left against medical advice | 409 | 9.5% | 7.1 to 12.8 |
| Discharged to home | 44,317 | 6.9% | 6.7 to 7.2 |
| Long-term care hospital | 260 | 3.1% | 1.6 to 6.0 |

(Missing and unmapped destinations, 3,252 patients, are in `results/06_discharge_disposition.csv`.)
- Rehab discharges were readmitted at about 3.8 times the rate of discharges home.
- Volume versus rate: skilled-nursing patients are 12.6% of the cohort but 18.7% of readmissions (1,176). Patients
  discharged home have the lowest common rate yet account for 49% of readmissions (3,078 of 6,277).
- Caveat: destination reflects illness severity, so this is not evidence that facilities cause readmission.
  Destination is a type of facility, not a specific hospital.

## F5. Risk score, validated on a holdout (07; validation split, n = 21,063)
Points: prior inpatient visits (0 to 3), any prior ED visit, 9 or more diagnoses, more than 20 medications, not
discharged home.

| Score | n | Rate |
|---|---|---|
| 0 | 6,174 | 5.2% |
| 1 | 7,019 | 8.5% |
| 2 | 5,030 | 11.1% |
| 3 | 2,077 | 13.5% |
| 4 | 531 | 17.9% |
| 5 | 171 | 24.0% |
| 6+ | 61 | 27.9% |

| Flag patients scoring | Share of patients | Share of readmissions | Lift |
|---|---|---|---|
| 4+ | 3.6% | 8.0% | 2.21 |
| 3+ | 13.5% | 22.6% | 1.68 |
| 2+ | 37.4% | 51.7% | 1.38 |

- The rate rises at every score step on the holdout and closely matches the training split (5.6% at score 0 to
  28.8% at score 6), so the score is stable.
- Practical value is modest: flagging the top 13.5% of patients finds 22.6% of readmissions.
- Caveat: hand-set points, not a fitted model, so there is no AUC or calibration; exploration ran on all data
  (decision D9), so the holdout is a consistency check, not an untouched test.

## F6. Sensitivity to the index-encounter choice (08)
| Definition | n | Overall rate | 0 prior inpatient | 3+ prior inpatient |
|---|---|---|---|---|
| A. Lowest encounter_id per patient (primary) | 69,973 | 9.0% | 8.1% | 26.5% |
| B. Highest encounter_id per patient | 69,169 | 4.6% | 3.4% | 14.4% |
| C. All eligible encounters | 99,343 | 11.4% | 8.6% | 26.4% |

- The overall rate roughly halves when each patient's last encounter is used. A plausible explanation, not
  verified: an encounter followed by a readmission in the extract cannot be a patient's last one, so last
  encounters are less likely to carry a `<30` label.
- The relationship with prior visits holds under all three definitions: 3+ visits carry 3.1 to 4.2 times the rate
  of 0 visits. Relative patterns are therefore more reliable than the absolute 9.0%.

## F7. Admitting specialty (6.3)
25 specialties have at least 100 patients (68,984 patients; 989 patients in smaller specialties are not shown).
Full table: `results/06_specialty_ranked.csv`.
- Clearly above the 9.0% overall rate: Hematology/Oncology 20.2% (22 of 109; CI 13.7 to 28.7), Oncology 18.0%
  (37 of 205; CI 13.4 to 23.9) and Internal Medicine 9.8% (1,039 of 10,641; CI 9.2 to 10.3). The oncology groups
  are small; Internal Medicine is the largest named specialty and accounts for 16.6% of all readmissions.
- Clearly below: Cardiology 7.2% (6.4 to 8.0), Emergency/Trauma 7.8% (7.1 to 8.7), Orthopedics-Reconstructive
  6.6% (5.3 to 8.3), Surgery-Cardiovascular/Thoracic 5.9% (4.2 to 8.4), Surgery-Neuro 5.2% (3.4 to 7.8),
  Obstetrics and Gynecology 3.7% (2.5 to 5.6), Otolaryngology 1.8% (0.5 to 6.4) and Pediatrics-Endocrinology
  0.0% (0 of 147; 0.0 to 2.5).
- 48.1% of the cohort has no recorded specialty (`Unknown`, 9.2%), so specialty comparisons cover about half the
  patients. Admitting specialty and primary diagnosis capture different things: cardiology admissions run below
  average even though circulatory diagnoses run above it.
