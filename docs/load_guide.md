# Load guide (BigQuery sandbox, no billing account)

The sandbox gives 10 GB storage and 1 TB of queries per month, and **tables and views expire after 60 days**.
This project is about 18 MB, so size is not an issue; expiry is. The repo is the source of truth: re-run
`sql/00` to `sql/08` when objects expire (about 10 minutes).

## 1. Create the dataset
BigQuery Studio -> project -> Create dataset -> ID `readmission` (keep the default location).

## 2. Load the raw table (all columns as text)
Autodetect will break on `?` in numeric columns and on diagnosis codes like `V57`, so use an explicit schema.

Console:
1. Dataset `readmission` -> Create table -> Source: Upload -> select `diabetic_data.csv`, format CSV.
2. Table name: `raw_diabetic_data`.
3. Schema: turn **Auto detect OFF**, choose **Edit as text**, paste the contents of `sql/raw_schema.json`.
   If the box rejects JSON, paste the single line in `sql/raw_schema.txt` instead.
4. Advanced options -> **Header rows to skip: 1**. Create table.

The schema file renames the hyphenated columns (for example `glyburide-metformin` -> `glyburide_metformin`).
Because the schema is explicit and the header row is skipped, the names come from the schema.

CLI alternative:
```
bq load --source_format=CSV --skip_leading_rows=1 readmission.raw_diabetic_data diabetic_data.csv ./sql/raw_schema.json
```

## 3. Run the pipeline
Run the files in `sql/` in order, 00 through 08. If you get `Not found: Dataset`, qualify the dataset with your
project id (`my-project.readmission.table`) or set the default project in query settings.

## 4. Validate the load
`sql/01_profiling.sql` query 1 must return 101,766 rows. Distinct patients should be about 71,518 (reported by
a published analysis of this dataset). If not, the load is wrong: stop and fix it. Log results in
`docs/data_quality_log.md`.

## Troubleshooting
- **"Unable to parse ... column_type: BOOL value: Steady"** during upload: Auto-detect was still on, so BigQuery
  guessed types from the first rows and ignored the schema. Untick Auto detect, paste the schema, and retry. The
  table must also be named exactly `raw_diabetic_data`.
