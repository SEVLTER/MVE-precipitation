#' Download precipitation data from EDI
#'
#' @param site Site name.
#' @param stations A data frame of station IDs.
#'
#' @returns A data frame of precipitation data.
download_precipitation <- function(site, stations) {
  # Specify focal years
  years <- 2019:year(today())
  
  # Get focal station ID
  station <- 
    stations %>%
    filter(.data$site == .env$site) %>%
    pull(station)
  
  # Identify latest data package in EDI
  # Make sure environment variable EDI_API_KEY is set in ~/.Renviron
  # See https://github.com/ropensci/EDIutils#authentication for details
  scope <- "knb-lter-sev"
  identifier <- 1
  revision <- list_data_package_revisions(scope, identifier, filter = "newest")
  packageId <- paste(scope, identifier, revision, sep = ".")
  
  # Identify focal entities in data package
  entityIds <- 
    read_data_entity_names(packageId) %>%
    rowwise() %>%
    mutate(
      yrs = gsub("Sevilleta_LTER_Hourly_Meteorological_Data_", "", entityName),
      yrs = gsub(".csv", "", yrs),
      yrs = strsplit(yrs, "_"),
      start = yrs[1],
      end = yrs[2]
    ) %>%
    ungroup() %>%
    filter(start %in% years | end %in% years) %>%
    pull(entityId)
  
  # Read focal entities as data frames
  dfs <- lapply(
    entityIds,
    \(x) read_csv(
      read_data_entity(packageId, x),
      guess_max = Inf,
      progress = FALSE,
      show_col_types = FALSE
    )
  )
  
  # Combine focal entities into a single data frame
  out <- 
    dfs %>%
    bind_rows()
  
  # Subset precipitation data for focal station and years
  out <- 
    out %>%
    filter(StationID == station, Year %in% years) %>%
    select(StationID:Hour, Precipitation) %>%
    add_column(Site = site, .before = 1)
  
  # Ensure data are arranged chronologically
  out <- 
    out %>%
    arrange(Date_Time)
  
  out
}
