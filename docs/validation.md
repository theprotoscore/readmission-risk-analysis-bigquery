# Reconciliation with the published study

The cohort rules (one encounter per patient, death and hospice discharges removed) follow Strack et al. (2014),
so the paper's Tables 2 and 3 are an external check on this pipeline.

| Metric | This analysis | Published |
|---|---|---|
| Final cohort | 69,973 | 69,984 |
| Share with no HbA1c test | 81.6% | 81.6% |
| Readmitted within 30 days | 6,277 (9.0%) | 6,459 (9.2%) |
| Readmission rate, untested vs tested | 9.1% vs 8.4% | 9.4% vs 8.7% |
| Circulatory / respiratory / digestive (n) | 21,384 / 9,486 / 6,487 | 21,411 / 9,490 / 6,485 |
| Diabetes / injury / genitourinary (n) | 5,748 / 4,694 / 3,440 | 5,747 / 4,697 / 3,435 |
| Discharged home (n, rate) | 44,317, 6.9% | 44,339, 7.2% |

**Reading the comparison.** Cohort size, group sizes and the HbA1c split agree with the paper to within about
0.5%. The untested-versus-tested gap (0.7 points) is the same size in both. Readmission counts here run about 3%
lower in every group, and rates 0.2 to 0.4 points lower. A plausible cause, not verified, is that the data has no
dates, so "first encounter" is approximated by the lowest `encounter_id`; for some multi-visit patients that
selects a different encounter from the one the authors used. The paper's "normal" HbA1c group corresponds to
`Norm` plus `>7` here.

Side-by-side figures: `results/reconciliation_with_published_study.csv`.
