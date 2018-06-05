
library(tidyverse)
library(leaflet)
library(geojsonio)

huc8 <- geojson_read("shiny/huc8.geojson", what = "sp")

m <- leaflet(huc8) %>%
  addTiles() %>%
  addPolygons(
    color = "#444444",
    weight = 1,
    smoothFactor = 0.5,
    opacity = 1.0,
    fillOpacity = 0.5,
    fillColor = "red",
    highlightOptions = highlightOptions(
      color = "white",
      weight = 2,
      bringToFront = TRUE
    )
  )
