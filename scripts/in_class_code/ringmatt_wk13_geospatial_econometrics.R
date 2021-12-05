
# setup -------------------------------------------------------------------

library(sp)
library(ape)
library(gstat)
library(geodist)
library(geosphere)
library(spdep)
library(maptools)
library(sf)
library(tidyverse)

# load and process data ---------------------------------------------------

census <-
  st_read('data/raw/spatial/census/census.shp') %>%
  filter(STATEFP == 11) %>%
  mutate(ALAND = ALAND*1E-6)

# Challenge: Modify the code above such that census only includes data where
# STATEFP is equal to 11 (DC) and the value of ALAND (land area) is converted
# from it's current measure (sq meters) to sq kilometers.

# Read in impervious surface:

impervious <-
  raster::raster('data/raw/spatial/rasters/impervious_surface.tif') %>%
  raster::crop(
    st_transform(census, st_crs(.))) %>%
  raster::projectRaster(crs = 
                          st_crs(census)$proj4string) %>%
  raster::mask(census)

# Challenge: Modify the code above such that the data are subset to the extent
# of the census data and the resultant object is in the same CRS as census.

# Read in crime data:

crimes <-
  read_csv('data/raw/dc_crimes.csv') %>%
  # pull(offense) %>%
  # unique()
  filter(lubridate::year(date_time) == 2020,
         offense_group == "violent") %>%
  st_as_sf(
    coords = c('longitude',
               'latitude'),
    crs = 
      st_crs(census))
  

# Challenge: Modify the code block above such that the data are subset to 
# the year 2020 and are represented as an sf points object.

# Challenge: Modify the census shapefile such that the resultant object
# includes a column representing the number of crimes per km2 and a column
# representing income. NA values for the number of crimes should be replaced by
# zeros. Warning: There should only be 179 features in the resultant object!

census_crimes <-
  st_join(
    crimes,
    census) %>%
  as_tibble() %>%
  group_by(GEOID) %>%
  summarize(crimes_per_km2 = n()/unique(ALAND)) %>%
  left_join(
    census,
    .,
    by = "GEOID") %>%
  transmute(
    crimes_per_km2 = replace_na(crimes_per_km2, 0),
    income)

# Plot crimes_per_km2:

census_crimes %>% 
  ggplot() +
  geom_sf(aes(fill = crimes_per_km2)) +
  scale_fill_viridis_c(option = 'magma') +
  theme_void()

# Convert to points:

census_crimes_pts <-
  census_crimes %>% 
  st_centroid()

# Plot points:

census_crimes_pts %>% 
  ggplot() +
  geom_sf(data = census) +
  geom_sf(aes(size = crimes_per_km2)) +
  theme_void()

# spatial autocorrelation, Moran's I --------------------------------------

distance_matrix <-
  census_crimes_pts %>% 
  st_coordinates() %>% 
  geodist::geodist() 

as.vector(distance_matrix) %>% 
  summary()

# Challenge, view just the first 5 rows and columns of the distance matrix.

distance_matrix[1:5,1:5]

# Calculate the inverse distance matrix:

inverse_distance_matrix <-
  1/distance_matrix

# or, in one step:

inverse_distance_matrix <- 
  census_crimes_pts %>% 
  st_coordinates() %>% 
  geodist::geodist() %>% 
  {1/.}

# Set diagonals to zero:

diag(inverse_distance_matrix) <- 0

# Calculate Moran's I:

ape::Moran.I(x = census_crimes_pts$crimes_per_km2,
             weight = inverse_distance_matrix)

# Challenge: What does the p-value mean? Are crimes spatially autocorrelated?

# The above can also be done with a binary distance matrix (e.g., network analysis):

# Challenge: Generate a binary distance matrix where distance greater than 0 but
# less than 2 kilometers are given the value 1 and all other distances are given
# the value zero.

binary_distance_matrix <-
  distance_matrix > 0 & 
  distance_matrix <= 2000
  
# Spatial autocorrelation with a binary distance matrix:
# Changes "neighbors" to any point within 2km and checks relationship to neighbors

ape::Moran.I(x = census_crimes_pts$crimes_per_km2,
             weight = binary_distance_matrix)

# spatial autocorrelation - correlogram -----------------------------------

# Get coordinates of crimes data and convert to a tibble:

crimes_coords <-
  census_crimes_pts %>% 
  st_coordinates() %>% 
  as_tibble()

pgirmess::correlog(
  coords = crimes_coords,
  z = census_crimes_pts$crimes_per_km2,
  method = 'Moran',
  nbclass = 10) %>% 
  plot()

# Perhaps not super useful given the distance classes?

census_crimes_pts %>% 
  st_transform(crs = 5070) %>% 
  st_coordinates() %>% 
  as_tibble() %>% 
  pgirmess::correlog(
    z = census_crimes_pts$crimes_per_km2,
    method = 'Moran',
    nbclass = 10) %>% 
  plot()

