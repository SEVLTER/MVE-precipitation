# MVE Precipitation

This repository contains an R pipeline for constructing a data set of plot-level treatments and precipitation histories for the mean-variance experiment at the SEV LTER. The pipeline is implemented with [`targets`](https://docs.ropensci.org/targets/) and R packages are managed with [`renv`](https://rstudio.github.io/renv/).

**Do once before running the pipeline:**

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

    i.  Create target objects (.rds) in a `_targets` directory.
    ii. Output data (.csv) and figures (.png) in an `output` directory.
