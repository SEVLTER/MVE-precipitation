# Use soil moisture data to identify/validate MVE treatment start dates

# Load packages
library(dplyr)
library(lubridate)
library(readr)
library(EDIutils)
library(ggplot2)
library(patchwork)

# Specify focal site
site <- "blue"

# Get treatment start years
start_year <- case_when(
  site == "blue" ~ 2019,
  site == "black" ~ 2020,
  site == "creosote" ~ 2021,
  site == "jsav" ~ 2022,
  site == "pj" ~ 2023,
  .default = NA
)

# Get approximate treatment start months (J. Rudgers, pers. comm.)
start_month <- case_when(
  site == "blue" ~ 9,
  site == "black" ~ 9,
  site == "creosote" ~ 10,
  site == "jsav" ~ 9,
  site == "pj" ~ 9,
  .default = NA
)

# Get identifier for soil moisture data package on EDI
identifier <- case_when(
  site == "blue" ~ 334,
  site == "black" ~ 335,
  site == "creosote" ~ 346,
  site == "jsav" ~ 347,
  site == "pj" ~ 354,
  .default = NA
)

# Identify latest data package
scope <- "knb-lter-sev"
revision <- list_data_package_revisions(scope, identifier, filter = "newest")
packageId <- paste(scope, identifier, revision, sep = ".")

# Identify focal entities in data package
entityIds <- 
  read_data_entity_names(packageId) %>%
  filter(grepl("SoilMoistureTemperature", entityName)) %>%
  pull(entityId)

# Read focal data entities
dfs <- lapply(
  entityIds,
  \(x) read_csv(
    read_data_entity(packageId, x),
    guess_max = Inf,
    progress = FALSE,
    show_col_types = FALSE
  )
)

# Combine data entities
df <- 
  dfs %>%
  bind_rows()

# Filter soil moisture data
df <- 
  df %>%
  filter(sensor == "VWC", !grepl("old", sensor_id))

# Handle outliers and nonsensical values
df <- 
  df %>%
  mutate(
    value = case_when(
      value < 0 ~ NA,
      value > 1 ~ NA,
      .default = value
    )
  )

# Construct mean-variance treatments
df <- 
  df %>%
  mutate(mean_var_trt = paste(mean_trt, "&", var_trt))

# Compute daily average soil moisture
df <- 
  df %>%
  group_by(year, month, day, depth, plot, mean_var_trt) %>%
  summarize(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
  mutate(date = as.Date(paste(year, month, day, sep = "-")), .before = 1)

# Compute coefficient of variation (CV) of soil moisture across plots
df_cv <- 
  df %>%
  group_by(date, year, month, day, depth) %>%
  summarize(
    value = sd(value, na.rm = TRUE) / mean(value, na.rm = TRUE),
    .groups = "drop"
  )

# Estimate treatment start date as the day before the largest CV within the start month
start_date <- 
  df_cv %>%
  filter(year(date) %in% start_year, month(date) %in% start_month) %>%
  group_by(depth) %>%
  slice(which.max(value)) %>%
  mutate(date = date - 1) %>%
  pull(date) %>%
  mean()

# Plot estimated start date over soil moisture
p_moisture <- 
  ggplot(df, aes(x = date, y = value)) +
  geom_vline(xintercept = start_date, linetype = 2, color = "red") +
  geom_line(aes(color = mean_var_trt, group = plot)) +
  facet_wrap(vars(depth), ncol = 1, labeller = "label_both") +
  labs(x = "Date", y = "Soil moisture", color = "Treatment") +
  theme_bw() +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(hjust = 0)
  )

# Plot estimated start date over CV of soil moisture
p_moisture_cv <- 
  ggplot(df_cv, aes(x = date, y = value)) +
  geom_vline(xintercept = start_date, linetype = 2, color = "red") +
  geom_line() +
  facet_wrap(vars(depth), ncol = 1, labeller = "label_both") +
  labs(x = "Date", y = "CV of soil moisture") +
  theme_bw() +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(hjust = 0)
  )

# Arrange plots
p_moisture + p_moisture_cv + plot_layout(guides = "collect")

# Also plot estimated start date over precipitation
p_precipitation <- 
  targets::tar_read_raw(paste0("precipitation_", site)) %>%
  filter(Year %in% start_year) %>%
  mutate(
    Date = as.Date(paste(Year, Month, Day_of_Month, sep = "-")),
    .before = 1
  ) %>%
  ggplot(aes(x = Date, y = Precipitation)) +
  geom_vline(xintercept = start_date, linetype = 2, color = "red") +
  geom_line() +
  theme_bw()

p_precipitation

# Print estimated start date
start_date