# spatial autocorrelation - semi-variogram --------------------------------

# Calculate a spatial distance matrix:

distance_matrix <-
  census_crimes_pts %>% 
  st_coordinates() %>% 
  geodist::geodist()

census_crimes_sp <-
  census_crimes_pts %>% 
  as_Spatial()

crimes_variogram <-
  variogram(crimes_per_km2 ~ 1, 
            data = census_crimes_sp)

# Make some guesses and generate a "close" model:

plot(crimes_variogram)

variogram_model <-
  vgm(
    psill = 1400,
    nugget = 400,
    range = 3,
    model = 'Gau')

# Fit model

fitted_variogram_model <-
  fit.variogram(crimes_variogram,
                model = variogram_model)

# Plot resultant object:

plot(crimes_variogram, 
     fitted_variogram_model)  

# spatial autocorrelation can be useful!  ---------------------------------

# Generate background points:

reference_points <-
  impervious %>% 
  raster::rasterToPoints() %>%
  as_tibble() %>% 
  st_as_sf(
    coords = c('x', 'y'),
    crs = st_crs(census)) %>% 
  as_Spatial() %>% 
  as_data_frame()

# Interpolate the data:

crimes_kriged <-
  krige(
    crimes_per_km2 ~ 1,
    locations = census_crimes_pts,
    newdata = reference_points,
    model = fitted_variogram_model)

# Plot the modeled data:

crimes_kriged %>% 
  as_Spatial() %>% 
  as_data_frame() %>% 
  ggplot(aes(x = coords.x1, y = coords.x2)) + 
  geom_tile(aes(fill=var1.pred)) + 
  coord_equal() +
  scale_fill_gradient2(
    low = "blue",
    mid = "yellow",
    high="red",
    midpoint = 300) +
  theme_void()

# We can convert the kriged object to a raster:

crimes_raster <-
  crimes_kriged %>%
  as_Spatial() %>% 
  raster::rasterize(impervious)

# Challenge: How well did kriging do at predicting crimes? Extract raster values
# at our crimes centroid (census_crimes_sp) and save the object as a tibble.

crimes_at_points <-
  # Now you

# Challenge: Modify the code above such that there is a new column called
# "difference" where predictions (var1.pred) greater than the actual value are
# assigned to the value "over" and those less than the actual value are assigned
# to the value "under".
  
crimes_at_points <-
  crimes_raster %>% 
  raster::extract(
    census_crimes_sp,
    sp = TRUE) %>% 
  as_tibble() %>% 
  mutate(
    difference = 
      if_else(
        var1.pred > crimes_per_km2,
        'over',
        'under'
      )) 

# Challenge: Use an OLS regression to compare actual vs. actual (crimes_per_km2) vs. predicted (var1.pred) values.
  
crimes_at_points %>% 
  # Now you
  crimes_at_points %>% 
  lm(var1.pred ~ crimes_per_km2,
     data = .) %>% 
  summary()

# Challenge: Plot the data as scatterplot where the points are colored by the values in column "difference".

crimes_at_points %>% 
  ggplot(aes(x = crimes_per_km2,
             y = var1.pred)) +
  geom_point(aes(color = difference))

# OLS ---------------------------------------------------------------------

# How are crime rates associated with income?

census_crimes_pts %>% 
  ggplot(aes(x = income, y = crimes_per_km2)) +
  geom_point() +
  theme_minimal()

census_crimes_pts %>% 
  lm(crimes_per_km2 ~ income,
     data = .) %>% 
  summary()

# but ... what are the assumptions of this model? Do we violate them?

# residuals ---------------------------------------------------------------

ols_model <-
  census_crimes_pts %>% 
  lm(crimes_per_km2 ~ income,
     data = .)

hist(ols_model$residuals)

neighbors_list <-
  census_crimes %>% 
  poly2nb()

neighbors_weights <-
  nb2listw(neighbors_list)

plot(neighbors_weights, 
     st_coordinates(census_crimes_pts))

# Test for spatial autocorrelation of residuals:

lm.morantest(ols_model, neighbors_weights)

# Dealing with spatial autocorrelation, spatial auto regressive models (SAR):

census_crimes_pts %>% 
  lagsarlm(crimes_per_km2 ~ income, 
           data=., 
           neighbors_weights) %>% 
  summary()

# Note: SAR models consider the dependent variable in a given area in relation
# to the values in surrounding areas

# Dealing with spatial autocorrelation, spatial error model (SEM):

census_crimes_pts %>% 
  errorsarlm(crimes_per_km2 ~ income, 
           data=., 
           neighbors_weights) %>% 
  summary()

# Note: SEM models consider the dependencies in error values as a function of
# proximity
