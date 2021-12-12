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

# Read in census manufacturing and natural resource employment change #s

df_industry <-
  read_csv("data/county_industry_change.csv") %>%
  as_tibble() %>%
  mutate(GEOID = 
           as.double(GEOID))

# Read in foreign born #s

df_foreign_born <-
  read_csv("data/county_foreign_born_change.csv") %>%
  as_tibble() %>%
  mutate(GEOID = 
           as.double(GEOID))

# wrangling -----------------------------------------------------------

# Create list of Eastern US states (minus Florida)

east_plus <-
  c("MI", "MN", "PA", "WI", "IL", "IN", "OH", "ME", "NH", "VT", "MA", "CT",
    "RI", "PA", "NY", "NJ", "MD", "DE", "DC", "MS", "TN", "AL", "KY", "WV",
    "GA", "NC", "SC", "VA", "LA", "AR", "MO", "IA")

df_counties <- 
  
  df_counties %>%
  
  # Subset to Eastern US
  
  filter(state %in% east_plus) %>%
  
  # Fill missing home construction values with zeros
  
  mutate(units = 
           if_else(is.na(units), 0, units)) %>%
  
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
  
  # Subset to important columns
  
  select(c(GEOID, name, state, year, pop, 
           med_home_income, inequality_index,
           poverty_rate, med_home_val, units)) %>%
  
  # Join manufacturing and natural resource industry data
  
  left_join(df_industry,
            on = "GEOID") %>%
  
  # Join foreign born percent data
  
  left_join(df_foreign_born,
            on = "GEOID")  %>%
  
  # Aggregate to one value per county, taking the difference between most
  # recent and oldest data available
  
  filter(year == 2010 | year == 2019) %>%
  group_by(GEOID) %>%
  mutate(pop_change = c(0, diff(pop)/
                          pop[2]),
         income_change = c(0,diff(med_home_income)),
         poverty_decrease = c(0,diff(poverty_rate)*-1),
         inequality_decrease = c(0,diff(inequality_index)*-1),
         home_val_change = c(0,diff(med_home_val)),
         housing_construction_increase = c(0, diff(units))) %>%
  ungroup() %>%
  filter(year == 2019) %>%
  
  # Select only the new aggregate variables
  
  select(c(GEOID, name, state, pop_change, 
           income_change,
           poverty_decrease, inequality_decrease,
           home_val_change, housing_construction_increase,
           manufacturing_percent_change,
           natural_resources_percent_change,
           foreign_born_pop_percent_change)) %>% 
  
  # Scales variables to z-scores
  
  mutate(
    across(pop_change:foreign_born_pop_percent_change,
           ~ (.x-mean(.x, na.rm = TRUE))/
             (sd(.x, na.rm = TRUE))))

# save ----------------------------------------------------------------

df_counties %>%
  write.csv("data/master_dataset_clean.csv")
