
# setup -------------------------------------------------------------------

library(sf)
library(sp)
library(tidyverse)
library(rgdal)

# read in shapefile data --------------------------------------------------

dc <-
  st_read('data/raw/spatial/rasters/dc.shp')
  
# read in raster data -----------------------------------------------------

# Trick, when using the raster package, I always use "::" instead of 
# loading the library on the top of the page (it shares function names with
# tidyverse functions:

# Here's how we would read in a raster one at a time:

#raster::raster('data/raw/spatial/rasters/nlcd.tif')

# We can also read them all at once with our new purrr skills!

raster_names <-
  c('canopy_cover',
    'impervious_surface',
    'nlcd')

my_rasters <- str_c('data/raw/spatial/rasters/',
                    raster_names,
                    '.tif') %>%
  # ~ specifies a function/formula w/ a . variable
  map( ~ raster::raster(.)) %>%
  set_names(raster_names)

# transforming the raster projection --------------------------------------

my_rasters$canopy_cover <-
  my_rasters$canopy_cover %>%
  raster::projectRaster(crs = raster::projection(my_rasters$nlcd))

# cropping rasters --------------------------------------------------------

canopy_small <- 
  dc %>%
  st_transform(raster::projection(my_raster$nlcd)) %>%
  raster::crop(my_rasters$canopy_cover, .)

# mask rasters ------------------------------------------------------------

canopy_small <- 
  dc %>%
  st_transform(raster::projection(my_raster$nlcd)) %>%
  raster::crop(my_rasters$canopy_cover, .) %>%
  raster::mask(
    st_transform(
      dc,
      raster::projection(my_raster$nlcd))
    )

# the raster stack --------------------------------------------------------

