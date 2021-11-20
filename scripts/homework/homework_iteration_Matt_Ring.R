
# setup ---------------------------------------------------------------

# libraries

library(tidyverse)
library(sf)

# unzip data folder

unzip(
  zipfile =  'data/raw/homework_iteration.zip',
  exdir = 'data/raw')

# read in files --------------------------------------------------

# 1. read in conus counties shapefile

read_dir <-
  'data/raw/homework_iteration'

conus_counties <-
  st_read(
    file.path(read_dir, 'conus_counties.shp'))

# 2. generate a vector of shapefile names

shp_names <-
  list.files(
    read_dir,
    pattern = '.shp')

# 3. read all shapefiles to global environment iteratively

shp_names %>% 
  purrr::map(
    ~ file.path(read_dir, .) %>% 
      st_read()) %>% 
  set_names(
    str_remove(shp_names, '.shp')) %>% 
  list2env(.GlobalEnv)


# reading and processing files ----------------------------------------

# 4. reads in conus_counties.shp and sets all column names to lowercase

conus_counties <-
  st_read(
    file.path(read_dir, 'conus_counties.shp')) %>%
  set_names(
    names(.) %>%
      tolower())

# 5. reads in all shapefiles and sets all column names to lowercase

shp_names %>% 
  purrr::map(
    ~ file.path(read_dir, .) %>% 
      st_read() %>%
      set_names(
        names(.) %>%
          tolower())) %>% 
  set_names(
    str_remove(shp_names, '.shp')) %>% 
  list2env(.GlobalEnv)

# 6. read in conus_counties.shp, sets all columns to lowercase, 
# and converts the CRS to EPSG 5070

conus_counties <-
  st_read(
    file.path(read_dir, 'conus_counties.shp')) %>%
  set_names(
    names(.) %>%
      tolower()) %>%
  st_transform(crs = 5070)

# 7. reads in all shapefiles, changing column names to lowercase and
# CRS to EPSG 5070

shp_names %>% 
  purrr::map(
    ~ file.path(read_dir, .) %>% 
      st_read() %>%
      set_names(
        names(.) %>%
          tolower()) %>%
      st_transform(crs = 5070)) %>% 
  set_names(
    str_remove(shp_names, '.shp')) %>% 
  list2env(.GlobalEnv)


# iteration and flow construction -------------------------------------

# 8. read conus_counties.shp, set column names to lowercase, subset
# to California, and transform the CRS to ESPG 5070.
# Then, plot conus_counties using ggplot

st_read(file.path(read_dir, 'conus_counties.shp')) %>%
  set_names(tolower(names(.))) %>%
  filter(state == 'California') %>%
  st_transform(crs = 5070) %>%
  ggplot(aes(fill = aland)) +
  scale_fill_viridis_b() +
  geom_sf() +
  theme_void()

# 9. Builds on question 7 by subsetting to only Western states

western_states <-
  c("Arizona",
    "California",
    "Colorado",
    "Idaho",
    "Montana",
    "Nevada",
    "New Mexico",
    "Oregon",
    "Utah",
    "Washington",
    "Wyoming")

western_shapes <- shp_names %>% 
  purrr::map(
    ~ file.path(read_dir, .) %>% 
      st_read() %>%
      set_names(
        names(.) %>%
          tolower()) %>%
      st_transform(crs = 5070) %>% 
  {if('state' %in% names(.)){
    filter(., state %in% western_states)
  } else{
    .
  }}) %>%
  set_names(
    str_remove(shp_names, '.shp')) %>% 
  list2env(.GlobalEnv)

# 10. Plots western states by percentage of inmates who tested positive 
# for covid in 2020

western_shapes$conus_states %>%
  left_join(read_csv(
    file.path(read_dir, 'prison_systems.csv'))) %>%
  select(c(state, 
           total_inmate_cases, 
           max_inmate_population_2020)) %>%
  mutate(percent_inmate_cases = 
           total_inmate_cases / max_inmate_population_2020) %>%
  ggplot(aes(fill = percent_inmate_cases)) +
  scale_fill_viridis_c(option = "magma") +
  geom_sf() +
  theme_void()

# Clear any hidden connections

gc()
  
# Removes the homework_iteration folder

unlink(
  'data/raw/homework_iteration',
  recursive = TRUE)

