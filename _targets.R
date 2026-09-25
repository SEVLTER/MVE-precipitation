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
    "EDIutils",
    "ggplot2"
  )
)

# Source R scripts
tar_source()

# Define global objects
sites <- c("blue", "black", "creosote", "jsav", "pj")

# Prepare output directories
dir_create("figures")
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
    ),
    tar_target(
      processed_precipitation,
      process_precipitation(precipitation, processed_treatments)
    ),
    tar_file(
      figure_precipitation,
      plot_precipitation(
        processed_precipitation,
        paste0("figures/MVE-precipitation-", site, ".png"),
        width = 12,
        height = 8
      )
    ),
    tar_file(
      output_treatments,
      write_csv_file(
        processed_treatments,
        paste0("output/MVE-treatments-", site, ".csv")
      )
    ),
    tar_file(
      output_precipitation,
      write_csv_file(
        processed_precipitation,
        paste0("output/MVE-precipitation-", site, ".csv")
      )
    )
  )
)
