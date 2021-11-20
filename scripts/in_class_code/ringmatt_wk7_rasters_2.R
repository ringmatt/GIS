# setup -------------------------------------------------------------------

library(sf)
library(sp)
library(tidyverse)

#source('scripts/source_script.R')

# read in the data --------------------------------------------------------

rasters <-
  read_rds('data/processed/rasters/dc_lc.rds')

dc <-
  st_read('data/raw/spatial/rasters/dc.shp')

dc_sp <-
  dc %>%
  st_transform(
    crs = st_crs(rasters))

survey <-
  st_read('data/raw/spatial/rasters/survey_points.shp') %>%
  st_transform(
    crs = st_crs(rasters))


# intro map -----------------------------------------------------------

survey %>%
  mutate(
    edu_attain = 
      factor(
        edu_attain,
        levels = 
          c('No diploma',
            'High school',
            'Associates',
            'Bachelors',
            'Masters',
            'PhD'))) %>%
  ggplot() +
  geom_sf(data = dc_sp) +
  geom_sf(aes(size = income, color = factor(edu_attain))) +
  scale_color_brewer(palette = "Reds") +
  theme_void() +
  labs(title = "Educational Attainment and Income in DC",
       color = "Education",
       size = "Income")


# some stats ----------------------------------------------------------

raster::cellStats(
  rasters$impervious_surface,
  stat = 'mean')

# Dr. Evans' favorite method, extracts whole vector at once then averages

raster::values(rasters$impervious_surface) %>%
  mean(na.rm = T)

# reclassify --------------------------------------------------------------

# Overview of the data

rasters$nlcd

# Plots the basic raster file

plot(rasters$nlcd)

# Creates a matrix converting land cover to zero or one 
# by whether something is a forest

reclass_matrix <- 
  tibble(
    from = 
      rasters$nlcd %>%
      raster::values() %>%
      unique() %>%
      sort()) %>%
    mutate(
      to = 
        if_else(from %in% 41:43, 1, 0)) %>%
    as.matrix()

# Converts the land cover values

rasters$forest <-
  raster::reclassify(
    rasters$nlcd,
    reclass_matrix)

# Displays the new land cover data

raster::plot(rasters$forest)

# Tests to ensure all values are 1, 0, or NA

raster::values(rasters$forest) %>%
  unique()

# distance ----------------------------------------------------------------

# Changes 0's to NAs

temp_raster <- 
  raster::reclassify(
    rasters$forest,
    matrix(
      c(1,0,1,NA),
      nrow = 2))

# Determines the distance from NA to non-NA points

park_distance <-
  raster::distance(temp_raster) %>%
  raster::mask(dc_sp)

raster::plot(park_distance)

# extract values to points ------------------------------------------------

# Finding the distance to forest from each survey point

survey %>%
  mutate(
    park_distance =
         raster::extract(
           park_distance,  
           survey))

# Another way of doing the above

survey_park_distance <- 
  raster::extract(
    park_distance,
    survey,
    sp = T) %>%
  as_tibble() %>%
  dplyr::rename(park_distance = layer) %>%
  select(id, park_distance)

# Finds % of different land cover within 200 m around each survey point

survey_lc <- 
  raster::extract(
    rasters,
    survey,
    buffer = 200, # distance (meters) from point
    fun = mean, # average value within distance specified above
    na.rm = T,
    sp = T) %>%
  as_tibble() %>%
  select(id, canopy_cover, impervious_surface)

# Total square meters of forest within 1 kilometer of each point

survey_forest <-
  raster::extract(
    rasters$forest, # or temp_raster
    survey,
    buffer = 1000,
    fun = sum,
    na.rm = T,
    sp = T) %>%
  as_tibble() %>%
  select(c(id, forest)) %>%
  mutate(forest = forest * 900) # mult by size of cell to get area
    
# Change into a single dataframe

survey %>%
  as_tibble() %>%
  select(id:edu_attain) %>%
  left_join(survey_park_distance,
            by = "id") %>%
  left_join(survey_lc,
            by = "id") %>%
  left_join(survey_forest,
            by = "id")




