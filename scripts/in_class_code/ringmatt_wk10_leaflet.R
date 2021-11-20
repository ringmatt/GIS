
# setup ---------------------------------------------------------------

library(leaflet)
library(tmap)
library(sf)
library(tidyverse)

# Get the data:

dc <-
  st_read('data/raw/spatial/rasters/dc.shp')

dc_crimes <-
  read_csv('data/raw/dc_crimes.csv')

census <-
  st_read('data/raw/spatial/census/census.shp')

rasters <-
  read_rds('data/raw/spatial/rasters/dc_lc.rds')

# wrangling -----------------------------------------------------------

# Subset dc_crimes to violent crimes:

violent_crimes <-
  dc_crimes %>% 
  filter(lubridate::year(date_time) == 2020,
         offense_group == 'violent')

# Convert violent_crimes to an sf object:

crimes_sp <-
  st_as_sf(
    violent_crimes,
    coords = c('longitude', 'latitude'),
    crs = 4326)

# Subset census data to DC and columns of interest:

dc_census <-
  census %>% 
  filter(STATEFP == 11) %>% 
  select(GEOID, edu, income, population)

# Convert census and crimes data to EPSG 5070:

list(crimes_sp,
     dc_census) %>% 
  map(~st_transform(., crs = 5070)) %>% 
  set_names('crimes_prj', 'census_prj') %>% 
  list2env(.GlobalEnv)

# Join crimes and census data, then simplify the shapes:

census_simple <-
  st_join(
    census_prj,
    crimes_prj) %>% 
  rmapshaper::ms_simplify(keep = 0.05)

# Calculate the number of crimes per 1000 residents and
# return as a simple features object:

census_simpler <-
  census_prj %>% 
  left_join(
    census_simple %>% 
      as_tibble() %>% 
      group_by(GEOID) %>% 
      summarize(crimes_per_1000 = n()/unique(population)*1000),
    by = 'GEOID')

# Transform shapes to 4326:

list(crimes_prj, census_simpler) %>% 
  map(~ st_transform(., crs = 4326)) %>% 
  set_names('crimes_4326', 'census_4326') %>% 
  list2env(.GlobalEnv)

# Subset crimes to robberies:

robberies <-
  crimes_4326 %>% 
  filter(offense == 'robbery')

# Rasterize crimes:

crimes_raster <-
  crimes_prj %>% 
  dplyr::select(-everything()) %>% 
  st_transform(crs = st_crs(rasters)) %>%
  as_Spatial() %>% 
  raster::rasterize(
    rasters, # These are the cells that the points are rasterized to
    fun = 'count', 
    background = 0)

# leaflet -------------------------------------------------------------

# Adds population density

census_4326 <- census_4326 %>%
  mutate(pop_density = population/st_area(.)*1000)

# Creates a palette for population density

pop_density_pal <-
  colorBin(
    bins = 8,
    palette = 'viridis',
    domain = census_4326$pop_density)

# Creates a palette for population

population_pal <-
  colorBin(
    bins = 8,
    palette = 'viridis',
    domain = census_4326$population)

# Adding points

crimes_coords <-
  st_coordinates(crimes_4326) %>% 
  as_tibble() %>% 
  bind_cols(as_tibble(crimes_4326))

# Question 1 ----------------------------------------------------------

census_4326 %>% 
  leaflet() %>% 
  
  addTiles() %>%
  
  # Adds a choropleth of Census population
  
  addPolygons(
    weight = 2,
    fillColor = 
      ~population_pal(population),
    fillOpacity = 0.7) %>% 
  
  # Adds robbery markers as circles
  
  addCircleMarkers(
    lng = crimes_coords[crimes_coords$offense == "robbery",]$X,
    lat = crimes_coords[crimes_coords$offense == "robbery",]$Y,
    clusterOptions = markerClusterOptions()) %>% 
  
  addLegend(
    'bottomleft',
    pal = population_pal, 
    values = ~population, 
    opacity = 1)

# Question 2 ----------------------------------------------------------

# Creates a plot of population and robberies in DC

