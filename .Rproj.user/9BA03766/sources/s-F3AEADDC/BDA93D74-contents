# Imports necessary packages
library(tidyverse)

# Loads weather data
df <- read.csv("data/raw/messy_weather.csv")

# Selects station level data
stations <- df %>%
  select(station:name) %>%
  distinct()

stations

# Selects weather level data
observations_raw <- df %>%
  select(station, year:march_31) %>%
  pivot_longer(contains("march"),
               names_to = "day",
               names_prefix = "march_",
               values_to = "values") %>%
  unite("date",
        c(year, month, day),
        sep = "-") %>%
  pivot_wider(names_from = variable,
              values_from = values) %>%
  separate(temperature_min_max, into = c("min_temp", "max_temp"), sep = ":") %>%
  mutate_at(vars(precip:max_temp),
            ~as.numeric(.)) %>%
  mutate(date = lubridate::as_date(date))

observations_raw

## My work is below, group coding is above

# Normalizes the data following Codd's rules
#df <- df %>%
  # Converts separate columns for each day into separate rows
  # Moves values from these columns into a new "values" variable
#  pivot_longer(contains("march"),
#               names_to = "day",
#               names_prefix = "march_",
#               values_to = "values") %>%
  # Condenses the separate rows for precipitation, snow, and temperature
  # into a single row, now showing all measures per location & day 
#  pivot_wider(c(station, longitude, latitude, elevation, state, name, year, month, day),
#              names_from = variable,
#              values_from = values) %>%
  # Fixes a violation of Codd's 1st normal rule, where the values of 
  # temperature_min_max are not atomic
#  separate(temperature_min_max, into = c("min_temp", "max_temp"), sep = ":")

# Displays the tidy'd data
df