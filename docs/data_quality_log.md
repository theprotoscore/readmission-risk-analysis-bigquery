# Data quality log

Checks run on 2026-10-26 (`sql/01_profiling.sql`, `sql/02_staging_and_cohort.sql`).

| # | Check | Result | Action |
|---|---|---|---|
| 1 | Raw row count | 101,766 rows, 101,766 distinct encounter IDs (matches source) | None |
| 2 | Distinct patients | 71,518 (matches published figure) | None |
| 3 | Target split, all encounters | NO 54,864 (53.9%); >30 35,545 (34.9%); <30 11,357 (11.2%) | None; patient-level rate is 9.0% |
| 4 | Diagnosis codes loaded as text | 1,644 V-codes and 1 E-code in `diag_1` | None |
| 5 | Missing values coded `?` | The source paper reports weight 97%, payer code 40%, medical specialty 47% missing. Specialty is missing for 48.1% of the final cohort (33,639 of 69,973) | Weight excluded; specialty kept as `Unknown`; payer code not used |
| 6 | Cohort flow | 101,766 -> 71,518 index encounters -> 69,973 after removing 1,545 death/hospice discharges | None |
| 7 | Group totals equal cohort size | Tables 3.1, 4.1 and 5.1 each sum to 69,973. Table 4.5 sums to 69,963 (10 patients without a diagnosis code fall below the n >= 100 rule) | Noted in findings |
| 8 | Load error on first attempt | 56 parse errors: schema auto-detect typed medication columns as BOOL | Reloaded with an explicit all-STRING schema |
