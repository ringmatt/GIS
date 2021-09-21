# Setup

library(sf)
library(tidyverse)

# 1. Data

states <- 
  spData::us_states

# 2. Reading shapefile

census <- 
  rgdal::readOGR('data/raw/spatial/census/census.shp') %>% 
  st_as_sf()

#census <- 
#   st_read('data/spatial/census/census.shp')

# 3. Reading in points

classroom <-
  sp::SpatialPoints(
    coords = data.frame(-77.075212,38.90677), 
    proj4string = sp::CRS('+proj=longlat +datum=WGS84')) %>% 
  st_as_sf()

# Read points data frame (sf):

classroom <-
  classroom %>% 
  data.frame(-77.075212,38.90677) %>% 
  st_as_sf(crs = 4326)

# 4. Subsetting objects

object.size(census)

dc_tracts <-
  filter(census, state_name == 'DC') %>% 
  st_make_valid()

va_tracts <-
  filter(census, state_name == 'Virginia') %>% 
  st_make_valid()

md_tracts <-
  filter(census, state_name == 'Maryland') %>% 
  st_make_valid()

# 5. Compare object sizes

object.size(dc_tracts)

object.size(md_tracts)

object.size(va_tracts)

# 6. Simplifying Spatial Polygons

md_tracts %>% 
  as('Spatial') %>% 
  rgeos::gUnaryUnion()

# Using the sf package

md <-
  st_union(
    md_tracts,
    is_coverage = TRUE)

# Uses faster sp function, but outputs sf

md <-
  md_tracts %>% 
  as('Spatial') %>% 
  rgeos::gUnaryUnion() %>% 
  st_as_sf()

# Plot

ggplot(md) +
  geom_sf() +
  theme_void()

# Project the data and replot

md %>%
  st_transform(crs = 5070 )%>% 
  st_simplify(dTolerance = 2000) %>% 
  ggplot() +
  geom_sf() +
  theme_void()

# Increasing tolerance makes the shape less detailed

md %>%
  st_transform(crs = 5070 )%>% 
  st_simplify(dTolerance = 10000) %>% 
  ggplot() +
  geom_sf() +
  theme_void()

# Increasing tolerance also reduces object size

st_transform(md, crs = 5070) %>% 
  object.size()

st_transform(md, crs = 5070) %>% 
  st_simplify(dTolerance = 2000) %>% 
  object.size()

# 7. Simplifying Mutli-Polygon Objects

states %>% 
  st_transform(crs = 5070) %>%
  ggplot() +
  geom_sf() +
  theme_void()

states %>% 
  st_transform(crs = 5070) %>%
  st_simplify(dTolerance = 10000) %>% 
  ggplot() +
  geom_sf() +
  theme_void()

# Looking at NE

states %>% 
  filter(REGION == 'Norteast') %>% 
  st_transform(crs = 5070) %>%
  st_simplify(dTolerance = 10000) %>% 
  ggplot() +
  geom_sf() +
  theme_void()

states %>% 
  st_transform(crs = 5070) %>% 
  mutate(AREA = as.numeric(AREA)) %>% 
  rmapshaper::ms_simplify(keep = 0.05) %>% 
  ggplot() +
  geom_sf() +
  theme_void()

# 8. Clipping

dc_tracts %>% 
  ggplot() +
  geom_sf() +
  geom_sf(
    data = classroom,
    size  = 3,
    color = 'red') +
  theme_void()

# Adds point buffer

st_buffer(classroom, dist = 1000)

dc_tracts %>% 
  st_transform(crs = 5070) %>% 
  ggplot() +
  geom_sf() +
  geom_sf(
    data = 
      st_buffer(
        classroom, 
        dist = 5000), 
    fill = 'blue', 
    alpha = .4) +
  geom_sf(
    data = classroom,
    size  = 3,
    color = 'red') +
  theme_void()

# Use point buffer to get overlap

dc_tracts %>% 
  st_intersection(
    classroom %>% 
      st_buffer(dist = 5000) %>% 
      st_transform(
        crs = st_crs(dc_tracts))) %>% 
  ggplot() +
  geom_sf() +
  theme_void()

# Challenge!

#Estimate DC population size within 5 km of campus.
#What assumptions did you make?

# Hint: Spatial join within non-spatial join
  

dc_tracts %>% 
  st_intersection(
    classroom %>% 
      st_buffer(dist = 5000) %>% 
      st_transform(
        crs = st_crs(dc_tracts))) %>%
  # Calculates area of the partial tract
  mutate(geom_area = st_area(geometry)) %>%
  # Joins in full tract areas
  left_join(dc_tracts %>%
            # Subsets to relevant columns
            select(c(GEOID, geom_full = geometry)) %>%
            # Calculates area of the full tract
            mutate(geom_full_area = st_area(geom_full)) %>%
            # Removes the geometry
            select(-c(geom_full)) %>%
            # Ensures the dataframe is a tibble
            as_tibble()) %>%
  # Adjusts population by proportion of area within 5km
  mutate(pop_adjusted = population*(geom_area/geom_full_area)) %>%
  # Selects only necessary columns
  select(c(GEOID, STATEFP, pop_adjusted, geom_area, geom_full_area)) %>%
  # Extracts total population
  summarise(total_pop = sum(pop_adjusted)) %>%
  pull(total_pop)








