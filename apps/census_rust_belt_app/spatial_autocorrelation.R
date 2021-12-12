
# setup -------------------------------------------------------------------

library(tidyverse)
library(sf)
library(sp)
library(spdep)
library(rgdal)
library(rgeos)
library(tmap)
library(tmaptools)
library(spgwr)
library(grid)
library(gridExtra)

# data --------------------------------------------------------------------

# Read in Census et al. data

df_counties <- 
  read_csv("data/master_dataset_clean.csv") %>%
  select(!...1) %>%
  rename(State = state,
         County = name) %>%
  
  # Creates a new column summing each selected feature
  
  mutate(`Recovery Score` =
           prcomp(
             select(.,
                    
                    # Select columns to build Recovery Score with
                    
                    c(pop_change, income_change,
                      home_val_change, 
                      housing_construction_increase,
                      manufacturing_percent_change)),
             rank. = 1,
             center = TRUE,
             retx = TRUE)$x[,1]) %>%
  
  # Subset to only GEOID, State, County, and Recovery score
  
  select(GEOID,
         State, 
         County, 
         `Recovery Score`)

# Read in shapefiles:

counties_shp <-
  st_read('data/us_counties.shp') %>%
  
  # Merge in state fips information
  
  left_join(
    read_csv("data/state_fips.csv"),
    on = "STATEFP") %>%
  select(c(GEOID, 
           State, 
           geometry)) %>%
  filter(State %in% 
           unique(df_counties$State)) %>%
  select(-c(State)) %>%
  mutate(GEOID = 
           as.integer(GEOID)) %>%
  st_transform(crs = 4326) %>%
  
  # Merge in county information
  
  left_join(
    df_counties,
    by = "GEOID")

# Removes counties without intersections (MA islands)
# as section "local moran's" will not work otherwise

counties_shp <- counties_shp[-c(1073, 1865),]

# local moran's -------------------------------------------------------

# Calculates which counties are neighbors

neighbors <- poly2nb(counties_shp)

# Determines whether there is local spatial autocorrelation

local <- localmoran(x = counties_shp$`Recovery Score`, 
                    listw = nb2listw(neighbors, 
                                     style = "W",
                                     zero.policy = TRUE))

# Binds results to original shapefile

moran_map <- cbind(counties_shp, local)

# local moran significance map ----------------------------------------

# Download and create the basemap

osm <- tmaptools::read_osm(bb(moran_map), ext = 1.05)

# Create the basemap

tm_shape(osm) +
  
  tm_rgb() +
  
  # Add polygons filled with local moran significance
  
  tm_shape(moran_map) + 
  tm_polygons(col = "Pr.z....E.Ii..",
              style = "fixed",
              alpha = 0.4,
              border.alpha = 0.1,
              
              # Divides colors into significance levels
              
              breaks = c(0, 0.01, 0.05, 0.1, Inf),
              
              palette = "-Greens",
              title = "Local Moran Significance") +
  
  # Adjusts where the legend is located
  
  tm_legend(legend.position = c("right", "bottom"))

# local moran plot ----------------------------------------------------

# Create the basemap

tm_shape(osm) +
  
  tm_rgb() +
  
  # Add polygons filled with local moran values
  # Note that the region around Nashville has an incredibly high value
  # And as such quantiles were necessary
  
  tm_shape(moran_map) + 
  tm_polygons(col = "Ii",
              alpha = 0.4,
              border.alpha = 0.1,
              style = "quantile",
              palette = "Blues",
              title = "Local Moran Statistic") +
  
  # Adjusts where the legend is located
  
  tm_legend(legend.position = c("right", "bottom"))

# local moran mixed ---------------------------------------------------

# Create the basemap

tm_shape(osm) +
  
  tm_rgb() +
  
  # Plots moran values
  # Positive values indicate similar surrounding values

  tm_shape(moran.map %>%
             
             # Filters for only significant values
             
             filter(Pr.z....E.Ii.. < 0.1)) +
  
  # Add polygons filled with corresponding local moran stats
  
  tm_polygons(col = "Ii",
              alpha = 0.4,
              border.alpha = 0.1,
              style = "quantile",
              palette = "Reds",
              title = "Significant Local\nMoran Statistics") +
  
  # Adjusts where the legend is located
  
  tm_legend(legend.position = c("right", "bottom"))
