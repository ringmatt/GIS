# Loads tidyverse
library(tidyverse)

# Reads in shapefile of states
states <- 
  rgdal::readOGR("data/raw/spatial/states_dmv/stusps.shp") # Issa ESRI file

# What type of object is "states"?
class(states)

# Structure of "states"
str(states)

# Can check slot (@) names

slotNames(states)

states@data

states@proj4string # contains the datum projection

# Plots a simple plot

sp::plot(states)

# Print proj4string of spatial dataset
raster::crs(states)

# EPSG codes
rgdal::make_EPSG() %>% 
  as_tibble() %>% 
  filter(str_detect(prj4, 'longlat'),
         str_detect(prj4, 'WGS84'))

# column names
names(states)

# Can interact as if a data frame (bc it is)

# Plotting Maryland
state_subset <-
  states[states$stat_nm == 'Maryland',]

sp::plot(
  state_subset, 
  col = '#dcdcdc')

# When run together, highlights MD in DMV

sp::plot(
  states, 
  col = '#dcdcdc')

sp::plot(
  state_subset, 
  col = '#bb0000',
  add = TRUE)

# Merge the DMV
region <-
  rgeos::gUnaryUnion(states)

sp::plot(
  region, 
  col = '#dcdcdc')

## Making Points

points <- 
  readr::read_csv('data/raw/wk3/sites.csv') %>% 
  as.data.frame() %>% 
  dplyr::select(lon, lat) %>% 
  sp::SpatialPoints(proj4string = raster::crs("+init=epsg:4326"))

# Bounding box

sp::bbox(points)

# Run together to plot on map

sp::plot(
  states, 
  col = '#dcdcdc')

sp::plot(
  points, 
  pch = 19,
  add = TRUE)

## SpatialPoints DF

points_spdf <- 
  readr::read_csv('data/raw/wk3/sites.csv') %>%
  as.data.frame() %>% 
  sp::SpatialPointsDataFrame(
    coords = .[,c('lon', 'lat')],
    data = .,
    proj4string = sp::CRS("+init=epsg:4326"))

sp::plot(
  states, 
  col = '#dcdcdc')

sp::plot(
  points, 
  pch = 19,
  col = 'red',
  add = TRUE)

# Spatial join - Extracting values to points
sp::over(points_spdf, states) %>% 
  tibble::as_tibble()


