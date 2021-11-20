
# setup ---------------------------------------------------------------

# libraries

library(tidyverse)
library(sf)

# unzip data folder

unzip(
  zipfile =  'data/raw/homework_data_deer_collisions.zip',
  exdir = 'data/raw')

# open shapefile and raster data

va_land_cover <-
  raster::raster('data/raw/homework_data_deer_collisions/nlcd2016.tif')

va_shp <-
  st_read('data/raw/homework_data_deer_collisions/VirginiaCounty.shp') %>%
  st_transform(
    crs = st_crs(va_land_cover))


# output --------------------------------------------------------------

# 1. Remove and fix zero and erroneous coordinates from the csv file

va_collisions <- 
  read.csv("data/raw/homework_data_deer_collisions/va_collisions.csv") %>%
  as_tibble() %>%
  mutate(x_temp =     # Finds then flips reversed lat/lon values
           if_else(x > 0, y, x),
         y_temp = 
           if_else(y < 0, x, y)) %>%
  mutate(x = x_temp,
         y = y_temp) %>%
  filter(x != 0 &     # Removes missing values
           y != 0 &
           !is.na(x) &
           !is.na(y)) %>%
  select(-c(x_temp, y_temp)) %>%
  st_as_sf(coords = c("x", "y"),    # Converts to a sf of points
           crs = 4326) %>%
  st_transform(crs = 
                 st_crs(va_land_cover)) %>%
  st_join(va_shp) %>%    # removes points outside of VA's counties
  filter(!is.na(STCOFIPS)) %>%
  select(-c(STCOFIPS:JURISTYPE))

# 2. Simplify the shapefile to decrease its file size to under 1MB

va_shp <- va_shp %>%
  st_simplify(dTolerance = 20) # Use rmapshaper::ms_simplify(keep = 0.05)

va_shp %>%
  object.size()

# 3. Summary table of collisions by county

va_collisions %>%
  st_join(va_shp) %>%
  as_tibble() %>%
  group_by(STCOFIPS, NAMELSAD) %>%
  summarize(collisions = 
              n()) %>%
  ungroup() %>%
  select(c(county = NAMELSAD, collisions)) %>%
  arrange(
    desc(collisions))

# 4. Create a bar plot of collisions by season

va_collisions %>%
  mutate(month = lubridate::month(
    as.Date(
      date_time))) %>%
  mutate(Season =
           if_else(
             month > 2 & month < 6,
             "Spring",
             if_else(
               month > 5 & month < 9,
               "Summer",
               if_else(month > 8 & month < 12,
                       "Fall",
                       "Winter")) )) %>% 
  as_tibble() %>%
  ggplot(aes(Season, fill = Season)) +
  geom_bar() +
  labs(y = "Collisions",
       title = "Deer Collisions in Virginia by Season") +
  theme_minimal() +
  theme(legend.position = "none")

# 5. Create a choropleth of Virginia counties 
# by average collisions per year

va_shp %>%
  st_join(va_collisions) %>%
  mutate(year = lubridate::year(
    as.Date(date_time))) %>%
  group_by(STCOFIPS, year) %>%
  summarize(collisions =
              n()) %>%
  group_by(STCOFIPS) %>%
  summarize(avg_yearly_collisions =
              mean(collisions, na.rm = T)) %>%
  ggplot() +
  geom_sf(aes(fill = avg_yearly_collisions)) +
  scale_fill_continuous(type = "viridis") +
  theme_void() +
  labs(fill = "Average Yearly Collisions")

# 6. Subset the raster to Warren County
# Generate a raster stack with two-layers: forested/non-forested &
# developed/undeveloped land

# Creates a matrix converting non-forest tiles to zero

forest_reclass <- 
  tibble(
    from = 
      va_land_cover %>%
      raster::values() %>%
      unique() %>%
      sort()) %>%
  mutate(
    to = 
      if_else(from %in% 41:43, 1, 0)) %>%
  as.matrix()

# Creates a matrix converting non-developed tiles to zero

developed_reclass <- 
  tibble(
    from = 
      va_land_cover %>%
      raster::values() %>%
      unique() %>%
      sort()) %>%
  mutate(
    to = 
      if_else(from %in% 21:24, 1, 0)) %>%
  as.matrix()

reclass_matrices <-
  list(forest_reclass, developed_reclass)

# Creates the raster stack, with two rasters:
# one for forests and one for developed land in Warren County

warren_rasters <- 
  reclass_matrices %>%
    purrr::map(
      ~ va_shp %>%
        filter(NAMELSAD == "Warren County") %>%
        raster::crop(va_land_cover, .) %>%
        raster::mask(va_shp %>%
                       filter(NAMELSAD == "Warren County")) %>%
        raster::reclassify(.x)) %>%
  set_names('forest', 'developed') %>% 
  raster::stack()

# 7. Report average forest and developed land within 200m of each incident

va_collisions %>%
  # st_join(va_shp) %>%
  # filter(NAMELSAD == "Warren County") %>%
  left_join(
    raster::extract(     # Determines average forested land near collision
      raster::subset(warren_rasters, 1),
      .,
      buffer = 200,    # distance (meters) from point
      fun = mean,    # average value within distance specified above
      na.rm = T,
      sp = T) %>%
      as_tibble() %>%
      select(c(event_id,
               proportion_forest = forest)) %>%
      filter(proportion_forest > 0),
    on = "event_id") %>%
  left_join(
    raster::extract(     # Determines average developed land near a collision
      raster::subset(warren_rasters, 2),
      .,
      buffer = 200,      # distance (meters) from point
      fun = mean,      # average value within distance specified above
      na.rm = T,
      sp = T) %>%
      as_tibble() %>%
      select(c(event_id,
               proportion_developed = developed)) %>%
      filter(proportion_developed > 0),
    on = "event_id") %>%
  as_tibble() %>%
  select(c(proportion_forest, proportion_developed)) %>% 
  summarize(average_proportion_forest = 
              mean(proportion_forest, na.rm = T),
            average_proportion_developed = 
              mean(proportion_developed, na.rm = T))
  

# end script ----------------------------------------------------------

# Clear any hidden connections

gc()

# Remove the unzipped homework folder

unlink(
  'data/raw/homework_data_deer_collisions',
  recursive = TRUE)








