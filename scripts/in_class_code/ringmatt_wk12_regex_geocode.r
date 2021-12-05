# setup ---------------------------------------------------------------

library(tidyverse)

# stringr basics, detecting strings ---------------------------------------

# Issue with text data, none of these show up as having grey through
# typical conditionals

c('gray wolf', 'gray ', 'grey') == 'gray'

# Detect strings with str_detect:

str_detect(string = 'gray', pattern = 'r')

str_detect('gray', 'gr')

str_detect('gray', 'gry')

# Challenge

birds <- c(nina = 'I wish I could fly like a bird in the sky',
          maude = 'To me they will always be glorious birds')

# Evaluate this statement such that both Nina and Maude’s reference to birds
# evaluate to TRUE:

str_detect(birds, 'bird')

# Evaluate this statement such that Maude’s reference to birds evaluates to TRUE
# and Nina’s evaluates to FALSE:

str_detect(birds, 'birds')

# Evaluate this statement such that Nina’s reference to birds evaluates to TRUE
# and Maude’s evaluates to FALSE:

str_detect(birds, 'bird ')

# stringr basics, replacing strings ---------------------------------------

# str_replace

str_replace(
  string = 'hello world', 
  pattern = 'world',
  replacement = 'everyone')

str_replace(
  'hello world', 
  'world',
  'everyone')

# str_replace, piped:

str_replace(
  'hello world', 
  'world',
  'everyone') %>% 
  str_replace(
    'everyone',
    'howdy') %>% 
  str_replace(
    'hello',
    'boy')

# str_replace, only the first match is replaced:

str_replace(
  '21/7/14',
  '/',
  '.')

# str_replace_all:

str_replace_all(
  '21/7/14', 
  '/', 
  '.')

# stringr basics, concatenating strings -----------------------------------

# Concatenate strings with str_c:

str_c(
  "He wasn't scared of nothin' boys",
  "he was pretty sure he could fly",
  sep = ', ')

# Concatenate multiple strings:

str_c(
  c('hello',
    'howdy',
    'hi'),
  'world',
  sep = ' ')

# Concatenate strings in a tibble:

tibble(
  a = c('hello', 'howdy'),
  b = c('world', 'everybody')) %>% 
  mutate(d = str_c(a, 'folks', sep = ' '))

# Concatenate columns:

tibble(
  a = c('hello', 'howdy'),
  b = c('world', 'everybody')) %>% 
  mutate(d = str_c(a, b, sep = ' '))


# stringr basics,  extract and remove -------------------------------------

# str_extract:

c('2021-09-01', '2021-10-01') %>% 
  str_extract('2021')

# str_remove:

c('2021-09-01', '2021-10-01') %>% 
  str_remove('2021-')

# str_remove_all:

c('2021-09-01', '2021-10-01') %>% 
  str_remove('-')

c('2021-09-01', '2021-10-01') %>% 
  str_remove_all('-')

# regex metacharacters, anchors -------------------------------------------

# Anchor at start of string (^):

c('gray', 'gray wolf', 'stingray') %>% 
  str_detect('^gray')

# Anchor at end of string:

c('gray', 'gray wolf', 'stingray') %>% 
  str_detect('gray$')

# regex metacharacters, character classes ---------------------------------

# The character class, ([x]):

c('gray', 'grey') %>% 
  str_detect('gr[ae]y') 

c('June', 'june') %>% 
  str_detect('[Jj]une') 

# Challenge: Evaluate this statement to detect salamander or Salamander:

dr_p <-
  c(
    who = 'In the herp world, Dr. P was known as Dr. Salamander.',
    what = 'I searched for hellbenders and other salamanders with Dr. P.')

dr_p %>%
  str_detect('[Ss]alamander')

# Range inside of a character class:

c('June', 'june', 'JUNE') %>% 
  str_detect('[a-z]') 

c('June', 'june', 'JUNE') %>% 
  str_detect('[A-Z]') 

c('June', 'june 1', 'JUNE') %>% 
  str_detect('[0-9]')

c('June', 'june 1', 'JUNE') %>% 
  str_detect('[A-Z0-9a-z]') 


# regex, or ---------------------------------------------------------------

# Regex or is "|":

