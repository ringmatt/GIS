## Setup

library(tidyverse)
library(sf)

# Reads in the census shapefile
census_sp <-
  rgdal::readOGR('data/raw/spatial/census/census.shp')

# Outputs the coordinate reference system for these data
census_sp@proj4string

# Separates the data by state 
dc_sp <- census_sp[census_sp$state_name == "DC",]

md_sp <- census_sp[census_sp$state_name == "Maryland",]

va_sp <- census_sp[census_sp$state_name == "Virginia",]

# Determines the spatial extent of each state

# DC's area (Land & Water)
sum(dc_sp$ALAND) + sum(dc_sp$AWATER)

# Maryland's area (Land & Water)
sum(md_sp$ALAND) + sum(md_sp$AWATER)

# Virginia's area (Land & Water)
sum(va_sp$ALAND) + sum(va_sp$AWATER)

# Plots DC

sp::plot(dc_sp)

# Dissolves census tract boundaries in Virginia

# Note: Creates a weird boundary whereby VA's claim to Delmarva is connected to 
# mainland VA. Not sure how to get rid of this, even tried using sf. 
va_dsslvd <- rgeos::gUnaryUnion(va_sp)

# Plots VA using sp
sp::plot(va_dsslvd)

# Creates a point object for our classroom
classroom_sp <- sp::SpatialPoints(cbind(-77.075212, 38.90677), 
                                  proj4string = sp::CRS("+proj=longlat +datum=WGS84"))

# Changes "dc_sp" to "dc_sf" (a simple features object)
dc_sf <- dc_sp %>%
  st_as_sf()

# Changes the classroom point to a simple features object
classroom_sf <- classroom_sp %>%
  st_as_sf()

# Changes the classroom point's crs to NAD83
classroom_prj <- classroom_sf %>%
  st_transform(
    st_crs(dc_sf))

# Finds the population of the census tract for our classroom
classroom_prj %>%
  st_join(dc_sf) %>%
  pull(population)


# Plots education levels in DC & adds a point for our classroom
dc_sf %>%
  ggplot() +
  # Adds in the education data as fill color for each tract
  geom_sf(aes(fill = edu)) +
  # Adds the classroom point, changes its color, shape, size
  stat_sf_coordinates(data = classroom_prj, color = "red", 
                      shape = "*", size = 7) + 
  # Changes the color scale to viridis's plasma option
  scale_fill_viridis_b(option = "plasma") +
  # Adds labels
  labs(title = "Education in DC",
       fill = "Education",
       x = "Longitude",
       y = "Latitude",
       caption = "Source: Census data") +
  # Sets the theme to minimal
  theme_minimal()
