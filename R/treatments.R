#' Process MVE treatments
#'
#' @param site Site name.
#' @param treatments A data frame of MVE treatments.
#' @param start_dates A data frame of MVE treatment start dates.
#' @param flip_dates A data frame of MVE shelter flip dates.
#'
#' @returns A data frame of processed MVE treatments.
process_treatments <- function(site, treatments, start_dates, flip_dates) {
  # Process site names
  out <- 
    treatments %>%
    mutate(
      site = gsub("^meanvar_", "", site),
      site = gsub("^creo$", "creosote", site)
    )
  
  # Filter to focal site
  out <- 
    out %>%
    filter(.data$site == .env$site)
  
  # Process treatment identities
  out <- 
    out %>%
    rename(
      mean_trt = mean_treatment,
      var_trt = variance_treatment
    ) %>%
    mutate(
      mean_trt = replace_values(mean_trt, "reduced" ~ "drier"),
      var_trt = replace_values(var_trt, "more variance" ~ "more"),
      mean_var_trt = paste(mean_trt, "mean &", var_trt, "variance"),
      .after = var_trt
    )
  
  # Process treatment values
  out <- 
    out %>%
    mutate(
      mean_val = case_when(
        mean_trt == "ambient" ~ 0,
        mean_trt == "drier" ~ -25,
        .default = NA
      )
    ) %>%
    pivot_longer(
      starts_with("var_treatment_"),
      names_to = "year",
      names_prefix = "var_treatment_",
      names_transform = list(year = as.numeric),
      values_to = "var_val"
    ) %>%
    mutate(
      var_val = case_when(
        var_val == "ambient" ~ 0,
        var_val == "increase" ~ 50,
        var_val == "decrease" ~ -50,
        .default = NA
      ),
      mean_var_val = mean_val + var_val
    ) %>%
    relocate(year, .after = plot)
  
  # Convert flip dates to long format
  flip_dates_long <- 
    flip_dates %>%
    pivot_longer(
      starts_with("flip_"),
      names_to = "year",
      names_prefix = "flip_",
      names_transform = list(year = as.numeric),
      values_to = "date"
    ) %>%
    drop_na()
  
  # Bind start dates to flip dates
  flip_dates_long <- 
    start_dates %>%
    mutate(year = year(date), .before = date) %>%
    bind_rows(flip_dates_long) %>%
    arrange(site, year)
  
  # Join start/flip dates to treatments
  out <- 
    out %>%
    left_join(flip_dates_long, by = join_by(site, year)) %>%
    filter(
      year >= min(year(date), na.rm = TRUE),
      year <= max(year(date), na.rm = TRUE)
    ) %>%
    relocate(date, .after = year)
  
  # Clean up output
  out <- 
    out %>%
    arrange(site, plot, year)
  
  out
}
