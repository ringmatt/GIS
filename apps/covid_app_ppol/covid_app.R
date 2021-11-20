
# setup -------------------------------------------------------------------

library(lubridate)
library(sf)
library(tmap)
library(shiny)
library(shinydashboard)
library(tidyverse)

# data --------------------------------------------------------------------

# Read in covid data from New York Times:

nyt_covid_url <-
  'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv'

covid_states <- 
  read_csv(nyt_covid_url) %>%
  select(!fips) %>%
  pivot_longer(
    cases:deaths,
    names_to = "metric",
    values_to = "n")

# Read in population data from us census:

population_states <-
  read_csv("data/co-est2020.csv") %>%
  filter(COUNTY == "000") %>%
  select(
    state = STNAME,
    population = POPESTIMATE2020)

# Read in shapefiles:

us_states <-
  st_read('data/us_states.shp') %>%
  select(c(state = name)) %>%
  st_transform(crs = 4326)

conus <-
  st_read('data/conus.shp')

# user interface ----------------------------------------------------------

ui <- 
  dashboardPage(
    
    dashboardHeader(title = 'Covid app'),
    
    dashboardSidebar(
      
      dateRangeInput(
        inputId = 'date_range',
        label = 'Select a range of dates:',
        start = min(covid_states$date),
        end = max(covid_states$date)),
      
      radioButtons(
        inputId = 'metric',
        label = 'View:',
        choiceNames = c('Cases', 'Deaths'),
        choiceValues = c('cases', 'deaths')),
      
      checkboxInput(
        inputId = 'population_adjust',
        label = 'Adjust for population?'),
      
      sidebarMenu(
        menuItem('Map',
                 icon = icon('map'),
                 tabName = 'maps'),
        
        menuItem('Table',
                 icon = icon('table'),
                 tabName = 'tables'),
        
        menuItem('Trend',
                 icon = icon('chart-line'),
                 tabName = 'charts')
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$link(
          rel = 'stylesheet',
          type = 'text/css',
          href = 'dashboard_styles.css'
        )
      ),
      
      tabItems(
        
        tabItem(
          tabName = 'maps',
          h2('Map'),
          tmapOutput(outputId = 'covid_map')),
        
        tabItem(
          tabName = 'tables',
          h2('Summary table'),
          dataTableOutput(outputId = 'summary_table')),
        
        tabItem(
          tabName = 'charts',
          h2('Trend'),
          selectInput(
            inputId = 'state_select',
            label = 'State',
            choices = c('Show all',
                        sort(us_states$state))),
          plotOutput(outputId = 'plot_output'))
      )
    )
  )

# server ------------------------------------------------------------------

server <- 
  function(input, output) { 
    
    # Data subsetting and summarizing -------------------------------------
    
    # Filter data by metric and date range:
    
    covid_filter <-
      reactive({
        covid_states %>%
          filter(metric == input$metric,
                 date >= input$date_range[1],
                 date <= input$date_range[2]) %>%
          select(-metric)
      })
      
    
    # Adjust for population if checked:
    
    covid_adjusted <-
      reactive({
        if (input$population_adjust) {
          covid_filter() %>%
            left_join(population_states,
                      by = "state") %>%
            mutate(n = n/population) %>%
            select(!population)
        } else {
          my_filtered_data
        }
      })
    
    # Summarize data for map and summary table:
    
    covid_summarized <-
      reactive({
        covid_adjusted() %>%
          group_by(state) %>%
          summarize(n = max(n) - min(n))
      })
    
    # Adjust for population if checked:
    
    # Trend data:
    
    
    
    # Outputs -------------------------------------------------------------
    
    # Map:
    
    output$covid_map <-
      renderTmap(
        us_states %>%
          left_join(
            covid_summarized(),
            by = "state") %>%
          
          tm_shape(.) +
          tm_polygons(col = 'n') +
          tm_view(bbox = 
                    st_bbox(conus)))
    
    # Summary table:
    
    
    # Plot:
    
    
  }

# knit and run app --------------------------------------------------------

shinyApp(ui, server)