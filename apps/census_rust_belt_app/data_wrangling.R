# Used to clean data for the app

# setup -------------------------------------------------------------------

library(lubridate)
library(sf)
library(tidyverse)

# data --------------------------------------------------------------------

# Read in Census et al. data

df_counties <- 
  read_csv("data/master_dataset.csv") %>%
  select(!...1)

# wrangling -----------------------------------------------------------

# Lists of states by region

mw <- 
  c("MI", "MN", "PA", "WI", "IL", "IN", "OH", "IA", "MO", "ND", "SD", "NE",
    "KS")

ne <-
  c("ME", "NH", "VT", "MA", "CT", "RI", "PA", "NY", "NJ", "MD", "DE", "DC")

so <-
  c("TX", "OK", "AR", "LA", "MS", "TN", "AL", "KY", "WV", "")

df_counties <- 
  
  df_counties %>%
  
  # Fill forward rural level and most recent presidential election columns
  
  group_by(GEOID) %>%
  
  fill(votes_dem_percent:rural_level,
       .direction = "down") %>%
  
  ungroup() %>%
  
  # Create a column for population density
  
  mutate(density = land_area/pop) %>%
  
  # Fill missing transit, hospital, and construction columns with zeros
  
  mutate(
    across(units:tribal_hospitals,
           ~if_else(
             is.na(.x), 0, .x))) %>%
  
  # Remove the sparsest columns
  
  select(-c(rating,
            votes_green_percent,
            votes_lib_percent)) %>%
  
  # Standardize columns by population
  
  mutate(
    across(c(agg_interest_div_rental,
             pub_transit, 
             work_from_home, 
             latinx_pop:other_pop,
             civ_unemp,
             civ_emp),
           function(x){
             x/pop})) %>%
  
  # Standardize columns per 10k residents
  
  mutate(
    across(c(units:train_2021,
             ems_hospitals:exp_homelessness),
           function(x){
             x/pop*10000})) %>%
  
  # Remove extra columns
  
  select(-c(pop, land_area)) %>%
  
  # Scales all variables from 0 to 1
  
  mutate(
    across(c(inequality_index:civ_emp,
             units:votes_other_percent,
             density),
           ~ (.x-min(.x, na.rm = TRUE))/
             (max(.x, na.rm = TRUE)-min(.x, na.rm = TRUE)))) %>%
  
  # Label states by region
  
  mutate(region =
           case_when(
             
           ))

# save ----------------------------------------------------------------

df_counties %>%
  write.csv("data/master_dataset_clean.csv")