# Detect gray or grey, not stingray or graying:

c('gray',
  'grey',
  'stingray',
  'graying') %>% 
  str_detect('^gray|grey$') 

# Detect June, june, jun, or Jun:
  
c('jun',
  'June',
  'juniper',
  'disjunct') %>% 
  str_detect('^[Jj]une|[Jj]un$')

# regex, alternation constraints ------------------------------------------

# Alternation constraints are "(x)"

# If we wanted to detect gray or grey, this doesn't work ... why?

c('gray',
  'grey',
  'grape',
  'honeysuckle') %>% 
  str_detect('gra|ey')

# Parentheses constrain the search:

c('gray',
  'grey',
  'grape',
  'honeysuckle') %>% 
  str_detect('gr(a|e)y')

# Challenge: Detect grayer, greyed, or graying, not stingray or grays:

c('grayed',
  'greyer',
  'grays',
  'stingray',
  'graying') %>%
  # str_detect('^gr[ae]y[ie]') %>%
  str_detect('gr[ae]y(e[rd]|ing)')

# regex, optional match ---------------------------------------------------

# Optional match is "?"
# Character prior to ? is optional

# Optional match, detect gray, grey, or grays, not stingray or graying:

c('gray',
  'grey',
  'grays',
  'stingray',
  'graying') %>% 
  str_detect('^gr[ae]ys?$')

# Detect jun or June, not juniper or disjunct:
  
  c('jun',
    'June',
    'juniper',
    'disjunct') %>% 
  str_detect('^[Jj]une?$')

c('Jun-1',
  'jun-1st',
  'jun-1s',
  'jun-15') %>% 
  str_detect('[Jj]un-1(st)?$')

# regex, wildcard ---------------------------------------------------------

# Regex wildcard is "."

# Detect grayer or greyed, not stingray or graying:

c('grayed',
  'greyer',
  'stingray',
  'graying') %>% 
  str_detect('^gr[ae]ye.$') 

# Challenge: Detect a date with a number:

c('Jun 1',
  'jun 1',
  'June/1',
  'June-1',
  'June') %>%
  str_detect("[Jj]une?.[0-9]")


# collect month names -------------------------------------------------

month.abb %>%
  str_c(collapse = "|")

month.name %>%
  str_c(collapse = "|")

# regex,  repetition metacharacters ---------------------------------------

# Repetition metacharacters, * = none or unlimited:

c('gray whale',
  'gray wolf', 
  'blue-gray gnatcatcher',
  'blue whale') %>% 
  str_detect('^gray.*$')

# Repetition metacharacters, + = once or unlimited:

c('gray whale',
  'gray wolf',
  'blue-gray gnatcatcher',
  'blue whale') %>% 
  str_detect('^.+gray.*$')

# Repetition metacharacters, {n} = repeated n times:

c('jun', 'june') %>% 
  str_detect('^[a-z]{4}$')

c('jun-1', 'june-1') %>% 
  str_detect('^[a-z]{4}-1$')

# Challenge: Which of these values represents a US phone number?

c('1-123-581-3213',
  '11-23-581-3213',
  '1-123-5813-213') %>%
  str_detect('^1-([0-9]{3}-){2}[0-9]{4}$')

# Repetition metacharacters, {n,k} = repeated n to k times:

c('Jun 1',
  'jun 19',
  'June/132',
  'June-99',
  'June') %>% 
  str_detect('^[Jj]une?.[0-9]{1,2}$')

# Challenge: We have tags where there are two to four digits followed by a dash,
# then five digits. Detect the correct tag number in these data:

c('11-358132',
  '112-35813',
  '1123-58132',
  '11235-81321') %>%
  str_detect('^[0-9]{2,4}-[0-9]{5}$')

# Geocode with httr API ---------------------------------------------------

# See https://nominatim.org/release-docs/latest/api/Search/#parameters

library(httr)

api_query <-
  'http://nominatim.openstreetmap.org/search?q=8404+Garland+Ave+Takoma+Park+Maryland&format=json&polygon_text=1&addressdetails=0&limit=1'

GET(api_query) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() %>% 
  select(lon, lat)

# Challenge (convert spaces to + and construct an api request:

my_address <-
  '8404 Garland Ave, Takoma Park Maryland'