census_4326 %>% 
  leaflet() %>% 
  
  # Adds the Wikimedia background & tiles
  
  addTiles() %>%
  addProviderTiles(providers$Wikimedia) %>% 
  
  # Adds a choropleth of DC population by Census tract
  
  addPolygons(
    weight = 2,
    fillColor = 
      ~population_pal(population),
    fillOpacity = 0.7) %>% 
  
  # Adds circular markers for robberies
  
  addCircleMarkers(
    lng = crimes_coords[crimes_coords$offense == "robbery",]$X,
    lat = crimes_coords[crimes_coords$offense == "robbery",]$Y,
    clusterOptions = markerClusterOptions(),
    label = crimes_coords$date_time) %>% 
  
  # Adds the legend
  
  addLegend(
    'bottomleft',
    pal = population_pal, 
    values = ~population, 
    opacity = 0.7)

# Question 3 ----------------------------------------------------------

# Creates an interactive map of crime and population in DC
# w/ adjustable background maps

census_4326 %>% 
  leaflet() %>% 
  
  # Adds tiles
  
  addTiles(group = 'Open Street Map') %>%
  
  # Adds an orthophoto background
  
  addProviderTiles(
    providers$Esri.WorldImagery,
    group = 'Orthophoto') %>% 
  
  # Adds a background from Wikimedia
  
  addProviderTiles(
    providers$Wikimedia,
    group = 'Wikimedia') %>% 
  
  # Adds population per Census tract as a choropleth
  
  addPolygons(
    weight = 2,
    fillColor = 
      ~population_pal(population),
    fillOpacity = 0.7,
    group = 'Population by Census Tract') %>% 
  
  # Adds interactive circular markers for robberies
  
  addCircleMarkers(
    lng = crimes_coords[crimes_coords$offense == "robbery",]$X,
    lat = crimes_coords[crimes_coords$offense == "robbery",]$Y,
    clusterOptions = markerClusterOptions(),
    label = crimes_coords$date_time,
    group = 'Robberies') %>% 
  
  # Adds interactive markers for violent crimes
  
  addMarkers(
    lng = crimes_coords$X,
    lat = crimes_coords$Y,
    clusterOptions = markerClusterOptions(),
    label = crimes_coords$date_time,
    group = 'Violent Crimes') %>% 
  
  # Includes the Census data's legend in the bottom left
  
  addLegend(
    'bottomleft',
    pal = population_pal, 
    values = ~population, 
    opacity = 1) %>% 
  
  # Adds each layer to an interactive legend
  
  addLayersControl(
    baseGroups = c('Open Street Map',
                   'Orthophoto',
                   'Wikimedia'),
    overlayGroups = c('Violent Crimes', 
                      'Robberies', 
                      'Population by Census Tract')) %>% 
  
  # Starts with violent crimes unchecked
  
  hideGroup('Violent Crimes')

# Question 4 ----------------------------------------------------------

raster_4326 <-
  crimes_raster %>% 
  
  # Aggregates to 500m x 500m resolution
  
  raster::aggregate(
    fact = 16,
    fun = sum,
    na.rm = T) %>%
  
  # Projects to the Census data's crs (EPSG 4326)
  
  raster::projectRaster(
    crs = st_crs(census_4326)$proj4string) %>%
  
  # Masks to the Census data
  
  raster::mask(census_4326)

# End of Assignment Additional Work -----------------------------------

raster_pal <-
  colorNumeric(
    palette = 'Reds',
    domain = raster::values(raster_4326),
    na.color = '#00000000')

census_4326 %>% 
  leaflet() %>% 
  
  addTiles(group = 'Open Street Map') %>%
  addProviderTiles(
    providers$Esri.WorldImagery,
    group = 'Orthophoto') %>% 
  
  addRasterImage(
    raster_4326,
    colors = raster_pal,
    opacity = 0.9,
    group = 'Crime Density') %>% 
  
  addPolygons(
    weight = 2,
    fillColor = 
      ~population_pal(population),
    fillOpacity = 0.7,
    group = 'Population by Census Tract') %>% 
  
  addMarkers(
    lng = crimes_coords$X,
    lat = crimes_coords$Y,
    clusterOptions = markerClusterOptions(),
    label = crimes_coords$date_time,
    group = 'Violent Crimes') %>% 
  
  addLegend(
    'bottomleft',
    pal = population_pal, 
    values = ~population, 
    opacity = 0.7) %>% 
  
  addLayersControl(
    baseGroups = c('Open Street Map',
                   'Orthophoto'),
    overlayGroups = c('Violent Crimes',
                      'Population by Census Tract',
                      'Crime Density')) %>% 
  
  hideGroup('Violent Crimes')
