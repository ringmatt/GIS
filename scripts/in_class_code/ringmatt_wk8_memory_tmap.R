
# setup ---------------------------------------------------------------

# Libraries

library(leaflet)
library(tmap)
library(sf)
library(tidyverse)

# data

dc_crimes <-
  read_csv('data/raw/dc_crimes.csv')

# Question 1: Subsetting and assigning data

dc_census <-
  st_read('data/raw/spatial/census/census.shp') %>%
  filter(state_name == "DC") %>%
  select(GEOID, edu, income, population)

dc_census %>%
  ggplot() +
  geom_sf(aes(fill = population)) +
  scale_fill_continuous(type = "viridis") +
  theme_void()

# End of Question 1

# Managing Memory -----------------------------------------------------

dc_census_reduced <-
  dc_census %>% 
  select(GEOID, edu, income, population)

# Question 2: Filter to only violent crimes
# Compare the size to the original object

violent_crimes <-
  dc_crimes %>%
  filter(lubridate::year(date_time) == 2020 &
         offense_group == "violent")

dc_crimes %>%
  object.size() %>% 
  format('Mb')

violent_crimes %>%
  object.size() %>% 
  format('Mb')

# End of Question 2

crimes_sp <-
  st_as_sf(
    violent_crimes,
    coords = c('longitude', 'latitude'),
    crs = 4326)

# Question 3: Transform projections


list(dc_census_reduced,
     crimes_sp) %>%
  purrr::map(function(df) {
    df %>%
      st_as_sf() %>%
      st_transform(crs = 5070)
  }) %>% 
  set_names('census_prj', 'crimes_prj') %>%
  list2env(.GlobalEnv)

# End of Question 3

# Question 4: Crime counts

census_prj %>%
  left_join(           # Left join is much faster
    st_join(           # Spatial join
      census_prj,
      crimes_prj) %>% 
    as_tibble() %>%    # Makes non-spatial
    group_by(GEOID) %>% 
    summarize(n = n()),
    by = "GEOID") %>%
  ggplot() +
  geom_sf(aes(fill = n)) +
  scale_fill_viridis_c(option = "cividis") +
  theme_void()

# End of Question 4

census_simple <-
  st_join(
    census_prj,
    crimes_prj) %>% 
  rmapshaper::ms_simplify(keep = 0.05)

# Question 5: Crimes per 1000

census_simpler <-
  census_simple %>%    # Work with original data file instead of pre-trimmed
  rmapshaper::ms_simplify(keep = 0.05) %>%
  group_by(GEOID) %>% 
  summarize(n = n(),
            population = unique(population)) %>%
  mutate(crimes_per_1000 = 
           if_else(population != 0,
                   n/population*1000, 
                   NA))

census_simpler %>%
  ggplot() +
  geom_sf(aes(fill = crimes_per_1000)) +
  scale_fill_viridis_c(option = "cividis") +
  theme_void()

# End of Question 5

# Remove extra files

rm(dc_crimes,
   dc_census,
   violent_crimes,
   dc_census_reduced,
   crimes_sp,
   census_simple,
   census_prj)

# tmap ----------------------------------------------------------------

# Question 6: Transform object crs's

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

# End of Question 6

tmap_mode('plot')

basemap <-
  st_bbox(census_4326) %>% 
  tmaptools::read_osm()

# Question 7: Filter to robberies

robberies <- crimes_4326 %>%
  filter(offense == "robbery")

# End of Question 7

# Question 8: Add homicides to the map of robberies

tm_shape(basemap) +
  tm_rgb() +
  
  tm_shape(census_4326) +
  tm_polygons(col = 'crimes_per_1000') +
  
  tm_shape(robberies) +
  tm_dots(size = 0.15,
          alpha = 0.4) +
  
  tm_shape(crimes_4326 %>%
             filter(offense == "homicide")) +
  tm_markers(size = 0.15) +
  
  tm_layout(legend.outside = TRUE)

# End of Question 8

# Question 9: Filter crimes to either homicides or robberies

crimes_4326 %>%
  filter(offense %in% c("homicide", "robbery"))

# End of Question 9

# Final Plot (Not a question)

tm_shape(basemap) +
  tm_rgb() +
  
  tm_shape(census_4326) +
  tm_polygons(col = 'crimes_per_1000') +
  
  tm_shape(
    crimes_4326 %>% 
      filter(offense %in% c('robbery', 'homicide'))) +
  tm_dots(
    col = 'offense',
    palette = c(robbery = 'blue', homicide = 'red'),
    size = 0.15,
    alpha = 0.5) +
  
  tm_layout(legend.outside = TRUE)
