
# setup -------------------------------------------------------------------

library(sf)
library(lubridate)
library(tidyverse)

# Read in data:

va_collisions <-
  read_csv('data/raw/homework_data_deer_collisions/va_collisions.csv')

va_counties <-
  st_read('data/raw/homework_data_deer_collisions/VirginiaCounty.shp')

nlcd <-
  raster::raster('data/raw/homework_data_deer_collisions/nlcd2016.tif')


# Question 1 --------------------------------------------------------------

# In the va_collisions.csv file, remove zero value coordinates and repair
# erroneous coordinates (e.g., coordinates outside of the state of Virginia).

# Determine bounding box of virginia in EPSG 4326:

va_bbox <-
  va_counties %>% 
  st_transform(crs = 4326) %>% 
  st_bbox()

# Take a look at collisions summary info (would normally do this in the
# console):

summary(va_collisions)

# Notice that some x values are positive (all longitudes in the Western
# hemisphere are negative) and some y values are negative (all latitudes in the
# Northern hemisphere are positive)! Switched longitudes and latitudes are very
# common.

collisions <-
  va_collisions %>% 
  mutate(
    x_temp = 
      if_else(
       between(x, va_bbox$xmin, va_bbox$xmax),
       x,
       y),
    y_temp = 
      if_else(
        between(y, va_bbox$ymin, va_bbox$ymax),
        y,
        x),
    x = x_temp,
    y = y_temp) %>% 
  select(-c(x_temp, y_temp))

# Question 2 --------------------------------------------------------------

# Simplify the counties shapefile such that the size of the resultant file is
# less than 1 MB.

counties_simple <-
  va_counties %>% 
  rmapshaper::ms_simplify(keep = 0.05)

# Question 3 --------------------------------------------------------------

# Generate a summary table showing the total number of collisions by county. 

collisions_sp <-
  collisions %>% 
  
  # Make spatial:
  
  st_as_sf(
    coords = c('x', 'y'),
    crs = 4326) %>% 
  
  # Transform to the CRS of counties_simple:
  
  st_transform(
    st_crs(counties_simple))

# Join counties and collisions

collisions_counties <-
  st_join(
    collisions_sp,
    counties_simple)


# Then summarize:

collisions_counties %>% 
  as_tibble() %>% 
  group_by(NAMELSAD) %>% 
  summarize(n = n())

# Question 4 --------------------------------------------------------------

# Create a bar plot that summarizes the number of collisions by season. Use this
# conversion for seasons: Sept-Nov = Fall; Dec-Feb = Winter; Mar-May = Spring;
# June-Aug = Summer.

# This was a weird interlude, but ...
  
collisions %>% 
  mutate(
    
    # Assign a season to each date:
    
    season = 
      case_when(
        month(date_time) %in% 9:11 ~ 'Fall',
        month(date_time) %in% c(12, 1, 2) ~ 'Winter',
        month(date_time) %in% 3:5 ~ 'Spring',
        month(date_time) %in% 6:8 ~ 'Summer') %>% 
      
      # (Optional) Convert to a factor so the data can be displayed in season
      # order:
      
      factor(
        levels = c(
          'Winter',
          'Spring', 
          'Summer',
          'Fall'))) %>% 
  
  # Summarize by season:
  
  group_by(season) %>% 
  summarize(n = n()) %>% 
  
  # Plot the data:
  
  ggplot(
    aes(x = season,
        y = n)) +
  geom_bar(stat = 'identity') +
  
  # (Optional) Change the y axis scale to something less dumb:
  
  scale_y_continuous(
    limits = c(0, 20000),
    expand = c(0, 0)) +
  
  # (Optional) Modify the plot labels:
  
  labs(
    title = 'Deer collisions in Virginia, by season 2011-2017',
    xlab = 'Season',
    ylab = 'Number of collisions') +
  
  # (Optional) Modify the theme:
  
  theme_bw()

# Question 5 --------------------------------------------------------------

# Generate a map showing the counties of Virginia with counties colored by the
# average number of collisions per year.

# Summarize collisions and counties again (as Question 3, above):

collisions_counties %>% 
  as_tibble() %>% 
  group_by(NAMELSAD) %>% 
  summarize(
    n = n()/
      length(
        unique(
          year(date_time)))) %>% 
  
  # Join to counties_simple to make the file spatial:
  
  left_join(
    counties_simple,
    .,
    by = 'NAMELSAD') %>% 
  
  # Map it:
  
  ggplot() +
  geom_sf(aes(fill = n)) +
  scale_fill_viridis_c(option = 'viridis') +
  theme_void() 


# Question 6 --------------------------------------------------------------

# Subset the NLCD raster to the extent and outline of Warren County. Generate a
# raster stack with two layers, forested/non-forested and developed/undeveloped
# land.

# Transform the counties file to the same CRS as the raster:

counties_warren <-
  counties_simple %>% 
  filter(NAMELSAD == 'Warren County') %>% 
  st_transform(
    crs = st_crs(nlcd))
  
# Crop and mask the raster to Warren County:

nlcd_warren <-
  raster::crop(
    nlcd,
    counties_warren) %>% 
  raster::mask(counties_warren) 

# Version 1: No purrr:

reclass_forest <-
  tibble(
    from = 
      raster::values(nlcd_warren) %>% 
      unique() %>% 
      sort()) %>% 
  mutate(
    to = if_else(from %in% 41:43, 1, 0)) %>% 
  as.matrix()


reclass_developed <-
  tibble(
    from = 
      raster::values(nlcd_warren) %>% 
      unique() %>% 
      sort()) %>% 
  mutate(
    to = if_else(from %in% 21:24, 1, 0)) %>% 
  as.matrix()

my_stack <-
  list(
  forest = 
    nlcd_warren %>% 
    raster::reclassify(reclass_forest),
  developed = 
    nlcd_warren %>% 
    raster::reclassify(reclass_developed)) %>% 
  raster::stack()

# Version 2 (extra credit), with purrr:

my_stack <-
  map(
    list(41:43, 
         21:24),
    function(reclass_values) {
      tibble(
        from = 
          raster::values(nlcd_warren) %>% 
          unique() %>% 
          sort()) %>% 
        mutate(
          to = if_else(from %in% reclass_values, 1, 0)) %>% 
        as.matrix() %>% 
        raster::reclassify(nlcd_warren, .)
    }) %>% 
  set_names('forest', 'developed') %>% 
  raster::stack()

# Question 7 --------------------------------------------------------------

# Easiest way is to subset collisions to warren county:

collisions_counties %>% 
  filter(NAMELSAD == 'Warren County') %>% 
  
  # Then project to the same projection as the raster:
  
  st_transform(crs = st_crs(my_stack)) %>% 
  
  # Then extract:
  
  raster::extract(
    my_stack,
    .,
    buffer = 200,
    fun = mean,
    na.rm = TRUE,
    sp = TRUE) %>% 
  as_tibble() %>% 
  summarize(
    forest = mean(forest),
    developed = mean(developed))
  # Or (did I teach you summarize_at?):
  # summarize_at(
  #   vars(forest, developed),
  #   ~ mean(.))
  









