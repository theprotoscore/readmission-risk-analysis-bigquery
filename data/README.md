# Data

The raw CSV is **not** committed (it is git-ignored). Download it from the primary source:

- https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008
- Files in the zip: `diabetic_data.csv` (about 18 MB, 101,766 rows, 50 columns) and `IDS_mapping.csv`.
  The lookup values from `IDS_mapping.csv` are already built into `sql/00_setup.sql`.

Place the CSV in `data/raw/` so the path is consistent across machines.

## License and citation
CC BY 4.0. Attribution required.

> Clore, J., Cios, K., DeShazo, J., & Strack, B. (2014). Diabetes 130-US Hospitals for Years 1999-2008
> [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C5230J

The data includes age, gender and race. Results by these fields are descriptive only (see `docs/limitations.md`).
