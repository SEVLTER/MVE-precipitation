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

#' Process precipitation data according to MVE treatments
#'
#' @param precipitation A data frame of precipitation data.
#' @param processed_treatments A data frame of processed MVE treatments.
#'
#' @returns A data frame of processed precipitation data.
process_precipitation <- function(precipitation, processed_treatments) {
  # Expand precipitation data to all possible date-times
  prec <- 
    precipitation %>%
    expand(
      Site,
      StationID,
      Date_Time = seq(min(Date_Time), max(Date_Time), by = 3600)
    ) %>%
    left_join(precipitation, by = join_by(Site, StationID, Date_Time))
  
  # Reconstruct date-time columns
  prec <- 
    prec %>%
    mutate(
      Date = date(Date_Time),
      Year = year(Date_Time),
      Month = month(Date_Time),
      Day_of_Month = mday(Date_Time),
      Julian_Day = yday(Date_Time),
      Hour = hour(Date_Time)
    )
  
  # Join treatment info for each plot to precipitation data
  out <- NULL
  plots <- unique(processed_treatments$plot)
  for (i in 1:length(plots)) {
    # Get treatment info for focal plot
    trts_i <- 
      processed_treatments %>%
      filter(plot == plots[i])
    
    # Prepare daily treatment info for focal plot
    df <- NULL
    for (j in 1:nrow(trts_i)) {
      # Get treatment start date
      # Assume missing start dates to be November 1st
      start <- with(trts_i, {
        if_else(
          !is.na(date[j]),
          date[j],
          as_date(paste(year[j], 11, 1, sep = "-"))
        )
      })
      
      # Get treatment end date
      # Assume missing end dates to be October 31st
      end <- with(trts_i, {
        if_else(
          !is.na(date[j + 1]),
          date[j + 1] - 1,
          as_date(paste(year[j] + 1, 10, 31, sep = "-"))
        )
      })
      
      # Get treatment info for focal year
      trts_j <- 
        trts_i %>%
        slice(j) %>%
        select(-date)
      
      # Construct daily treatment info
      daily_trts_j <- 
        expand_grid(date = seq(start, end)) %>%
        bind_cols(trts_j)
      
      # Bind daily treatment info
      df <- 
        df %>%
        bind_rows(daily_trts_j)
    }
    
    # Join daily treatment info to hourly precipitation data
    prec_i <- 
      prec %>%
      left_join(df, by = join_by(Site == site, Date == date)) %>%
      filter(Date <= end)
    
    # Fill missing block and plot IDs
    prec_i <- 
      prec_i %>%
      mutate(
        block = replace_na(unique(na.omit(block))),
        plot = replace_na(unique(na.omit(plot)))
      )
    
    # Bind to output
    out <- 
      out %>%
      bind_rows(prec_i)
  }
  
  # Compute precipitation history
  out <- 
    out %>%
    mutate(
      Precipitation = if_else(
        !is.na(mean_var_val),
        Precipitation * (1 + (mean_var_val / 100)),
        Precipitation
      )
    )
  
  # Clean up output
  out <- 
    out %>%
    relocate(block, plot, .after = StationID) %>%
    rename(Trt_Year = year) %>%
    rename_with(\(x) gsub("_", " ", x), everything()) %>%
    rename_with(tools::toTitleCase, everything()) %>%
    rename_with(\(x) gsub(" ", "_", x), everything()) %>%
    arrange(Site, Plot, Date_Time)
  
  out
}
