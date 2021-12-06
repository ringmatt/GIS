
# setup -------------------------------------------------------------------

library(sf)
library(tmap)
library(tmaptools)
library(tidyverse)
library(leaflet)

# data --------------------------------------------------------------------

# Read in Census et al. data

df_counties <- 
  read_csv("data/master_dataset_clean.csv") %>%
  select(!...1) %>%
  rename(State = state,
         County = name) %>%
  
  # Creates a new column summing Rust and Recovery Scores
  
  mutate(`Rust Score` = rowMeans(
    select(., c(pop_change, poverty_decrease,
           manufacturing_percent_change)),
    na.rm = TRUE),
    `Recovery Score` = rowMeans(
      select(., c(pop_change, income_change,
             home_val_change, housing_construction_increase)),
      na.rm = TRUE))  %>%
  
  select(GEOID, State, County, `Rust Score`, `Recovery Score`)

df_counties %>%
  pull(`Rust Score`) %>%
  summary

# Read in shapefiles:

counties_shp <-
  st_read('data/us_counties.shp') %>%
  
  # Merge in state fips information
  
  left_join(
    read_csv("data/state_fips.csv"),
    on = "STATEFP") %>%
  select(c(GEOID, State, geometry)) %>%
  filter(State %in% 
           unique(df_counties$State)) %>%
  select(-c(State)) %>%
  mutate(GEOID = as.integer(GEOID)) %>%
  st_transform(crs = 4326)

# Static Rust Map -----------------------------------------------------

# Sets TMap's mode to view only

tmap_mode(c("plot", "view"))

tmap_rust <-
  counties_shp %>%
  
  left_join(
    df_counties,
    by = "GEOID") %>%
  
  # Initailize TMap
  
  tm_shape(.) +
  
  # Add colored polygons to the map
  
  tm_polygons(col = "Rust Score",
              alpha = 0.75,
              border.alpha = 0.05,
              palette = "-Oranges",
              colorNA = "Red",
              style = "cont",
              id = "County",
              popup.vars = c("County", "State", 
                             "Rust  Score"),
              popup.format = list(digits = 2)) +
  
  # Fit the initial zoom to the states we selected
  
  tm_view(bbox =
            st_bbox(counties_shp))

tmap_save(tmap_rust, filename="figures/tmap_rust.png")

# Static Recovery Map -------------------------------------------------

tmap_recovery <-
  counties_shp %>%
  left_join(
    df_counties,
    by = "GEOID") %>%
  
  # Initialize TMap
  
  tm_shape(.) +
  
  # Add colored polygons to the map
  
  tm_polygons(col = "Recovery Score",
              alpha = 0.75,
              border.alpha = 0.05,
              palette = "BrBG",
              colorNA = "Blue",
              style = "cont",
              id = "County",
              popup.vars = c("County", "State", 
                             "Recovery  Score"),
              popup.format = list(digits = 2)) +
  
  # Fit the initial zoom to the states we selected
  
  tm_view(bbox =
            st_bbox(counties_shp))

tmap_save(tmap_recovery, filename="figures/tmap_recovery.png")