my_address %>%
  str_replace_all(
    pattern = ' ',
    replacement = '+')

# Read in data:

lat_lon <- 
  api_query %>% 
  GET() %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() %>% 
  select(lon, lat) %>%
  mutate_all(as.double)

# Challenge: Convert to a spatial file:

lat_lon <- lat_lon %>%
  sf::st_as_sf(coords = c("lon", "lat"), crs=4326)

# Multiple addresses with time lag:

my_addresses <-
  c('Georgetown University, Washington DC',
    'National Zoo Washington DC',
    '8404 Garland Ave Takoma Park MD')

my_addresses %>%
  purrr::map_dfr(
    function(address_var) {
      Sys.sleep(1)
      str_c('http://nominatim.openstreetmap.org/search?q=',
            address_var,
            '&format=json&polygon_text=1&addressdetails=0&limit=1') %>% 
        GET() %>% 
        httr::content(as = 'text') %>% 
        jsonlite::fromJSON() %>% 
        transmute(
          address = address_var,
          lon,
          lat)
    })

# Remove + signs?

lat_lons <- 
  my_addresses %>% 
  purrr::map_dfr(
    function(address_var) {
      Sys.sleep(1)
      str_c('http://nominatim.openstreetmap.org/search?q=',
            str_replace_all(address_var, ' ', '+'),
            '&format=json&polygon_text=1&addressdetails=0&limit=1') %>% 
        GET() %>% 
        httr::content(as = 'text') %>% 
        jsonlite::fromJSON() %>% 
        transmute(
          address = address_var,
          lon,
          lat)
    })

# Challenge: Convert to a spatial file and generate an interactive map in a single piped statement:

lat_lons %>%
  mutate(lon = as.double(lon),
         lat = as.double(lat)) %>%
  sf::st_as_sf(coords = c("lon", "lat"), crs=4326)

# Challenge, write your own geocoding function that returns an sf object:

geocode <- function(addresses){
  addresses %>%
  purrr::map_dfr(
    function(addresses) {
      Sys.sleep(1)
      str_c('http://nominatim.openstreetmap.org/search?q=',
            str_replace_all(addresses, ' ', '+'),
            '&format=json&polygon_text=1&addressdetails=0&limit=1') %>% 
        GET() %>% 
        httr::content(as = 'text') %>% 
        jsonlite::fromJSON() %>% 
        transmute(
          address = addresses,
          lon,
          lat) %>%
        mutate(lon = as.double(lon),
               lat = as.double(lat)) %>%
        sf::st_as_sf(coords = c("lon", "lat"), crs=4326)
    })
}

geocode(my_addresses)

# Create a my_addresses file:

my_addresses_gc <-
  geocode(my_addresses)

# Reverse geocode (https://nominatim.org/release-docs/latest/api/Reverse/):

url_reverse <-
  'https://nominatim.openstreetmap.org/reverse?format=json&lon=-77.07458&lat=38.90894&zoom=18&addressdetails=1'

GET(url_reverse) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() %>% 
  pluck('display_name')

# What if we had an sf file?

my_address_coordinates <-
  geocode(my_addresses) %>% 
  sf::st_coordinates() %>% 
  as_tibble()

my_address_url <-
  str_c(
    'https://nominatim.openstreetmap.org/reverse?format=json&lon=',
    my_address_coordinates$X, 
    '&lat=',
    my_address_coordinates$Y,
    '&zoom=18&addressdetails=1')

GET(my_address_url[1]) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() %>% 
  pluck('display_name')

# Challenge write a purrr::map that will add an address column to an sf file with multiple coordinates:

my_addresses_sf <-
  geocode(my_addresses) %>%
  transmute(site = c('Georgetown', 'NZP', 'home'))

# Challenge: Write a function called reverse_geocode that will determine the addresses of my_addresses_sf (note: see st_coordinates):


reverse_geocode(my_addresses_sf)

# tmaptools and geocoding -------------------------------------------------

# Geocode with tmaptools:

tmaptools::geocode_OSM(
  my_addresses,
  as.sf = TRUE)

# Reverse geocode with tmaptools:

tmaptools::rev_geocode_OSM(
  my_addresses_sf)

