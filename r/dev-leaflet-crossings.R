
library(tidyverse)
library(leaflet)

m <- leaflet() %>%
  addTiles() %>%
  addMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R")
m

m <- leaflet() %>%
  addTiles() %>%
  addCircleMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R")
m

m <- leaflet() %>%
  addProviderTiles(providers$Stamen.Terrain) %>%
  addCircles(lng=174.768, lat=-36.852, popup="The birthplace of R")
m

# cluster points
leaflet(quakes) %>% addTiles() %>% addMarkers(
  clusterOptions = markerClusterOptions()
)

# circle markers - radius specified in pixels
leaflet(quakes) %>% addTiles() %>%
  addCircleMarkers()

# circle markers - radius specified in meters
leaflet(quakes) %>% addTiles() %>%
  addCircles()

# highlight (does not work with markers)
leaflet(quakes) %>%
  addTiles() %>%
  addCircles(
    radius = 10000,
    highlightOptions = highlightOptions(
      color = "red",
      weight = 6,
      bringToFront = TRUE
    )
  )


# crossings ---------------------------------------------------------------

crossings <- read_csv(
  "csv/crossings-01040002.csv",
  col_types = cols(
    id = col_integer(),
    x_coord = col_double(),
    y_coord = col_double(),
    lon = col_double(),
    lat = col_double()
  )
)

# Circles w/ highlighting
leaflet(crossings) %>%
  addTiles() %>%
  addCircles(
    lng = ~ lon,
    lat = ~ lat,
    highlightOptions = highlightOptions(
      color = "red",
      weight = 6,
      bringToFront = TRUE
    )
  )

# CircleMarkers w/ clustering
leaflet(crossings) %>%
  addTiles() %>%
  addCircleMarkers(
    lng = ~ lon,
    lat = ~ lat,
    clusterOptions = markerClusterOptions(
      showCoverageOnHover = FALSE
    )
  )
