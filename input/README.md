# Pipeline inputs

## treatments.csv

Table of mean-variance treatments for MVE plots.

- **site**: Name of MVE site.
- **block**: Block ID.
- **plot**: Plot ID.
- **mean_treatment**: Mean treatment for MVE plot (ambient or reduced).
- **variance_treatment**: Variance treatment for MVE plot (ambient or more variance).
- **var_treatment_YYYY**: Variance treatment for MVE plot in year YYYY (ambient, increase, or decrease). Variance treatment begins by early November of the year listed (e.g., var_treatment_2024 began Nov 2024 and extends through Oct 2025).

## stations.csv

Table of meteorological stations associated with MVE sites.

- **site**: Name of MVE site.
- **station**: ID of closest meteorological station.
