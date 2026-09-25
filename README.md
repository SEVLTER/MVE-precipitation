# MVE Precipitation

This repository contains an R pipeline for constructing a data set of plot-level treatments and precipitation histories for the mean-variance experiment (MVE) at the SEV LTER. The pipeline is implemented with [`targets`](https://docs.ropensci.org/targets/) and R packages are managed with [`renv`](https://rstudio.github.io/renv/).

## Pipeline

**Once before running the pipeline:**

Obtain an API key for [EDI](https://edirepository.org/) via the [EDI IAM portal](https://auth.edirepository.org/auth/ui/signin) and add it to `~/.Renviron` in the form `EDI_API_KEY=key` (where `key` is your API key). See [here](https://github.com/ropensci/EDIutils#authentication) for details. The `.Renviron` file can be conveniently created or opened with:

``` r
usethis::edit_r_environ()
```

**To run the pipeline:**

1.  Clone (download) this repository to your machine.

2.  Start a new R session at the root of this repository. RStudio users can conveniently do this by opening the RStudio project `MVE-precipitation.Rproj`.

3.  Restore the R project library as recorded in `renv.lock`:

    ``` r
    renv::restore()
    ```

4.  Run the pipeline as defined in `_targets.R`:

    ``` r
    targets::tar_make()
    ```

    This will:

    1.  Create target objects (.rds) in a `_targets` directory.
    2.  Create figures (.png) in a `figures` directory.
    3.  Output processed data (.csv) in an `output` directory.

## Outputs

The primary outputs of the pipeline are precipitation histories for MVE plots reconstructed according to yearly MVE treatments. Precipitation data are derived from the (now-retired) [Meteorology Data from the Sevilleta National Wildlife Refuge, New Mexico](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-sev&identifier=1) (Moore & Winter 2026). Note that missing precipitation values are omitted in the source data but are explicitly filled in as NAs here. Treatment info for each MVE site is also provided as output.

## References

Moore, D.I. and A.S. Winter. 2026. Retired Meteorology Data from the Sevilleta National Wildlife Refuge, New Mexico ver 20. Environmental Data Initiative. <https://doi.org/10.6073/pasta/8fde845dbda008312b5b43ff01377a1f> (Accessed 2026-09-25).
