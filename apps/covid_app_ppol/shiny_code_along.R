
# data loading ------------------------------------------------------------

# 1. Read in the covid data from the nytimes, reshape the data such that cases
# and deaths are stored in a single column named "metric", values are stored in
# a single column named "n", and the resultant data frame contains the columns
# date, state, metric, and n. Assign the object to your global environment with
# the name "covid_states".

nyt_covid_url <-
  'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv'

covid_states <- 
  read_csv(nyt_covid_url) %>%
  select(!fips) %>%
  pivot_longer(
    cases:deaths,
    names_to = "metric",
    values_to = "n")

# 2. Read in the population data (data/co-est2020.csv) for each state (COUNTY =
# 000) for 2020 (POPESTIMATE2020). Rename the column "STNAME" to "state" and
# "POPESTIMATE" to "population" then subset the data frame such that it only
# includes those columns. Assign the data frame to your global environment with
# the name "population_states".

population_states <-
  read_csv("data/co-est2020.csv") %>%
  filter(COUNTY == "000") %>%
  select(
    state = STNAME,
    population = POPESTIMATE2020)

# 3. Modify the us_states shapefile, renaming the column "name" to "state", then
# subset the data to only that column. Save the file to your global environment
# with the name "us_states".

us_states <-
  st_read('data/us_states.shp') %>%
  select(c(state = name)) %>%
  st_transform(crs = 4326)

# 4. Read in the shapefile for the continental US (data/conus.shp).

conus <-
  st_read('data/conus.shp')

# data exploration and modification ---------------------------------------

# 5. Extract the earliest date from covid_states:

covid_states %>%
  pull(date) %>%
  min()

# 6. Filter covid_states to where the metric is "cases" and the dates are
# between 2021-09-01 and 2021-11-10. Assign the object to your global
# environment as "my_filtered_data".

my_filtered_data <-
  covid_states %>%
  filter(metric == "cases",
         date >= "2021-09-01",
         date <= "2021-11-10") %>%
  select(-metric)

# 7. Join population_states to my_filtered_data, then calculate the percent of
# each state's population that contracted Covid-19, and remove the population
# column from the resultant data frame.

my_filtered_data %>%
  left_join(population_states,
            by = "state") %>%
  mutate(n = n/population) %>%
  select(!population)

# 8. An if () { } else { } control flow construct:

test_cfc <-
  function(a) {
    if (a == 1) {
      str_c('hello ', 'world')
    } else {
      str_c('howdy ', 'world')
    }
  }

test_cfc(1)

test_cfc(2)

# Run the following to add population_adjusted to your global environment:

population_adjusted <-
  TRUE

# Write a control flow construct that returns the proportion of the population
# infected, expressed as a percentage, if population_adjusted is TRUE or the
# number of people affected if population_adjusted is FALSE:

if (population_adjusted) {
  my_filtered_data %>%
    left_join(population_states,
              by = "state") %>%
    mutate(n = n/population) %>%
    select(!population)
} else {
  my_filtered_data
}

# 9. Using covid_states, calculate the number of infected individuals, by state:

my_filtered_data %>%
  group_by(state) %>%
  summarize(n = 
              max(n) - min(n))

# 10. Use tmap and my_filtered_data to generate an interactive map of covid
# cases where the US states are colored by the number of cases:

tmap_mode('view')

us_states %>%
  left_join(
    my_filtered_data %>%
      group_by(state) %>%
      summarize(n = 
                  max(n) - min(n)),
    by = "state") %>%
  
  tm_shape(.) +
  tm_polygons(col = 'n') +
  
  # Ensures shapes which cross the dateline don't mess up the map
  
  tm_view(bbox = 
            st_bbox(conus))

# 11. Subset my_filtered_data to the state of Maryland and use ggPlot to map the
# trend in cases in that state:



