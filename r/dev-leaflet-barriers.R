
library(tidyverse)
library(leaflet)

source("functions.R")
config <- load_config()

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


# barriers ---------------------------------------------------------------

conn <- dbConnect(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = config$db$dbname,
  host = config$db$host,
  port = config$db$port,
  user = config$db$user
)

sql <- "SELECT id, type, x_coord, y_coord, lat, lon, bh.* FROM barriers b INNER JOIN barriers_huc bh ON b.id=bh.barrier_id WHERE bh.huc8 = $1"
barriers <- dbGetQuery(conn, sql, param = list('01040002'))

summary(barriers)

# Circles w/ highlighting
leaflet(barriers) %>%
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
leaflet(barriers) %>%
  addTiles() %>%
  addCircleMarkers(
    lng = ~ lon,
    lat = ~ lat,
    clusterOptions = markerClusterOptions(
      showCoverageOnHover = FALSE
    )
  )
