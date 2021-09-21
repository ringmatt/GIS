dc_tracts %>% 
  st_intersection(
    classroom %>% 
      st_buffer(dist = 5000) %>% 
      st_transform(
        crs = st_crs(dc_tracts))) %>%
  # Calculates area of the partial tract
  mutate(geom_area = st_area(geometry)) %>%
  # Joins in full tract areas
  left_join(dc_tracts %>%
              # Subsets to relevant columns
              select(c(GEOID, geom_full = geometry)) %>%
              # Calculates area of the full tract
              mutate(geom_full_area = st_area(geom_full)) %>%
              # Removes the geometry
              select(-c(geom_full)) %>%
              # Ensures the dataframe is a tibble
              as_tibble()) %>%
  # Adjusts population by proportion of area within 5km
  mutate(pop_adjusted = population*(geom_area/geom_full_area)) %>%
  # Selects only necessary columns
  select(c(GEOID, STATEFP, pop_adjusted, geom_area, geom_full_area)) %>%
  # Extracts total population
  summarise(total_pop = sum(pop_adjusted)) %>%
  pull(total_pop)