# set up ------------------------------------------------------------------

library(sf)
library(tidyverse)

# Ensures dplyr's select will be used by default
select <- dplyr::select

# 1. Read in the data:

census_sp <- 
  rgdal::readOGR('data/raw/spatial/census/census.shp')

# 2. Read in the data:

census_sp@proj4string

# 5. Separate data frames for each state:


state_files <-
  purrr::map(
    unique(census_sp@data$state_name),
    ~ census_sp[census_sp$state_name == .,]) %>% 
  set_names(
    str_c(
      unique(census_sp@data$state_name),
      '_sp') %>% 
      tolower())

list2env(
  state_files,
  .GlobalEnv)

# 6. Spatial extent of each state?

purrr::map(
  state_files,
  ~ .@bbox)

# 7. Plot dc_sp:

sp::plot(dc_sp)

# 8. Shapefile of VA:

rgeos::gUnaryUnion(va_sp)

# 9. Plot VA:

rgeos::gUnaryUnion(va_sp) %>% 
  sp::plot()

# 10. Classroom point:

clasroom_sp <-
  sp::SpatialPoints(
    coords = data.frame(-77.075212,38.90677), 
    proj4string = sp::CRS('+proj=longlat +datum=WGS84'))

# 11. dc_sf:

dc_sf <-
  st_as_sf(dc_sp)

# 12. classeroom_sf:

classroom_sf <-
  st_as_sf(clasroom_sp)

# 13. spatial join:

st_transform(
  classroom_sf, 
  st_crs(dc_sf)) %>% 
  st_join(dc_sf) %>% 
  pull(population)

# 14. plotting education:

dc_sf %>% 
  st_as_sf() %>%
  st_transform(crs = 5070) %>%
  rename(Proportion = edu) %>% 
  ggplot() +
  geom_sf(
    aes(fill = Proportion)) +
  geom_sf(
    data = classroom_sf, 
    aes(size = 2),
    shape = "*",
    color = "#00aa00") +
  scale_fill_viridis_c(option =  'magma') +
  theme_minimal() +
  ggtitle(
    "Proportion of the DC population with at least 
    an Associate's degree, by census block")

