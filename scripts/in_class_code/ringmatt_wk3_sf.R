# Load packages
library(sf)
library(tidyverse)

# Import data, convert to simple features object
states_sf <-
  rgdal::readOGR('data/raw/spatial/states_dmv/states.shp') %>%
  st_as_sf() %>%
  # Change column name for states
  rename(state = ID) %>%
  # Import additional 1977 state information
  left_join(
    read_csv('data/raw/wk3/states_1977.csv'),
    by = 'state')

# Plot with ggplot
states_sf %>% 
  ggplot() +
  geom_sf(aes(fill = population)) +
  scale_fill_viridis_c(option = 'plasma')

## Transform Projections

states_prj <-
  states_sf %>%
  mutate(
    population_density = population/area) %>% 
  st_transform(crs = 5070)

states_prj %>% 
  ggplot() +
  geom_sf(aes(fill = population_density)) +
  scale_fill_gradient2(
    low = 'blue', 
    mid = 'white', 
    high = 'red',
    midpoint = 0.4) +
  theme_void()

## Invalid Geometries

# % of states with invalid geometries
# that are not easily fixable
st_make_valid(states_sf) %>% 
  st_is_valid() %>% 
  sum(.)/nrow(states_sf)

# Overwrite (don't do irl!) and resave
states_proj <- states_prj %>%
  st_make_valid()

# Never resave obj in global env

## Points

sites_sf <-
  read_csv("data/raw/wk3/sites.csv") %>%
  st_as_sf(
    x = sites,
    coords = c('lon', 'lat'),
    remove = FALSE, 
    crs = 4326) %>%
  st_transform(st_crs(states_prj))

# Super simple spatial join!
# Needed to change crs
states_sf %>% 
  st_join(states_prj)
  



