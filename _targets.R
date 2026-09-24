# {targets} pipeline for constructing precipitation histories in MVE plots

# Load packages required to define the pipeline
library(targets)
library(tarchetypes)
library(fs)

# Set target options
tar_option_set(
  packages = c(
    "dplyr",
    "tidyr",
    "tibble",
    "lubridate",
    "readr",
    "EDIutils"
  )
)

# Source R scripts
tar_source()

# Define global objects
sites <- c("blue", "black", "creosote", "jsav", "pj")

# Prepare output directory
dir_create("output")

# Define the target list
list(
  tar_file_read(
    start_dates,
    "input/MVE-start-dates.csv",
    read_csv(!!.x, progress = FALSE, show_col_types = FALSE) %>%
      mutate(date = as_date(date, format = "%m/%d/%y"))
  ),
  tar_file_read(
    flip_dates,
    "input/MVE-flip-dates.csv",
    read_csv(!!.x, progress = FALSE, show_col_types = FALSE) %>%
      mutate(across(starts_with("flip_"), \(x) as_date(x, format = "%m/%d/%y")))
  ),
  tar_file_read(
    stations,
    "input/stations.csv",
    read_csv(!!.x, progress = FALSE, show_col_types = FALSE)
  ),
  tar_file_read(
    treatments,
    "input/treatments.csv",
    read_csv(!!.x, progress = FALSE, show_col_types = FALSE)
  ),
  tar_map(
    list(site = sites),
    tar_target(
      processed_treatments,
      process_treatments(site, treatments, start_dates, flip_dates)
    ),
    tar_target(
      precipitation,
      download_precipitation(site, stations)
    )
  )
)
