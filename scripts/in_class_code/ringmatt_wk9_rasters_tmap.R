

# setup ---------------------------------------------------------------

# libraries

library(tidyverse)
library(sf)
library(tmap)

rasters <-
  read_rds('data/processed/rasters/dc_lc.rds')

# rasters -------------------------------------------------------------

# Quick way of modifying values to binaries

temp <-
  rasters$canopy_cover >= 80

raster::plot(temp)

# Removes missing values

temp[temp == 0] <-
  NA

raster::plot(temp)

# Quesion 1 -----------------------------------------------------------

## Classifying Land

# Change all water tile values to 0 and land to 1

land <-
  rasters$nlcd != 11

# Sets all water tiles to NA, from 0

land[land == 0] <-
  NA

# Plots using the raster package

raster::plot(land)

# End of Question 1 ---------------------------------------------------

# Binarizing a raster function

raster_to_na <-
  function(raster_object, na_value = 0) {
    raster_object[raster_object == na_value] <-
      NA
    raster_object
  }

# Plots all water

raster_to_na(rasters$nlcd == 11) %>% 
  raster::plot()

# Plots all forests

{rasters$nlcd == 41} %>% 
  raster_to_na() %>% 
  raster::plot()

## Reclassifying continuous rasters

# Reclassifying canopy cover raster


# Question 2 ----------------------------------------------------------

# Classify low, medium, and high-intensity impervious surfaces
# as 0, 1, and 2 respectively

urban_intensity <-
  tribble(
    ~from, ~to, ~becomes,
    0, 10, 0,
    10, 60, 1,
    60, 100, 2) %>%
  as.matrix() %>%
  raster::reclassify(
    rasters$impervious_surface,
    .,
    include.lowest = TRUE,
    right = FALSE)

# Plot using the raster package

urban_intensity %>%
  raster::plot()

# Test to see if 0-9 is low, 10-59 is medium, and 60-100 is high

cut(
  c(9,10,59,60,100),
  breaks = c(0, 10, 60, 100),
  labels = c('low', 'medium', 'high'),
  include.lowest = TRUE,
  right = FALSE)

# End of Question 2 ---------------------------------------------------

## Raster Math

impervious_proportion <-
  rasters$impervious_surface/100

raster::plot(impervious_proportion)

impervious_proportion_no_water <-
  impervious_proportion*land

raster::plot(impervious_proportion_no_water)

## Raster to Points (ggplot for rasters)

# Convert to points

impervious_proportion_no_water %>% 
  raster::rasterToPoints() %>% 
  as_tibble() %>% 
  rename(impervious_cover = layer) %>% 
  ggplot() +
  geom_tile(aes(x = x, y = y, fill = impervious_cover)) +
  scale_fill_viridis_c(option = 'cividis') +
  coord_equal() +
  theme_void()

## Points to Raster

# Getting "crimes_prj" and "census_prj" from Week 8

dc_census_reduced <-
  st_read('data/raw/spatial/census/census.shp') %>%
  filter(state_name == "DC") %>%
  select(GEOID, edu, income, population)

crimes_sp <-
  read_csv('data/raw/dc_crimes.csv') %>%
  filter(lubridate::year(date_time) == 2020 &
           offense_group == "violent") %>%
  st_as_sf(
    .,
    coords = c('longitude', 'latitude'),
    crs = 4326)

list(dc_census_reduced,
     crimes_sp) %>%
  purrr::map(function(df) {
    df %>%
      st_as_sf() %>%
      st_transform(crs = 5070)
  }) %>% 
  set_names('census_prj', 'crimes_prj') %>%
  list2env(.GlobalEnv)

# End of extracting crmes_prj

crimes_raster <-
  crimes_prj %>%    # Need "crimes_prj" from ringmatt_wk8_memory_tmap.R
  dplyr::select(-everything()) %>% 
  st_transform(crs = st_crs(rasters)) %>%
  as_Spatial() %>% 
  raster::rasterize(
    rasters, # These are the cells that the points are rasterized to
    fun = 'count', 
    background = 0)

# Aggregates to 33 rows high and cols wide

crimes_raster %>% 
  raster::aggregate(
    fact = 33,
    fun = sum) %>% 
  raster::plot()

# Question 3 ----------------------------------------------------------

# Plot crimes per 500m^2 in dc

# Load in the dc shapefile data

dc_sp <- st_read('data/raw/spatial/rasters/dc.shp') %>%
  st_transform(
    crs = st_crs(crimes_raster))

# Plots crimes in DC as a raster of 500x500m squares

crimes_raster %>% 
  raster::aggregate(
    fact = 16,
    fun = sum) %>%
  raster::mask(dc_sp) %>%         # Mask raster to the dc shapefile
  raster::rasterToPoints() %>%    # Convert back to points
  as_tibble() %>% 
  rename(crimes = layer) %>%
  ggplot(aes(fill = crimes)) +    # Plot using ggplot
  geom_tile(aes(x = x, y = y, fill = crimes)) +
  scale_fill_viridis_c(option = 'cividis') +
  theme_void()

# End of Question 3 ---------------------------------------------------

# Load Census and Crimes 4326 from week 8

census_simple <-
  st_join(
    census_prj,
    crimes_prj) %>% 
  rmapshaper::ms_simplify(keep = 0.05)

census_simpler <-
  census_simple %>%    # Work with original data file instead of pre-trimmed
  rmapshaper::ms_simplify(keep = 0.05) %>%
  group_by(GEOID) %>% 
  summarize(n = n(),
            population = unique(population)) %>%
  mutate(crimes_per_1000 = n/population*1000)

rm(dc_crimes,
   dc_census,
   violent_crimes,
   dc_census_reduced,
   crimes_sp,
   census_simple,
   census_prj)

list2env(
  list(crimes_prj,
       census_simpler) %>%
    purrr::map(function(df) {
      df %>%
        st_transform(crs = 4326)
    }) %>%
    set_names(c("crimes_4326", "census_4326")),
  .GlobalEnv)

rm(crimes_prj,
   census_simpler)


# Question 4 ----------------------------------------------------------

# Interactive DC crime map where each offense has a layer

# Set to interactive viewing

tmap_mode('view')

# Plot each layer of offenses on top of census tracts colored by crime rate

tm_shape(census_4326) +
  tm_polygons(col = 'crimes_per_1000',
              alpha = 0.5) +
  
  # Offense Layer: Homicides
  
  tm_shape(
    name = 'homicide',
    filter(crimes_4326, 
           offense == 'homicide')) +
  tm_dots(size = 0.05,
          clustering = TRUE) +
  
  # Offense Layer: Robberies
  
  tm_shape(
    name = 'robberies',
    filter(crimes_4326, 
           offense == 'robbery')) +
  tm_dots(size = 0.05,
          clustering = TRUE) +
  
  # Offense Layer: Assault
  
  tm_shape(
    name = 'assault',
    filter(crimes_4326, 
           offense == 'assault w/dangerous weapon')) +
  tm_dots(size = 0.05,
          clustering = TRUE) +
  
  # Offense layer: Sex Abuse
  
  tm_shape(
    name = 'sex abuse',
    filter(crimes_4326, 
           offense == 'sex abuse')) +
  tm_dots(size = 0.05,
          clustering = TRUE)

