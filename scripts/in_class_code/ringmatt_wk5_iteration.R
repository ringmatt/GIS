## Loads in the package(s):
library(tidyverse)

#source('scripts/source_script.R')


## Reads in the data:


# Reads in the Census data as a tibble w/o the geometry feature
census <- 
  sf::st_read('data/raw/spatial/census/census.shp') %>% 
  as_tibble() %>% 
  select(-geometry)

# Reads in the World Bank data
countries_world_bank <-
  read_rds('data/raw/countries_world_bank.rds')


## Calculations


# Calculates mean income using base indexing
mean(
  census[which(census$COUNTYFP == '027'), ]$income,
  na.rm = TRUE)

# Calculates mean income using tidyverse filtering
census %>% 
  filter(COUNTYFP == '027') %>% 
  pull(income) %>% 
  mean(na.rm = TRUE)


## Function Tangent


my_fun <-
  function(x){
    # Saves y to the global environment
    y <<- x
    
    # Returns y+1
    (y + 1)
  }

my_fun(3)
y


## For Loops


# 1. The Output Container

counties <-
  vector(
    # Type of vector
    'numeric', 
    # Assigns length to the number of counties
    length = length(unique(census$COUNTYFP)))

# 2. The Sequence Statement (control-flow construct)

for(i in 1:length(unique(census$COUNTYFP))){
  
}

# 3. The Body

for(i in 1:length(unique(census$COUNTYFP))){
  
  # Split the data:
  COUNTYFP_subset <-
    census[census$COUNTYFP == unique(census$COUNTYFP)[i], ]
  
  # Define the location inside of the output container:
  counties[i] <-
    # Apply a function:
    mean(
      COUNTYFP_subset$income,
      na.rm = TRUE)
}

# Saves the data as a tibble, ordered by county income
tibble(
  COUNTYFP = unique(census$COUNTYFP),
  income = counties) %>%
  arrange(desc(income))

unique(census$COUNTYFP[census$STATEFP == "51"])

unique(census$STATEFP)


## Fibonacci's Equation


# Creates a blank vector of length 10

N <- 
  vector(
  'numeric',
  length = 10)

# Sets the initial Fibonacci numbers

N[1:2] <-
  c(0, 1)

# Cycles from 3 to the length of N

for(i in 3:length(N)) {
  N[i] <-
    N[i - 1] + N[i -2]
}

# OR we can add an if-else statement to this for loop

my_index <- 
  vector(
    'logical',
    length = 10)

for(i in seq_along(my_index)) {
  if(i %in% 1:2) {
    my_index[i] <-
      TRUE
  } else {
    my_index[i] <-
      FALSE
  }}

# Returns whether each index is valid

fib

## Map Functions - easy & optimized for-loop

my_map <-
  map(
    # Sequence statement:
    1:length(unique(census$COUNTYFP)),
    
    # Takes in indicies
    function(i) {
      # *Split* the data:
      
      COUNTYFP_subset <-
        census[census$COUNTYFP == unique(census$COUNTYFP)[i], ]
      
      # Output per iteration:
      
      tibble(
        COUNTYFP =  unique(census$COUNTYFP)[i],
        
        # *Apply* a function:
        
        value = 
          mean(
            COUNTYFP_subset$income,
            na.rm = TRUE))
    })

# *Combine* the output:

bind_rows(my_map)

## Mapping by Row

map_dfr(
  # Sequence statement:
  unique(census$COUNTYFP),
  function(x) {
    # Output per iteration:
    
    tibble(
      COUNTYFP = x,
      value = 
        # Split the data:
        
        filter(census, COUNTYFP == x) %>% 
        
        # Apply a function:
        
        pull(income) %>% 
        mean(na.rm = TRUE))
  })

## The Tilde Operator

map_dfr(
  # Sequence statement:
  unique(census$COUNTYFP),
  ~ tibble(
    COUNTYFP = .,
    value = 
      # Split the data:
      
      filter(census, COUNTYFP == .) %>% 
      
      # Apply a function:
      
      pull(income) %>% 
      mean(na.rm = TRUE))
)





